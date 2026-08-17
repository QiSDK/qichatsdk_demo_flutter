# qichat_ui_sdk

QiChat 客服 UI SDK ——把 `flutter_qichat_sdk` 协议层封装成一个**开箱即用的客服界面**（客服列表 + 聊天页 + 未读管理 + 评价），可被任意 Flutter App 直接接入。

宿主只要一次 `init`，再调 `openCustomerService(context)` 即可让用户进入"客服列表 → 聊天"全流程；线路检测、连接生命周期、未读同步、WebSocket 重连全部由 SDK 接管。

## 仓库结构

```
qichat_ui_sdk/                  # 库（package 根）
├── lib/
│   ├── qichat_ui_sdk.dart      # 公共 API barrel：export QiChatUISDK
│   └── src/                    # 内部实现（不建议宿主直接 import src/）
├── assets/                     # SDK 自带图片资源
├── pubspec.yaml                # name: qichat_ui_sdk
└── example/                    # 演示 demo（独立 Flutter app）
    ├── lib/
    │   ├── main.dart           # 演示入口 + 联系客服按钮
    │   ├── BWSettingViewController.dart  # demo 调试用设置页
    │   └── demo_config.dart    # demo 默认值 + SharedPreferences 持久化
    ├── ios/  android/  ...     # 运行 demo 用的平台目录
    └── pubspec.yaml            # 依赖 qichat_ui_sdk: { path: ../ }
```

## 接入步骤（宿主端）

### 1. 添加依赖

`pubspec.yaml`：

```yaml
dependencies:
  qichat_ui_sdk:
    git:
      url: <your-git-url>
      ref: <branch-or-tag>
  # 或本地路径
  # qichat_ui_sdk:
  #   path: ../qichat_ui_sdk
```

### 2. 应用启动时初始化

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
    detectUrls: 'https://csh5-3-test.qlbig05.xyz,https://backup.example.com',
    baseUrlImage: 'https://imagesacc.hfxg.xyz',
  );

  runApp(const MyApp());
}
```

### 3. **重要：MaterialApp 必须包 FlutterSmartDialog**

SDK 的 toast / loading 等使用 `flutter_smart_dialog`，宿主需在 MaterialApp 上挂上 builder：

```dart
MaterialApp(
  builder: FlutterSmartDialog.init(),
  home: MyHomePage(),
)
```

### 4. 点击"联系客服"

```dart
ElevatedButton(
  onPressed: () => QiChatUISDK.openCustomerService(context),
  child: const Text('联系客服'),
)
```

可选：显示未读小红点。

```dart
StreamBuilder<int>(
  stream: QiChatUISDK.totalUnreadStream,
  builder: (_, snap) {
    final n = snap.data ?? 0;
    return n > 0 ? Badge(label: Text('$n')) : const SizedBox.shrink();
  },
)
```

### 5. 登出 / 切账号

```dart
await QiChatUISDK.dispose();        // 断开连接、清监听
await QiChatUISDK.init(...);        // 用新身份重新 init
```

## 公共 API

| 方法 | 作用 |
|---|---|
| `QiChatUISDK.init({...})` | 一次性初始化：写入配置、启动连接管理、启动线路检测、注册 lifecycle observer |
| `QiChatUISDK.openCustomerService(context)` | 等待线路就绪后 push 客服列表页 |
| `QiChatUISDK.openChat(context, consultId)` | 直接 push 某个 consult 的聊天页 |
| `QiChatUISDK.lineStatusStream` | 线路检测状态文本流（用于宿主显示"正在检测..." 等）|
| `QiChatUISDK.totalUnreadStream` | 未读总数流（红点）|
| `QiChatUISDK.totalUnread` | 同步读取当前未读总数 |
| `QiChatUISDK.dispose()` | 断开连接、清空状态 |

## 运行 demo

```bash
cd example
flutter pub get
flutter run
```

启动后点击"联系客服"按钮可看到客服列表。右下角齿轮按钮进入设置页可手动改 cert / userId 等测试不同租户。

## 注意事项

1. **WidgetsFlutterBinding**：宿主必须先调用 `WidgetsFlutterBinding.ensureInitialized()` 再调 `QiChatUISDK.init`，否则注册 lifecycle observer 会崩。
2. **assets 自动打包**：SDK 自带的图片资源在库的 `pubspec.yaml` 里声明，宿主无需重复声明；库内代码已加 `package: 'qichat_ui_sdk'` 前缀。
3. **iOS/macOS WebView**：SDK init 时会自动把 `WebViewPlatform.instance` 设为 `WkWebViewPlatform`（用于聊天中预览图片/视频）。如果宿主自己也设置过 WebView 平台，可能需要协调顺序。
4. **桌面端 window_manager**：demo 主程序里调了 `windowManager.ensureInitialized()`，SDK 不负责这个——宿主桌面端按需自管。
