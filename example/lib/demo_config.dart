import 'package:shared_preferences/shared_preferences.dart';

import 'package:qichat_ui_sdk/src/Constant.dart'
    show
        PARAM_LINES,
        PARAM_USERTYPE,
        PARAM_XTOKEN;

/// Demo 专用配置加载。
///
/// 维护一组硬编码默认值（开发测试用）+ SharedPreferences 覆盖，供启动时
/// 喂给 [QiChatUISDK.init]。**生产宿主不需要这种结构**——它会直接传入登录后
/// 拿到的身份。
class DemoConfig {
  static const String defaultCert =
      'COYBEAIYwNgoIPIBKIOzgtGXMg.-t5P7JEo-Dg7nlJpu6uZzNJE3QtRaJV9bE1yhZqduThDLHE6MGxCBFuwF38v5z5SJhoD40fmwAtPj4iIL9iPAQ';
  static const int defaultMerchantId = 230;
  static const int defaultUserId = 666667;
  static const String defaultUserName = '王五';
  static const String defaultDetectUrls =
      'https://csh5-3-test.qlbig05.xyz,https://xxx.qixin14.xxx';
  static const String defaultBaseUrlImage = 'https://images-3-test.qlbig05.xyz';
  static const int defaultMaxSessionMinutes = 300;
  static const int defaultUserType = 2;
  static const String defaultBackupWebUrl = 'https://www.baidu.com';
  static const String defaultPlatformName = '测试平台';

  final String cert;
  final int userId;
  final String userName;
  final int merchantId;
  final String detectUrls;
  final String baseUrlImage;
  final int maxSessionMinutes;
  final int userType;
  final String backupWebUrl;
  final String platformName;

  DemoConfig({
    required this.cert,
    required this.userId,
    required this.userName,
    required this.merchantId,
    required this.detectUrls,
    required this.baseUrlImage,
    required this.maxSessionMinutes,
    required this.userType,
    required this.backupWebUrl,
    required this.platformName,
  });

  static Future<DemoConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DemoConfig(
      detectUrls: prefs.getString(PARAM_LINES) ?? defaultDetectUrls,
      cert: prefs.getString('PARAM_CERT') ?? defaultCert,
      merchantId: prefs.getInt('PARAM_MERCHANT_ID') ?? defaultMerchantId,
      userId: prefs.getInt('PARAM_USER_ID') ?? defaultUserId,
      userName: prefs.getString('PARAM_USERNAME') ?? defaultUserName,
      baseUrlImage:
          prefs.getString('PARAM_ImageBaseURL') ?? defaultBaseUrlImage,
      maxSessionMinutes:
          prefs.getInt('PARAM_MAXSESSIONMINS') ?? defaultMaxSessionMinutes,
      userType: (prefs.getInt(PARAM_USERTYPE) ?? defaultUserType - 1) + 1,
      backupWebUrl:
          prefs.getString('PARAM_BACKUP_WEB_URL') ?? defaultBackupWebUrl,
      platformName:
          prefs.getString('PARAM_PLATFORM_NAME') ?? defaultPlatformName,
    );
  }

  /// 清空 xToken 缓存（设置变更或登出时）。
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PARAM_XTOKEN, '');
  }
}
