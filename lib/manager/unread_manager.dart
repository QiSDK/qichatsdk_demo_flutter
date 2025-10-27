import 'dart:async';
import '../model/unread_item.dart';

/// 未读消息管理器（单例模式）
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

  /// 增加指定会话的未读数
  void incrementUnread(int consultId) {
    _unreadMap[consultId] = (_unreadMap[consultId] ?? 0) + 1;
    _notifyListeners();
    print('UnreadManager: consultId=$consultId 未读数+1, 当前未读数=${_unreadMap[consultId]}');
  }

  /// 清零指定会话的未读数
  void clearUnread(int consultId) {
    if (_unreadMap.containsKey(consultId)) {
      _unreadMap[consultId] = 0;
      _notifyListeners();
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

  /// 清空所有未读数
  void clearAll() {
    _unreadMap.clear();
    _notifyListeners();
    print('UnreadManager: 所有未读数已清空');
  }

  /// 销毁管理器
  void dispose() {
    _unreadStreamController.close();
  }
}
