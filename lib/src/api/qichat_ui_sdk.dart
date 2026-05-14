import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';

/// 公共 API（骨架，将在 P4 中实现）。
///
/// 当前仅占位，编译可通过；具体逻辑在后续 task 中接入 [GlobalChatManager]、
/// [LineDetectLib]、[EntrancePage]、[ChatPage] 等内部模块。
class QiChatUISDK {
  QiChatUISDK._();

  static bool _initialized = false;

  /// 应用启动时调用一次。完成 SDK 初始化、线路检测启动、连接管理注册。
  static Future<void> init({
    required String cert,
    required int userId,
    required String userName,
    required int merchantId,
    required String detectUrls,
    required String baseUrlImage,
    int maxSessionMinutes = 300,
    int userType = 2,
  }) async {
    if (_initialized) return;
    _initialized = true;
    // TODO(P4): 把这些参数写入 QiChatConfig，启动 GlobalChatManager 和 LineDetectLib。
  }

  /// 打开客服列表页（默认入口）。
  static Future<void> openCustomerService(BuildContext context) async {
    // TODO(P4): Navigator.push EntrancePage。
  }

  /// 可选：直接打开某个 consult 的聊天页。
  static Future<void> openChat(BuildContext context, Int64 consultId) async {
    // TODO(P4): Navigator.push ChatPage(consultId: consultId)。
  }

  /// 全局未读消息总数流。
  static Stream<int> get totalUnreadStream {
    // TODO(P4): 转发 UnreadManager.unreadStream 求和。
    return const Stream<int>.empty();
  }

  /// 宿主登出时调用。断开连接、清理缓存。
  static Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    // TODO(P4): GlobalChatManager.instance.stop()，清理监听器。
  }
}
