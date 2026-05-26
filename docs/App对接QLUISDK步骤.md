# QiChat UISDK 集成步骤

## 1. 从后端获取配置

从自家后端拉取 `cert`、`userId`、`userName`、`merchantId`、`detectUrls`、`baseUrlImage` 等参数，用于后续 SDK 初始化和线路检测。

> `cert` 是租户身份凭证，**严禁硬编码到 App 里**，按用户从安全接口下发。

## 2. 初始化

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

## 3. 订阅状态流（可选）

SDK 把线路检测与未读总数都做成**广播流**，在任意页面 `initState` 里订阅即可，离开页面记得 `cancel`。

### 3.1 线路检测状态

`QiChatUISDK.lineStatusStream` 推送线路检测状态文本，绑到 UI 文案可让用户看到「正在检测线路 / 已切到备用线路 / 当前线路 ping=120ms」等。

```dart
StreamSubscription? _lineSub;

@override
void initState() {
  super.initState();
  _lineSub = QiChatUISDK.lineStatusStream.listen((status) {
    if (mounted) setState(() => _lineStatus = status);
  });
}

@override
void dispose() {
  _lineSub?.cancel();
  super.dispose();
}
```

### 3.2 未读总数

`QiChatUISDK.totalUnreadStream` 推送所有会话未读之和。每当未读变化（新消息到达 / 用户读了某条 / 切会话）就推一次。配合同步读取的 `QiChatUISDK.totalUnread` 作为 `initialData`，可避免红点首帧闪烁。

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

## 4. 打开客服界面

### 4.1 客服列表入口

```dart
ElevatedButton(
  onPressed: () => QiChatUISDK.openCustomerService(context),
  child: const Text('联系客服'),
)
```

### 4.2 直接进入指定聊天

适用于从消息推送 / DeepLink 跳转，已知具体 `consultId` 的场景：

```dart
import 'package:fixnum/fixnum.dart';

ElevatedButton(
  onPressed: () => QiChatUISDK.openChat(context, Int64(consultId)),
  child: const Text('继续会话'),
)
```

## 5. 主题

### 5.1 内置主题

| 静态成员 | 类型 | 说明 |
|---|---|---|
| `AppChatTheme.defaultTheme` | `AppChatTheme` | SDK 默认蓝色主题 |
| `AppChatTheme.presets` | `List<AppChatTheme>` | 10 套精选主题（晴空蓝 / 薄暮紫 / 蜜桃粉 / 抹茶绿 / 日落橙 / 星空靛 / 暗夜紫 / 极简灰 / 幻夜紫 / 晨雾白）|
| `AppChatTheme.random()` | `AppChatTheme` | 从 `presets` 随机抽一套；`presets` 为空时返回 `defaultTheme` |

### 5.2 指定主题

```dart
final myTheme = AppChatTheme.presets[3]; // 抹茶绿
QiChatUISDK.openCustomerService(context, theme: myTheme);
```

### 5.3 自定义主题

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

## 6. 销毁 / 切账号

`QiChatUISDK.dispose()` 断开 wss 连接、清空 SDK 监听、重置内部 config。

调用场景：

- 用户登出
- 切换账号 / 商户（也可直接调 `init`，内部会自动先 `dispose`）
- 宿主退出客服模块且确定后续不再需要

```dart
await QiChatUISDK.dispose();
```
