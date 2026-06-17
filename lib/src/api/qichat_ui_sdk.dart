import 'dart:async';
import 'dart:io' show Platform;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../model/ServiceKeyword.dart';
import '../manager/global_chat_manager.dart';
import '../manager/unread_manager.dart';
import '../model/AppChatTheme.dart';
import '../vc/ChatPage.dart';
import '../vc/device_info_page.dart';
import '../vc/entrancePage.dart';
import 'unread_query.dart';

/// QiChat UISDK 公共 API。
///
/// 宿主 App 通过本类完成接入。详见 [QiChatUISDK.init]、
/// [QiChatUISDK.openCustomerService]。
class QiChatUISDK {
  QiChatUISDK._();

  static bool _initialized = false;

  /// 应用启动后调用一次。要求宿主已先执行 [WidgetsFlutterBinding.ensureInitialized]。
  ///
  /// 内部会同步完成：线路检测 → 用拿到的 domain 建立 wss 连接 → 启动保活监控。
  /// 返回 true 表示线路就绪且连接已发起；false 表示线路检测超时（[lineDetectTimeout]）。
  ///
  /// 参数：
  /// - [cert]：租户证书；
  /// - [userId]：用户 ID；
  /// - [userName]：用户名（用于客服端显示）；
  /// - [merchantId]：商户 ID；
  /// - [platformName]：商户名（用于聊天页 AppBar 右侧展示）；
  /// - [detectUrls]：逗号分隔的线路检测 URL（如 'https://csapi.hfxg.xyz,https://backup'）；
  /// - [baseUrlImage]：图片资源 CDN 域名；
  /// - [maxSessionMinutes]：会话最大分钟数（默认 300）；
  /// - [userType]：用户类型（默认 2）；
  /// - [lineDetectTimeout]：线路检测超时（默认 10 秒）。
  static Future<bool> init({
    required String cert,
    required int userId,
    required String userName,
    required int merchantId,
    required String detectUrls,
    required String baseUrlImage,
    String platformName = '',
    int maxSessionMinutes = 300,
    int userType = 2,
    Duration lineDetectTimeout = const Duration(seconds: 10),
  }) async {
    // 重复 init：身份/商户可能变了，旧 domain/连接不可复用 → 先清干净再重走
    if (_initialized) {
      await dispose();
    }

    QiChatConfig.initialize(
      cert: cert,
      userId: userId,
      userName: userName,
      merchantId: merchantId,
      platformName: platformName,
      detectUrls: detectUrls,
      baseUrlImage: baseUrlImage,
      maxSessionMinutes: maxSessionMinutes,
      userType: userType,
    );

    _initWebViewPlatform();
    // 首次使用时把历史未读从本地读回内存（已加载会跳过）
    await UnreadManager.instance.init();
    GlobalChatManager.instance.initialize();
    GlobalChatManager.instance.startLineDetect();

    final ready = await GlobalChatManager.instance
        .waitLineReady(timeout: lineDetectTimeout);
    if (!ready) return false;

    GlobalChatManager.instance.connectIfNeeded();
    GlobalChatManager.instance.startConnectionMonitoring();

    _initialized = true;
    return true;
  }

  /// 设置「关键词自动卡片」配置。
  ///
  /// 宿主调用自己的接口拿到 `service_keyword` 数组（每条含 `subject` / `content` /
  /// `keywords` / `weight` 等），原样传入即可。可在 [init] 之后任意时机重复调用覆盖。
  ///
  /// 之后当用户在聊天页输入的文本包含某条的任一 keyword 时，UISDK 会自动以
  /// `msgSourceType = MST_AUTO_CARD` 追加发送一条卡片消息。
  static void setAutoCardKeywords(List<Map<String, dynamic>> serviceKeywords) {
    QiChatConfig.current.serviceKeywords =
        serviceKeywords.map((e) => ServiceKeyword.fromJson(e)).toList();
  }

  static void _initWebViewPlatform() {
    if (kIsWeb) return;
    if (Platform.isIOS || Platform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  /// 打开客服列表页（默认入口）。
  ///
  /// 调用前必须先 [init] 成功（init 已保证线路就绪并发起连接）。
  ///
  /// [theme]：宿主可传入一套主题,会一路下传到 [ChatPage]，保证整个会话视觉一致。
  /// 不传则由 SDK 内部随机一套。
  static Future<bool> openCustomerService(
    BuildContext context, {
    AppChatTheme? theme,
  }) async {
    if (!_initialized) {
      assert(false, 'QiChatUISDK.openCustomerService 前必须先调用 init()');
      return false;
    }
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntrancePage(theme: theme)),
    );
    return true;
  }

  /// 直接打开某个 consult 的聊天页。
  static Future<bool> openChat(
    BuildContext context,
    Int64 consultId, {
    AppChatTheme? theme,
  }) async {
    if (!_initialized) {
      assert(false, 'QiChatUISDK.openChat 前必须先调用 init()');
      return false;
    }
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ChatPage(consultId: consultId, theme: theme)),
    );
    return true;
  }

  /// 打开设备信息页。展示当前设备 / 应用 / 线路状态，支持保存为图片。
  ///
  /// iOS 上需要宿主自行在 Info.plist 添加 `NSPhotoLibraryAddUsageDescription`，
  /// 否则「保存为图片」会被系统直接拒绝。
  static Future<void> openDeviceInfo(
    BuildContext context, {
    AppChatTheme? theme,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DeviceInfoPage(theme: theme)),
    );
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

  /// 冷启动后、未调用 [init] 之前，把上次落盘的未读读回内存。
  /// 宿主在"商户列表"这类不依赖具体商户身份的页面，可以提前调用让红点立刻可见。
  /// 重复调用会跳过。
  static Future<void> preloadUnread() => UnreadManager.instance.init();

  /// 仅当本地没有该 consult 的非零未读时，用 [count] 兜底写入并广播。
  /// 配合 [queryUnreadFor] 使用：服务端快照不覆盖 WS 实时累加的本地值。
  static void setUnreadIfAbsent(int consultId, int count) =>
      UnreadManager.instance.setUnreadIfAbsent(consultId, count);

  /// Stateless 拉取某个商户的服务端快照未读 `consultId -> unread`。
  ///
  /// 完全不触碰 [QiChatConfig.current]，因此宿主可以在"商户列表"页对多个商户
  /// 并行调用，不会干扰当前已 [init] 的那个商户的 WS 连接或全局 cert / domain。
  ///
  /// 失败（线检超时 / HTTP 错误）返回空 Map，由宿主决定如何合并到本地
  /// [UnreadManager]——推荐用 [UnreadManager.setUnreadIfAbsent]，保留 WS
  /// 实时累加值优先于服务端快照。
  static Future<Map<int, int>> queryUnreadFor({
    required String cert,
    required int merchantId,
    required String detectUrls,
    Duration timeout = const Duration(seconds: 10),
  }) =>
      UnreadQuery.fetch(
        cert: cert,
        merchantId: merchantId,
        detectUrls: detectUrls,
        timeout: timeout,
      );

  /// 按 consultId 维度的未读流。宿主在"商户列表"等聚合页可基于自己的 consultIds
  /// 求交集得到每个商户的未读数。
  static Stream<Map<int, int>> get unreadMapStream =>
      UnreadManager.instance.unreadStream;

  /// 按 consultId 维度的未读快照（同步读取）。
  static Map<int, int> get unreadMap => UnreadManager.instance.getAllUnread();

  /// 用户进入某个 consult 的 ChatPage 时触发，emit 该 consultId。
  /// 宿主可借此把"用户实际用过的 consultId"持久化到自己的商户记录里。
  static Stream<int> get consultEnteredStream =>
      GlobalChatManager.instance.consultEnteredStream;

  /// 宿主登出时调用，断开连接、清理监听。
  static Future<void> dispose() async {
    if (!_initialized) return;
    GlobalChatManager.instance.stop();
    GlobalChatManager.instance.clearAllListeners();
    QiChatConfig.reset();
    _initialized = false;
  }
}
