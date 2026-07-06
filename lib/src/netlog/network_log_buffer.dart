import 'package:flutter/foundation.dart';

import 'network_log.dart';

/// 网络日志缓冲区 - 与 Android `NetworkLogBuffer` / iOS `NetworkLogBuffer` 对齐。
///
/// 收集 `CustomInterceptors` 捕获的 HTTP 请求日志，最多保留 [_maxCount] 条
/// （超出丢弃最旧）。最新的在前。通过 [logs]（[ValueListenable]）驱动列表页实时刷新。
class NetworkLogBuffer {
  NetworkLogBuffer._();
  static final NetworkLogBuffer instance = NetworkLogBuffer._();

  static const int _maxCount = 200;

  /// 只读日志流；列表页用 [ValueListenableBuilder] 监听即可实时更新。
  final ValueNotifier<List<NetworkLog>> logs = ValueNotifier(<NetworkLog>[]);

  /// 记录一条新请求（onRequest 时调用）。
  void addRequest(NetworkLog log) {
    final list = [log, ...logs.value];
    if (list.length > _maxCount) {
      list.removeRange(_maxCount, list.length);
    }
    logs.value = list;
  }

  /// 用响应补全对应请求（onResponse / onError 时调用），按 [id] 匹配。
  /// 传入的 [update] 会拿到已有的那条 [NetworkLog] 做原地补全。
  void completeResponse(String id, void Function(NetworkLog log) update) {
    final list = logs.value;
    final index = list.indexWhere((e) => e.id == id);
    if (index == -1) return;
    update(list[index]);
    // 触发监听（内容变了但引用没变，复制一份新 list 通知）
    logs.value = List<NetworkLog>.from(list);
  }

  /// 清空所有日志
  void clear() {
    logs.value = <NetworkLog>[];
  }
}
