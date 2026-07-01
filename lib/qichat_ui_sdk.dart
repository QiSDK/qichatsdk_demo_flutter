/// QiChat UISDK 公共入口。
///
/// 宿主 App 通过本文件暴露的 [QiChatUISDK] 调用客服功能：
///
/// ```dart
/// await QiChatUISDK.init(
///   cert: '...',
///   userId: 666667,
///   userName: '王五',
///   merchantId: 230,
///   detectUrls: 'https://ddd,https://...',
///   baseUrlImage: 'https://imagesacc.hfxg.xyz',
/// );
///
/// // 用户点击"联系客服"
/// QiChatUISDK.openCustomerService(context);
/// ```
library qichat_ui_sdk;

export 'src/api/qichat_ui_sdk.dart' show QiChatUISDK;
export 'src/config.dart' show CardJumpHandler;
export 'src/model/AppChatTheme.dart' show AppChatTheme, AppChatGradientDirection;
