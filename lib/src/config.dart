import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import 'package:flutter_qichat_sdk/src/dartOut/api/common/c_message.pb.dart'
    as cmessage;

import 'model/Entrance.dart';
import 'model/ServiceKeyword.dart';

/// 宿主处理「卡片跳转」的回调签名。
///
/// [jumpUrl] 是卡片配置里的跳转链接，[jumpCategory] 为跳转类型：
/// `1=小程序`（如 `pages/Withdraw/Record`）、`2=H5`（完整网址）、`3=原生页`
/// （见 [ServiceKeyword.jumpMiniProgram] 等常量）。宿主据此把用户导航到自己的
/// 小程序容器 / WebView / 原生页。回调携带聊天页的 [context]，可直接
/// `Navigator.push`。
///
/// 注意：一旦注册处理器，**所有类型**（含 H5）都交给宿主；未注册时 SDK 才会
/// 用「H5 → 外部浏览器、其余 → 内置模拟页」兜底。
typedef CardJumpHandler = void Function(
    BuildContext context, String jumpUrl, int? jumpCategory);

/// 宿主通过 [QiChatUISDK.setCardJumpHandler] 注册的卡片跳转处理器。
///
/// 作为库级变量而非 [QiChatConfig] 字段：跳转是「宿主怎么打开页面」的能力，
/// 与具体商户会话无关，不应被 [QiChatConfig.reset]（登出 / 切商户）清掉。
/// 为 null 时 SDK 用内置模拟页 `MiniProgramMockPage` 兜底。
CardJumpHandler? cardJumpHandler;

/// SDK 运行时单例配置。
///
/// 由 [QiChatUISDK.init] 写入，内部模块通过 [QiChatConfig.current] 读取。
/// 不要直接 new；使用 [QiChatConfig.initialize] 初始化全局唯一实例。
class QiChatConfig {
  // 宿主一次性传入的配置
  String cert;
  int userId;
  String userName;
  int merchantId;
  String platformName;
  String detectUrls;
  String baseUrlImage;
  int maxSessionMinutes;
  int userType;

  // 运行时可变状态
  String xToken = '';
  String domain = '';
  Entrance? entrance;
  cmessage.WithAutoReply? withAutoReplyBuilder;
  final Map<Int64, List<types.Message>> unSentMessage = {Int64(0): []};

  /// 宿主通过 [QiChatUISDK.setAutoCardKeywords] 传入的关键词卡片配置。
  /// 用户输入命中其中任一 keyword 时，自动发送 MST_AUTO_CARD 卡片消息。
  List<ServiceKeyword> serviceKeywords = [];

  // SDK 协议层单例（整个生命周期共用一个 ChatLib）
  final ChatLib chatLib = ChatLib();

  // 兼容字段：部分模块写过 reportRequest（结构占位用）
  final ReportRequest reportRequest = ReportRequest();

  /// 聊天ID。连接维度：一条 wss 连接对应一个 chatId，跨咨询类型共用，
  /// 由 SCHi.id 在连接成功时下发。'0' 表示未知。只存内存，不落盘。
  String chatId = '0';

  String get baseUrlApi => 'https://$domain';

  QiChatConfig._({
    required this.cert,
    required this.userId,
    required this.userName,
    required this.merchantId,
    required this.platformName,
    required this.detectUrls,
    required this.baseUrlImage,
    required this.maxSessionMinutes,
    required this.userType,
  });

  static QiChatConfig? _current;

  /// 返回当前实例。未初始化时返回内部 fallback（便于 dev 调试），生产环境
  /// 由 [QiChatUISDK.init] 保证已设置。
  static QiChatConfig get current {
    return _current ??= QiChatConfig._(
      cert: '',
      userId: 0,
      userName: '',
      merchantId: 0,
      platformName: '',
      detectUrls: '',
      baseUrlImage: '',
      maxSessionMinutes: 300,
      userType: 2,
    );
  }

  static bool get isInitialized => _current != null;

  /// 由 [QiChatUISDK.init] 调用，写入一次性配置。
  static void initialize({
    required String cert,
    required int userId,
    required String userName,
    required int merchantId,
    required String detectUrls,
    required String baseUrlImage,
    String platformName = '',
    int maxSessionMinutes = 300,
    int userType = 2,
  }) {
    final cfg = current
      ..cert = cert
      ..userId = userId
      ..userName = userName
      ..merchantId = merchantId
      ..platformName = platformName
      ..detectUrls = detectUrls
      ..baseUrlImage = baseUrlImage
      ..maxSessionMinutes = maxSessionMinutes
      ..userType = userType;
    _current = cfg;
  }

  /// 测试或登出场景下清空状态。
  static void reset() {
    _current = null;
  }
}

/// 占位结构，与原 Constant.dart 中的 `ReportRequest` 保持一致。
class ReportRequest {}
