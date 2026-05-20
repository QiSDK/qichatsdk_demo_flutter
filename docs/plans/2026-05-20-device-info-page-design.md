# 设备信息（Device Info）页面 — 设计

日期：2026-05-20
分支：refactor/uisdk

## 背景

宿主 App（28圈 等业务方）在客服流程里需要一个「设备信息」页，让用户能把本机环境一键发给客服排查问题。截图见 `设备信息.png`。

## 目标

- 只读展示设备 / 应用 / SDK 当前线路相关信息。
- 右上角「保存为图片」可把当前页截图存入系统相册。
- 通过 `QiChatUISDK.openDeviceInfo(context)` 暴露，宿主自己决定从哪里进入。

## 数据来源

| 字段 | 来源 | 备注 |
|---|---|---|
| 会员账号 | `QiChatConfig.current.userName` | 空时 fallback `userId` |
| 手机型号 | `device_info_plus` | iOS 经 `_iosMarketingName` 映射成「iPhone 12 Pro Max」 |
| 应用名称 | `PackageInfo.appName` | |
| 手机系统版本 | `device_info_plus` | `iOS_<version>` / `Android_<release>` |
| APP当前版本 | `PackageInfo.version` + `buildNumber` + " (V3)" | V3 = SDK 大版本，硬编码 |
| 当前时间 | `DateTime.now()` | `Timer.periodic(1s)` 实时刷新 |
| 应用包名 | `PackageInfo.packageName` | |
| 登录IP | `—` | 占位，暂不接外部服务 |
| 当前线路 | `domain` 在 `detectUrls` split 后的下标 → `线路${i+1}` | 找不到下标则显示 `domain` 原值 |
| 线路等级 | `—` | 占位 |
| 线路扫描 | `—` | 占位；当前 SDK `LineDetectLib` 只在首条成功时停止，不给所有线路心跳耗时 |

截图中「应用包名」出现两次，判定为截图重复，不复刻。

## UI

```
Scaffold
├── AppBar(theme.gradientStartColor)
│   ├── leading: BackButton
│   ├── title: '设备信息'
│   └── actions: IconButton(Icons.save_alt) → 保存为图片
└── body: Container(gradient: theme.linearGradient)
    └── SafeArea + SingleChildScrollView
        └── RepaintBoundary(_cardKey)    ← 截图范围
            └── Card(白底, radius 16, margin 16)
                └── Column(_Row × 10, 中间 Divider)
```

`_Row`：
- 高 ≥ 56，padding 16/14。
- 左 label：深色，15sp。
- 右 value：浅灰 `#9AA0A6`，14sp，右对齐。
- multiLine（登录IP / 线路扫描）：value 占下一行整宽左对齐。

主题：AppBar 用 `gradientStartColor`/`tintColor`，背景用 `linearGradient`；卡片始终白底保证可读。

## 行为

- **加载态**：并发拉 `iosInfo`/`androidInfo` + `PackageInfo`，未完成的字段先显示 `—`。
- **实时时间**：`Timer.periodic(1s)` 只重建「当前时间」行；`dispose` 取消。
- **保存图片**：
  ```dart
  final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  await Gal.putImageBytes(bytes, name: 'device_info_<ts>');
  ```
  失败/无权限 → `Gal.requestAccess()` 兜底，再失败 toast 报错。
- **异常兜底**：每个 future 单独 try/catch，单字段失败显示 `—`，不让整页崩。

## 平台差异

- iOS：`utsname.machine` 内部代号映射为营销名，未命中 fallback 原值。
- Android：`androidInfo.model`，版本 `release`。
- 非移动端：整页字段全 `—`，不抛错。
- iOS 保存图片需要宿主 `Info.plist` 加 `NSPhotoLibraryAddUsageDescription`，在 `openDeviceInfo` dartdoc 里提示。

## 落地清单

1. `pubspec.yaml`：加 `device_info_plus`、`gal`。
2. 新建 `lib/src/vc/device_info_page.dart`：页面 + `_iosMarketingName`。
3. `lib/src/api/qichat_ui_sdk.dart`：加 `openDeviceInfo()` 静态方法。
4. `example/` 里 main 加按钮跳设备信息页（联调用）。

## YAGNI 已剔除

- 实时线路心跳扫描 / IP 地理定位：先用 `—` 占位，等后端 / SDK 改造后再接。
- 复制到剪贴板按钮：用户选了「保存为图片」，不重复加。
- 加载态 Shimmer 骨架：用 `—` 占位更简单。
