import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/unread_item.dart';

/// 未读消息管理器（单例模式）
///
/// 存储维度：`consultId -> unreadCount`。consultId 是服务端分配的全局唯一 ID，
/// 因此一个 App 接入多商户时也无需按 merchant 再拆一层。
///
/// 持久化：每次变更后 debounce 写入 SharedPreferences（key 见 [_prefsKey]）。
/// 应用启动后 [init] 会异步加载历史快照，宿主可在 [QiChatUISDK.init] 中等待。
class UnreadManager {
  // 私有构造函数
  UnreadManager._();

  // 单例实例
  static final UnreadManager _instance = UnreadManager._();

  // 获取单例
  static UnreadManager get instance => _instance;

  // 存储未读消息数：consultId -> unreadCount
  final Map<int, int> _unreadMap = {};

  // 未读数变化的Stream控制器
  final StreamController<Map<int, int>> _unreadStreamController =
      StreamController<Map<int, int>>.broadcast();

  /// 获取未读数变化的Stream
  Stream<Map<int, int>> get unreadStream => _unreadStreamController.stream;

  // ========== 持久化 ==========

  static const String _prefsKey = 'qichat_unread_v1';

  /// 防抖写盘：避免高频消息导致每条都落盘
  Timer? _persistTimer;
  static const Duration _persistDebounce = Duration(milliseconds: 300);

  bool _loaded = false;

  /// 从本地加载历史未读。可重复调用，已加载则跳过。
  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            final cid = int.tryParse(k.toString());
            final cnt = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
            if (cid != null && cnt > 0) {
              _unreadMap[cid] = cnt;
            }
          });
        }
      }
    } catch (e) {
      print('UnreadManager: 加载本地未读失败 $e');
    }
    _loaded = true;
    _notifyListeners();
    print('UnreadManager: 加载完成，共 ${_unreadMap.length} 条会话有未读');
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persistNow);
  }

  Future<void> _persistNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_unreadMap.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        final encoded = jsonEncode(
          _unreadMap.map((k, v) => MapEntry(k.toString(), v)),
        );
        await prefs.setString(_prefsKey, encoded);
      }
    } catch (e) {
      print('UnreadManager: 持久化失败 $e');
    }
  }

  // ========== 业务方法 ==========

  /// 增加指定会话的未读数
  void incrementUnread(int consultId) {
    _unreadMap[consultId] = (_unreadMap[consultId] ?? 0) + 1;
    _notifyListeners();
    _schedulePersist();
    print('UnreadManager: consultId=$consultId 未读数+1, 当前未读数=${_unreadMap[consultId]}');
  }

  /// 仅当本地没有该 consult 的非零未读时，用 [count] 兜底写入。
  /// 用于宿主从服务端 entrance 接口拉到"快照未读"后回填：本地 WS 实时
  /// 累加值优先，避免服务端慢一拍的快照覆盖刚到达的新消息。
  void setUnreadIfAbsent(int consultId, int count) {
    if (count <= 0) return;
    if ((_unreadMap[consultId] ?? 0) > 0) return;
    _unreadMap[consultId] = count;
    _notifyListeners();
    _schedulePersist();
  }

  /// 清零指定会话的未读数
  void clearUnread(int consultId) {
    if (_unreadMap.containsKey(consultId)) {
      _unreadMap.remove(consultId);
      _notifyListeners();
      _schedulePersist();
      print('UnreadManager: consultId=$consultId 未读数已清零');
    }
  }

  /// 获取指定会话的未读数
  int getUnread(int consultId) {
    return _unreadMap[consultId] ?? 0;
  }

  /// 获取所有未读数
  Map<int, int> getAllUnread() {
    return Map.from(_unreadMap);
  }

  /// 获取总未读数
  int getTotalUnread() {
    return _unreadMap.values.fold(0, (sum, count) => sum + count);
  }

  /// 获取所有UnreadItem列表
  List<UnreadItem> getAllUnreadItems() {
    return _unreadMap.entries
        .map((entry) => UnreadItem(
              consultId: entry.key,
              unreadCount: entry.value,
            ))
        .toList();
  }

  /// 通知监听者
  void _notifyListeners() {
    if (!_unreadStreamController.isClosed) {
      _unreadStreamController.add(Map.from(_unreadMap));
    }
  }

  /// 清空所有未读数（也清掉持久化）
  void clearAll() {
    _unreadMap.clear();
    _notifyListeners();
    _schedulePersist();
    print('UnreadManager: 所有未读数已清空');
  }

  /// 销毁管理器
  void dispose() {
    _persistTimer?.cancel();
    _unreadStreamController.close();
  }
}
