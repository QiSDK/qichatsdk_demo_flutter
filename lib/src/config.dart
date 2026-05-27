import 'package:fixnum/fixnum.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import 'package:flutter_qichat_sdk/src/dartOut/api/common/c_message.pb.dart'
    as cmessage;

import 'model/Entrance.dart';

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

  // SDK 协议层单例（整个生命周期共用一个 ChatLib）
  final ChatLib chatLib = ChatLib();

  // 兼容字段：部分模块写过 reportRequest（结构占位用）
  final ReportRequest reportRequest = ReportRequest();
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
