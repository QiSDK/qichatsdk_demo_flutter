import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

// 客服 UISDK 的唯一入口：宿主只需要用 QiChatUISDK 这一个门面类
import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';
// demo 专用：直接读 SDK 内部存 xToken 的 key，用于拼「备用客服」的跳转参数
import 'package:qichat_ui_sdk/src/Constant.dart' show PARAM_XTOKEN;

import 'BWSettingViewController.dart';
import 'demo_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面端（Windows / Linux / macOS）先把窗口尺寸固定成手机比例，方便调试
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(900, 675),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // demo 专用：从 SharedPreferences 加载设置页填的配置
  // 真实接入时，这些值一般来自宿主 App 的登录态 / 后台下发，不需要设置页
  final cfg = await DemoConfig.load();

  // 【关键】初始化 UISDK：内部会做线路检测、建立 WebSocket、恢复会话
  // 必须在 runApp 之前或进入聊天页之前调用一次
  await QiChatUISDK.init(
    cert: cfg.cert, // 商户证书，后台分配
    userId: cfg.userId, // 宿主侧用户唯一 ID
    userName: cfg.userName, // 展示用昵称
    merchantId: cfg.merchantId, // 商户 ID
    detectUrls: cfg.detectUrls, // 线路检测地址列表，SDK 会挑最快的一条用
    baseUrlImage: cfg.baseUrlImage, // 图片 / 文件上传下载的域名
    maxSessionMinutes: cfg.maxSessionMinutes, // 会话最长保留时间，超时后重新开会话
  );

  // demo：模拟「宿主调自己接口拿到 service_keyword 配置后喂进 SDK」。
  // 真实接入时，这里换成宿主自己的 HTTP 请求结果。
  await _loadAutoCardKeywords();

  // demo：宿主接管「卡片跳转」。用户点带 jumpUrl 的卡片按钮时回调到这里。
  // 真实接入时，这里换成打开你自己的小程序容器 / 原生页 / WebView。
  // 不注册的话，SDK 会用内置模拟页兜底。
  QiChatUISDK.setCardJumpHandler(_handleCardJump);

  runApp(const MyApp());
}

/// demo：宿主侧模拟「打开小程序页面」。
///
/// - [context] 由 SDK 传入，是聊天页所在的 context，可以直接用来 push 路由
/// - [jumpUrl] 卡片按钮上配的跳转地址
/// - [jumpCategory] 跳转类型，宿主可据此决定用小程序 / 原生页 / WebView 打开
void _handleCardJump(BuildContext context, String jumpUrl, int? jumpCategory) {
  SmartDialog.showToast('宿主接管：模拟打开小程序 $jumpUrl');
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _MiniProgramDemoPage(jumpUrl: jumpUrl, jumpCategory: jumpCategory),
    ),
  );
}

/// demo：模拟的小程序页面。真实接入时替换成宿主自己的页面 / 容器。
class _MiniProgramDemoPage extends StatelessWidget {
  final String jumpUrl;
  final int? jumpCategory;

  const _MiniProgramDemoPage({required this.jumpUrl, this.jumpCategory});

  @override
  Widget build(BuildContext context) {
    final title = jumpUrl.split('/').where((s) => s.isNotEmpty).lastOrNull ??
        jumpUrl;
    return Scaffold(
      appBar: AppBar(title: Text('小程序模拟页 · $title')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_new, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text('宿主已接管跳转',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SelectableText(jumpUrl,
                  style: const TextStyle(
                      fontFamily: 'monospace', color: Colors.black87)),
              if (jumpCategory != null) ...[
                const SizedBox(height: 8),
                Text('jumpCategory：$jumpCategory',
                    style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('返回聊天'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 从内置示例 JSON 读取 `result[0].service_keyword` 并设置到 UISDK。
///
/// 关键词卡片的作用：用户发的消息命中某个关键词时，SDK 自动回一张引导卡片。
/// 真实接入时把 rootBundle 换成宿主自己的接口响应即可，数据结构保持一致。
Future<void> _loadAutoCardKeywords() async {
  try {
    // 示例数据放在 SDK 包的 assets 里，所以路径要带 packages/<包名>/ 前缀
    final raw = await rootBundle.loadString(
        'packages/qichat_ui_sdk/assets/json/mst_card_msg_match_list.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final result = data['result'] as List?;
    if (result == null || result.isEmpty) return;
    final list = (result.first['service_keyword'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    // 【关键】喂给 SDK；不调用则关键词卡片功能不生效
    QiChatUISDK.setAutoCardKeywords(list);
  } catch (e) {
    // 卡片配置属于增强功能，加载失败只打日志，不影响聊天主流程
    debugPrint('加载自动卡片关键词失败: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QiChat UISDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(size: 15),
        ),
      ),
      // 【关键】SDK 内部用 SmartDialog 弹 toast / 弹窗，宿主必须在这里初始化它
      builder: FlutterSmartDialog.init(builder: (context, child) {
        return GestureDetector(
          // 点击空白处收起键盘（聊天页输入框体验需要）
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: MediaQuery(
            // 锁定字体缩放为 1.0，避免系统「超大字体」把聊天气泡布局撑破
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          ),
        );
      }),
      home: const MyHomePage(title: 'QiChat UISDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //String _lineStatus = "正在线路检测...";
  String _lineStatus = ""; // 线路检测状态文案，由 SDK 的 stream 推过来
  String _versionNo = ""; // demo App 版本号
  int _unread = 0; // 客服消息总未读数，用于「联系客服」按钮上的红点

  // demo：当前选中的内置主题，由顶部主题条切换，默认第 0 套
  // 真实接入时不需要这个选择器：挑定一套 presets[n] 写死，
  // 或者按自家品牌色 new 一个 AppChatTheme 传给 openCustomerService 即可
  int _themeIndex = 0;
  AppChatTheme _theme = AppChatTheme.presets.isEmpty
      ? AppChatTheme.defaultTheme
      : AppChatTheme.presets.first;

  @override
  void initState() {
    super.initState();

    print("main 线路检测");
    // 【关键】监听线路检测状态：宿主可用它决定入口按钮是否可点、展示什么提示
    QiChatUISDK.lineStatusStream.listen((status) {
      print('[Main] lineStatusStream: $status');
      if (mounted) setState(() => _lineStatus = status);
    });
    // 【关键】监听总未读数：即使没进聊天页，收到客服消息也会推过来，用于角标红点
    QiChatUISDK.totalUnreadStream.listen((count) {
      if (mounted) setState(() => _unread = count);
    });

    _loadVersion();

    // demo：显示网络日志悬浮按钮，点开可查看 SDK 的 HTTP 请求（对齐 Android/iOS demo）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) QiChatUISDK.showNetworkLogButton(context);
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _versionNo = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _theme.gradientStartColor,
        foregroundColor: _theme.tintColor,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _theme.linearGradient),
        child: Column(
          children: [
            // demo：主题选择条。真实接入时删掉，主题写死即可
            _ThemeSwatchStrip(
              selectedIndex: _themeIndex,
              onSelected: (index) => setState(() {
                _themeIndex = index;
                _theme = AppChatTheme.presets[index];
              }),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 客服入口按钮 + 右上角未读红点
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme.tintColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _contactCustomerService,
                          child: const Text('联系客服',
                              style: TextStyle(fontSize: 15)),
                        ),
                        // 未读数由 totalUnreadStream 驱动，超过 99 显示 99+
                        if (_unread > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _unread > 99 ? '99+' : '$_unread',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _theme.tintColor,
                        side: BorderSide(color: _theme.tintColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: _openBackupCustomerService,
                      child: const Text('备用客服',
                          style: TextStyle(fontSize: 15)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_lineStatus,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: _theme.leftBubbleTextColor)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('版本号：$_versionNo',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: _theme.leftBubbleTextColor)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSettings,
        backgroundColor: _theme.tintColor,
        foregroundColor: Colors.white,
        tooltip: '设置',
        child: const Icon(Icons.settings),
      ),
    );
  }

  /// 【关键】打开客服聊天页。SDK 内部负责建连、拉历史、渲染整个聊天界面。
  /// 返回 false 说明线路还没就绪（init 没完成 / 检测全部失败），此时不会跳页。
  Future<void> _contactCustomerService() async {
    final ok = await QiChatUISDK.openCustomerService(context, theme: _theme);
    if (!ok && mounted) {
      SmartDialog.showToast('线路未就绪，请稍后再试');
    }
  }

  // 带参数打开客服中心 App，如果App没有安装，打开一个网址链接
  Future<void> _openBackupCustomerService() async {
    final cfg = await DemoConfig.load();
    final prefs = await SharedPreferences.getInstance();
    // xToken 是 SDK 登录成功后缓存的凭证，带过去可以让客服中心 App 免登录
    final xToken = prefs.getString(PARAM_XTOKEN) ?? '';

    // _themeIndex 对应 AppChatTheme.presets 的下标，顺序与 iOS ChatTheme.presets 一致：
    // 0-晨雾白, 1-暗夜神殿, 2-蜜桃粉, 3-抹茶绿, 4-日落橙,
    // 5-星空靛, 6-暗夜紫, 7-极简灰, 8-幻夜紫, 9-晴空蓝, 10-薄暮紫
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

    // 独立「客服中心 App」注册的 URL Scheme，参数通过 query 传过去
    final deepLink = Uri(
      scheme: 'juhekefu',
      host: 'open',
      queryParameters: params,
    );

    // 先试 deep link 唤起 App；抛异常或返回 false 都视为「没装」
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

    // 保留备用网址自带的 query，再把同一套参数拼上去
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

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BWSettingViewController()),
    );
    // 设置页改完配置后重启 SDK
    // 【关键】改 cert / userId / 域名这类连接参数，必须先 dispose 断开旧连接再 init，
    // 否则旧的 WebSocket 和缓存会话会继续存在，导致消息串号
    final cfg = await DemoConfig.load();
    await QiChatUISDK.dispose();
    await QiChatUISDK.init(
      cert: cfg.cert,
      userId: cfg.userId,
      userName: cfg.userName,
      merchantId: cfg.merchantId,
      detectUrls: cfg.detectUrls,
      baseUrlImage: cfg.baseUrlImage,
      maxSessionMinutes: cfg.maxSessionMinutes,
    );
  }
}

/// demo 专用：顶部横向滚动的主题选择条。
///
/// 样式与 iOS demo 的 themeScrollView 严格对齐（见 QLUISDK_Demo_iOS 的
/// ViewController.swift）：60×60 圆形色块填 `gradientEndColor` 纯色，
/// 选中态 3px 白描边 + 放大 1.15 倍，未选中不描边。
///
/// 真实接入时把这个控件连同调用处一起删掉，直接写死一套主题即可。
class _ThemeSwatchStrip extends StatelessWidget {
  /// 当前选中的主题在 [AppChatTheme.presets] 中的下标
  final int selectedIndex;

  /// 点击色块回调，参数为新选中的下标
  final ValueChanged<int> onSelected;

  const _ThemeSwatchStrip({
    required this.selectedIndex,
    required this.onSelected,
  });

  // 尺寸对齐 iOS：色块 60，容器 70 + stack 间距 15 → 单位间距 85
  static const double _size = 60; // 色块直径
  static const double _slot = 85; // 单个色块占位宽度（含选中放大后的余量）
  static const double _rowHeight = 84; // 行高，留出放大 1.15 倍的空间

  @override
  Widget build(BuildContext context) {
    final presets = AppChatTheme.presets;
    if (presets.isEmpty) return const SizedBox.shrink();

    final current = presets[selectedIndex];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Text(
              '聊天主题（${selectedIndex + 1}/${presets.length}）',
              // 标题颜色跟着当前主题走，深色主题下才不会看不见
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: current.leftBubbleTextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            height: _rowHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final theme = presets[index];
                final selected = index == selectedIndex;
                return SizedBox(
                  width: _slot,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onSelected(index),
                      // 选中的放大 1.15 倍，与 iOS 的 spring 动画观感一致
                      child: AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _size,
                          height: _size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // 对齐 iOS：纯 gradientEndColor 填充，不画渐变、不加圆点
                            color: theme.gradientEndColor,
                            // 对齐 iOS：只有选中态描边，未选中不描边
                            border: selected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
