import 'dart:async';
import 'dart:io' show Platform;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../manager/global_chat_manager.dart';
import '../manager/unread_manager.dart';
import '../vc/ChatPage.dart';
import '../vc/entrancePage.dart';

/// QiChat UISDK 公共 API。
///
/// 宿主 App 通过本类完成接入。详见 [QiChatUISDK.init]、
/// [QiChatUISDK.openCustomerService]。
class QiChatUISDK {
  QiChatUISDK._();

  static bool _initialized = false;

  /// 应用启动后调用一次。要求宿主已先执行 [WidgetsFlutterBinding.ensureInitialized]。
  ///
  /// 参数：
  /// - [cert]：租户证书；
  /// - [userId]：用户 ID；
  /// - [userName]：用户名（用于客服端显示）；
  /// - [merchantId]：商户 ID；
  /// - [detectUrls]：逗号分隔的线路检测 URL（如 'https://csapi.hfxg.xyz,https://backup'）；
  /// - [baseUrlImage]：图片资源 CDN 域名；
  /// - [maxSessionMinutes]：会话最大分钟数（默认 300）；
  /// - [userType]：用户类型（默认 2）。
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
    if (_initialized) {
      // 允许重复 init 更新身份（多账号切换场景）
      QiChatConfig.initialize(
        cert: cert,
        userId: userId,
        userName: userName,
        merchantId: merchantId,
        detectUrls: detectUrls,
        baseUrlImage: baseUrlImage,
        maxSessionMinutes: maxSessionMinutes,
        userType: userType,
      );
      return;
    }

    QiChatConfig.initialize(
      cert: cert,
      userId: userId,
      userName: userName,
      merchantId: merchantId,
      detectUrls: detectUrls,
      baseUrlImage: baseUrlImage,
      maxSessionMinutes: maxSessionMinutes,
      userType: userType,
    );

    _initWebViewPlatform();
    GlobalChatManager.instance.initialize();
    GlobalChatManager.instance.startLineDetect();

    _initialized = true;
  }

  static void _initWebViewPlatform() {
    if (kIsWeb) return;
    if (Platform.isIOS || Platform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  /// 打开客服列表页（默认入口）。
  ///
  /// 内部会等待线路检测完成（最多 [waitTimeout] 秒）。若未就绪返回 false。
  static Future<bool> openCustomerService(
    BuildContext context, {
    Duration waitTimeout = const Duration(seconds: 10),
  }) async {
    if (!_initialized) {
      assert(false, 'QiChatUISDK.openCustomerService 前必须先调用 init()');
      return false;
    }
    final ready =
        await GlobalChatManager.instance.waitLineReady(timeout: waitTimeout);
    if (!ready) return false;
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntrancePage()),
    );
    return true;
  }

  /// 直接打开某个 consult 的聊天页。
  static Future<bool> openChat(
    BuildContext context,
    Int64 consultId, {
    Duration waitTimeout = const Duration(seconds: 10),
  }) async {
    if (!_initialized) {
      assert(false, 'QiChatUISDK.openChat 前必须先调用 init()');
      return false;
    }
    final ready =
        await GlobalChatManager.instance.waitLineReady(timeout: waitTimeout);
    if (!ready) return false;
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatPage(consultId: consultId)),
    );
    return true;
  }

  /// 线路检测状态文本流。宿主可订阅它在 UI 中显示线路状态。
  static Stream<String> get lineStatusStream =>
      GlobalChatManager.instance.lineStatusStream;

  /// 全局未读消息总数流。宿主可订阅它在"联系客服"按钮上显示红点。
  static Stream<int> get totalUnreadStream =>
      UnreadManager.instance.unreadStream.map(_sumUnread);

  static int _sumUnread(Map<int, int> m) =>
      m.values.fold<int>(0, (a, b) => a + b);

  /// 当前未读总数（同步读取）。
  static int get totalUnread => UnreadManager.instance.getTotalUnread();

  /// 宿主登出时调用，断开连接、清理监听。
  static Future<void> dispose() async {
    if (!_initialized) return;
    GlobalChatManager.instance.stop();
    GlobalChatManager.instance.clearAllListeners();
    QiChatConfig.reset();
    _initialized = false;
  }
}
