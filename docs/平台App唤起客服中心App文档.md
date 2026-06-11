// 平台App带参数打开客服中心 App；如果客服中心App没有安装，打开一个网址链接
Future<void> _openBackupCustomerService() async {
  final cfg = await DemoConfig.load();
  final prefs = await SharedPreferences.getInstance();
  final xToken = prefs.getString(PARAM_XTOKEN) ?? '';

  // _themeIndex: 0-晨雾白 → 1-暗夜神殿 → 蜜桃粉 → 抹茶绿 → 日落橙 → 星空靛 → 暗夜紫 → 极简灰 → 幻夜紫 → 晴空蓝 → 11-薄暮紫
  final params = <String, String>{
    'cert': cfg.cert,
    'userId': '${cfg.userId}',
    'merchantId': '${cfg.merchantId}',
    'userName': cfg.userName,
    'userType': '${cfg.userType}',
    'platformName': cfg.platformName,
    'themeIndex': '$_themeIndex',
    if (xToken.isNotEmpty) 'xToken': xToken,
  };

  final deepLink = Uri(
    scheme: 'juhekefu',
    host: 'open',
    queryParameters: params,
  );

  bool deepLinkOk = false;
  try {
    deepLinkOk =
        await launchUrl(deepLink, mode: LaunchMode.externalApplication);
  } catch (_) {
    deepLinkOk = false;
  }
  if (deepLinkOk || !mounted) return;

  // 未安装客服中心 App，退到外部网页
  final webUrl = cfg.backupWebUrl.trim();
  if (webUrl.isEmpty) {
    SmartDialog.showToast('未安装客服中心 App，且未配置备用网页');
    return;
  }

  final base = Uri.parse(webUrl);
  final webUri = base.replace(queryParameters: {
    ...base.queryParameters,
    ...params,
  });

  try {
    final ok =
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) SmartDialog.showToast('打开备用网页失败');
  } catch (_) {
    if (mounted) SmartDialog.showToast('打开备用网页失败');
  }
}
