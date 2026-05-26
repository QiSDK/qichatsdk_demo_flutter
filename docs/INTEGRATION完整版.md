# QiChat UISDK 对接文档

> 适用版本：`qichat_ui_sdk` 2.0.0
> 目标读者：把 QiChat 客服功能集成到自家 Flutter App 的开发者

QiChat UISDK 把 `flutter_qichat_sdk` 协议层封装成开箱即用的客服界面（客服列表、聊天页、未读管理、评价、设备信息）。宿主 App 一次 `init`、再调 `openCustomerService(context)` 就能让用户走完「联系客服 → 选择会话 → 聊天」全流程；线路检测、WebSocket 连接 / 重连、生命周期、未读同步全部由 SDK 内部接管。

---

## 目录

1. [环境要求](#1-环境要求)
2. [接入步骤](#2-接入步骤)
3. [`QiChatUISDK` API 参考](#3-qichatuisdk-api-参考)
4. [`AppChatTheme` 主题](#4-appchattheme-主题)
5. [常见集成模式](#5-常见集成模式)
6. [注意事项与常见问题](#6-注意事项与常见问题)

---

## 1. 环境要求

| 项 | 要求 |
|---|---|
| Flutter SDK | `>=3.0.0 <4.0.0` |
| Dart SDK | `>=3.0.0` |
| 目标平台 | iOS / Android / macOS / Windows |
| 必备插件 | `flutter_smart_dialog`（宿主必须在 `MaterialApp` 上挂 builder，见 §2.4） |

宿主 App 自身需要联网权限。SDK 内部会用到摄像头、麦克风、相册（聊天发图 / 录制 / 保存设备信息截图），平台权限需要宿主在 Info.plist / AndroidManifest 中声明。

---

## 2. 接入步骤

### 2.1 添加依赖

`pubspec.yaml`：

```yaml
dependencies:
  qichat_ui_sdk:
    git:
      url: <your-git-url>
      ref: <branch-or-tag>      # 或固定到 tag，如 v2.0.0
  # 或本地路径
  # qichat_ui_sdk:
  #   path: ../qichat_ui_sdk
```

SDK 自带的图片资源在库自己的 `pubspec.yaml` 已声明并加 `package: 'qichat_ui_sdk'` 前缀，宿主**无需重复声明 assets**。

### 2.2 iOS 平台配置

在 `ios/Runner/Info.plist` 中至少添加以下 key：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机以便在客服会话中拍照</string>

<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风以便在客服会话中录音</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要读取相册以便在客服会话中发送图片 / 视频</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要写入相册以便保存设备信息截图</string>
```

> `NSPhotoLibraryAddUsageDescription` 是 [`openDeviceInfo`](#openDeviceInfo) 内「保存为图片」功能必须的；缺失会被系统直接拒绝。

### 2.3 Android 平台配置

宿主 App 的 `AndroidManifest.xml`：

- 若你的接入域名是 `http://`（线路检测、图片 CDN 任一为非 HTTPS），需在 `<application>` 上加 `android:usesCleartextTraffic="true"`。
- 摄像头 / 相册 / 麦克风权限由 `image_picker`、`camera`、`wechat_assets_picker` 等子插件在自己的 manifest 中合并声明，宿主一般无需手动添加。

### 2.4 包 `FlutterSmartDialog`

SDK 的 toast、loading 走 `flutter_smart_dialog`，宿主必须在 `MaterialApp` 上挂 builder：

```dart
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

MaterialApp(
  builder: FlutterSmartDialog.init(),
  home: const MyHomePage(),
)
```

### 2.5 初始化

宿主在 `main()` 中调用一次 `QiChatUISDK.init`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();   // 必须

  await QiChatUISDK.init(
    cert: '<your-cert>',
    userId: 666667,
    userName: '王五',
    merchantId: 230,
    detectUrls: 'https://csapi.example.com,https://backup.example.com',
    baseUrlImage: 'https://images.example.com',
  );

  runApp(const MyApp());
}
```

### 2.6 触发客服界面

```dart
ElevatedButton(
  onPressed: () => QiChatUISDK.openCustomerService(context),
  child: const Text('联系客服'),
)
```

到这里集成已经可用。后续章节是各 API 的完整参考。

---

## 3. `QiChatUISDK` API 参考

`QiChatUISDK` 是 SDK 的唯一公共入口类，所有方法和成员都是 `static`。

```dart
import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';
```

### 3.1 `init(...) → Future<bool>`

应用启动后调用一次，完成「线路检测 → 用拿到的 domain 建立 wss 连接 → 启动保活监控」。

```dart
static Future<bool> init({
  required String cert,
  required int userId,
  required String userName,
  required int merchantId,
  required String detectUrls,
  required String baseUrlImage,
  String tenantName = '',
  int maxSessionMinutes = 300,
  int userType = 2,
  Duration lineDetectTimeout = const Duration(seconds: 10),
});
```

**参数**

| 参数 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `cert` | `String` | ✅ | — | 租户证书。**切勿硬编码在 App 里**，从你自家的安全后端下发。 |
| `userId` | `int` | ✅ | — | 业务方用户 ID（用于客服端识别用户身份）。 |
| `userName` | `String` | ✅ | — | 用户名，用于客服端 / 聊天页显示。 |
| `merchantId` | `int` | ✅ | — | 商户 ID。 |
| `detectUrls` | `String` | ✅ | — | 逗号分隔的线路检测 URL 列表，例：`'https://a.example.com,https://b.example.com'`。SDK 会探测可用线路并选最快的一条。 |
| `baseUrlImage` | `String` | ✅ | — | 图片资源 CDN 域名。 |
| `tenantName` | `String` | ❌ | `''` | 商户名，显示在聊天页 AppBar 右侧。 |
| `maxSessionMinutes` | `int` | ❌ | `300` | 会话最大分钟数。 |
| `userType` | `int` | ❌ | `2` | 用户类型，业务约定值，一般保持默认。 |
| `lineDetectTimeout` | `Duration` | ❌ | `10s` | 线路检测超时。 |

**前置条件**

- 调用前必须已执行 `WidgetsFlutterBinding.ensureInitialized()`；否则 SDK 内部注册 lifecycle observer 会崩。
- iOS / macOS 上，`init` 内部会自动把 `WebViewPlatform.instance` 设为 `WkWebViewPlatform`（聊天页内嵌图片 / 视频预览需要）。如果宿主自己也设置过 WebView 平台，**注意顺序**：让 SDK init 在你的 WebView 平台设置之前 / 之后由你决定，通常 SDK init 后不要再覆盖。

**返回值**

- `true`：线路检测就绪，wss 连接已发起，可以调 `openCustomerService` / `openChat`。
- `false`：在 `lineDetectTimeout` 内没有任何 detect URL 返回可用 → 宿主可以提示「线路异常，请稍后再试」。

**幂等性**

重复调用 `init` 会先 `dispose()` 再重走整个流程，所以可以放心地在「设置页改完配置」「切账号」等场景下二次调用。

---

### 3.2 `openCustomerService(context, {theme}) → Future<bool>`

打开**客服列表页**（也是默认入口），让用户挑选要联系的客服。

```dart
static Future<bool> openCustomerService(
  BuildContext context, {
  AppChatTheme? theme,
});
```

| 参数 | 说明 |
|---|---|
| `context` | 用于 `Navigator.push`。 |
| `theme` | 可选主题。不传则 SDK 内部用 [`AppChatTheme.random()`](#appchatthemerandom)。传入后会一路下传到聊天页，保证整段会话视觉一致。 |

**返回值**：`true` 表示成功 push；`false` 表示尚未 `init` 或 `context` 已 unmounted。

**典型用法**

```dart
final ok = await QiChatUISDK.openCustomerService(context, theme: myTheme);
if (!ok && mounted) {
  SmartDialog.showToast('线路未就绪，请稍后再试');
}
```

---

### 3.3 `openChat(context, consultId, {theme}) → Future<bool>`

直接打开**某个具体 consult 的聊天页**，跳过客服列表。常用于：从消息推送点进来、深链跳转。

```dart
static Future<bool> openChat(
  BuildContext context,
  Int64 consultId, {
  AppChatTheme? theme,
});
```

| 参数 | 说明 |
|---|---|
| `consultId` | `Int64`（`fixnum` 包），目标会话 ID。 |
| `theme` | 同 [`openCustomerService`](#32-opencustomerservicecontext-theme--futurebool)。 |

**返回值**：同上，`false` 表示未 init 或 context unmounted。

---

### 3.4 `openDeviceInfo(context, {theme}) → Future<void>` <a id="openDeviceInfo"></a>

打开**设备信息页**，展示当前设备 / 应用 / 线路状态，支持把页面保存为图片让用户提交反馈。

```dart
static Future<void> openDeviceInfo(
  BuildContext context, {
  AppChatTheme? theme,
});
```

> iOS 必须在 `Info.plist` 添加 `NSPhotoLibraryAddUsageDescription`，否则「保存为图片」会被系统直接拒绝。

---

### 3.5 `lineStatusStream → Stream<String>`

线路检测状态文本流。**广播流**，可被多处订阅。宿主可以把它直接绑在 UI 文案上让用户看到「正在检测线路 / 已切到备用线路 / 当前线路 ping=120ms」等。

```dart
StreamSubscription? _sub;

@override
void initState() {
  super.initState();
  _sub = QiChatUISDK.lineStatusStream.listen((status) {
    if (mounted) setState(() => _lineStatus = status);
  });
}

@override
void dispose() {
  _sub?.cancel();
  super.dispose();
}
```

---

### 3.6 `totalUnreadStream → Stream<int>`

全局未读总数流，所有会话未读之和。每当未读变化（新消息到达 / 用户读了某条 / 切会话）就推一次。

```dart
StreamBuilder<int>(
  stream: QiChatUISDK.totalUnreadStream,
  initialData: QiChatUISDK.totalUnread,
  builder: (_, snap) {
    final n = snap.data ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Badge(label: Text(n > 99 ? '99+' : '$n'));
  },
)
```

---

### 3.7 `totalUnread → int`

同步读取**当前**未读总数。适合首次构建时和 `StreamBuilder.initialData` 配合，避免红点闪烁。

---

### 3.8 `dispose() → Future<void>`

断开 wss 连接、清空 SDK 监听、重置内部 config。

调用场景：

- 用户登出
- 切换账号 / 商户（一般直接调 `init`，里面会自动先 dispose）
- 宿主退出客服模块且确定后续不再需要

```dart
await QiChatUISDK.dispose();
```

---

## 4. `AppChatTheme` 主题

```dart
import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';
// 同 barrel 导出
```

### 4.1 字段

```dart
class AppChatTheme {
  final Color gradientStartColor;       // 渐变起始色
  final Color gradientEndColor;         // 渐变结束色
  final AppChatGradientDirection gradientDirection; // 渐变方向
  final Color tintColor;                // 统一按钮 / 图标着色
  final Color leftBubbleColor;          // 客服气泡背景
  final Color leftBubbleTextColor;      // 客服气泡文字
  final Color rightBubbleColor;         // 用户气泡背景
  final Color rightBubbleTextColor;     // 用户气泡文字
}
```

| 字段 | 必填 | 默认 |
|---|---|---|
| `gradientStartColor` | ✅ | — |
| `gradientEndColor` | ✅ | — |
| `gradientDirection` | ❌ | `topToBottom` |
| `tintColor` | ✅ | — |
| `leftBubbleColor` | ❌ | 白色 88% 透明 |
| `leftBubbleTextColor` | ❌ | `#1A1A1A` |
| `rightBubbleColor` | ❌ | `tintColor` 92% 透明 |
| `rightBubbleTextColor` | ❌ | `Colors.white` |

派生：

- `linearGradient → LinearGradient`：直接用于 `Container.decoration`。
- `gradientBegin / gradientEnd → Alignment`：自行组装 gradient 时用。

### 4.2 `AppChatGradientDirection`

```dart
enum AppChatGradientDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  topLeftToBottomRight,
  topRightToBottomLeft,
}
```

### 4.3 内置主题

| 静态成员 | 类型 | 说明 |
|---|---|---|
| `AppChatTheme.defaultTheme` | `AppChatTheme` | SDK 默认蓝色主题 |
| `AppChatTheme.presets` | `List<AppChatTheme>` | 10 套精选主题（晴空蓝 / 薄暮紫 / 蜜桃粉 / 抹茶绿 / 日落橙 / 星空靛 / 暗夜紫 / 极简灰 / 幻夜紫 / 晨雾白） |
| `AppChatTheme.random()` <a id="appchatthemerandom"></a> | `AppChatTheme` | 从 `presets` 随机抽一套；`presets` 为空时返回 `defaultTheme` |

### 4.4 自定义主题

```dart
final myTheme = AppChatTheme(
  gradientStartColor: const Color(0xFFF7F7FA),
  gradientEndColor: const Color(0xFFE6ECF5),
  gradientDirection: AppChatGradientDirection.topToBottom,
  tintColor: const Color(0xFF4589F6),
  // 其余 4 个气泡色用默认即可
);

QiChatUISDK.openCustomerService(context, theme: myTheme);
```

---

## 5. 常见集成模式

### 5.1 「联系客服」按钮带未读红点

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    ElevatedButton(
      onPressed: () => QiChatUISDK.openCustomerService(context),
      child: const Text('联系客服'),
    ),
    StreamBuilder<int>(
      stream: QiChatUISDK.totalUnreadStream,
      initialData: QiChatUISDK.totalUnread,
      builder: (_, snap) {
        final n = snap.data ?? 0;
        if (n == 0) return const SizedBox.shrink();
        return Positioned(
          right: -6, top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              n > 99 ? '99+' : '$n',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        );
      },
    ),
  ],
)
```

### 5.2 显示线路状态文案

```dart
String _lineStatus = '';
StreamSubscription? _lineSub;

@override
void initState() {
  super.initState();
  _lineSub = QiChatUISDK.lineStatusStream.listen(
    (s) => mounted ? setState(() => _lineStatus = s) : null,
  );
}

@override
void dispose() {
  _lineSub?.cancel();
  super.dispose();
}
```

### 5.3 登出 / 切账号

```dart
Future<void> switchAccount(NewUser u) async {
  await QiChatUISDK.dispose();
  await QiChatUISDK.init(
    cert: u.cert,
    userId: u.id,
    userName: u.name,
    merchantId: u.merchantId,
    detectUrls: '...',
    baseUrlImage: '...',
  );
}
```

> 也可以直接调 `init`，内部检测到已 `_initialized` 会先自动 `dispose`，再重走 init 流程。`dispose` + `init` 的写法只是让意图更明确。

### 5.4 从推送 / DeepLink 直接打开会话

业务侧拿到 consultId 后：

```dart
import 'package:fixnum/fixnum.dart';

QiChatUISDK.openChat(context, Int64(consultIdFromPush));
```

---

## 6. 注意事项与常见问题

1. **`WidgetsFlutterBinding.ensureInitialized()`**：必须在 `init` 之前调用，否则 SDK 注册 lifecycle observer 时会崩。
2. **`MaterialApp.builder` 必须包 `FlutterSmartDialog.init()`**：SDK 的 toast / loading 依赖它；不包会导致 dialog 完全不显示。
3. **不要 `import` `package:qichat_ui_sdk/src/...`**：`src/` 下是实现细节，可能在任意小版本被重构。`lib/qichat_ui_sdk.dart` 才是稳定的公共 API barrel。
4. **assets 自动打包**：SDK 自带图片在库的 `pubspec.yaml` 已声明，宿主**不要**重复声明。
5. **iOS / macOS WebView 平台**：`init` 内部会设 `WkWebViewPlatform`，如果你 App 已经设过其他 WebView 平台实现，安排好顺序（一般让 SDK init 后保持现状即可，不要再 set 回去）。
6. **桌面端 `window_manager`**：SDK 不负责窗口管理，桌面端由宿主自管。
7. **线路异常**：`init` 返回 `false` 通常意味着所有 `detectUrls` 都不可达。先检查域名是否正确、是否被 firewall 拦截、Android 是否漏配 `usesCleartextTraffic`。
8. **重复 `init`**：安全，内部会先 `dispose` 再重建。无需自己判 `_initialized`。
9. **未读为何不更新**：检查 `MaterialApp.builder` 是否包了 `FlutterSmartDialog.init`，以及 wss 是否已连接（看 `lineStatusStream`）。
10. **`cert` 安全**：`cert` 是租户身份凭证，**严禁硬编码到 App 包里**。从你自家后端按用户下发（一般和登录接口一起返回）。

---

## 附：最小可运行示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await QiChatUISDK.init(
    cert: '<your-cert>',
    userId: 666667,
    userName: '王五',
    merchantId: 230,
    detectUrls: 'https://csapi.example.com',
    baseUrlImage: 'https://images.example.com',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FlutterSmartDialog.init(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Demo')),
        body: Center(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => QiChatUISDK.openCustomerService(ctx),
              child: const Text('联系客服'),
            ),
          ),
        ),
      ),
    );
  }
}
```

更完整的示例见仓库 `example/` 目录（含设置页、备用客服 DeepLink、未读红点、线路状态）。
