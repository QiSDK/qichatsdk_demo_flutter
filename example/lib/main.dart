import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logman/logman.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:qichat_ui_sdk/qichat_ui_sdk.dart';

import 'BWSettingViewController.dart';
import 'demo_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final cfg = await DemoConfig.load();

  await QiChatUISDK.init(
    cert: cfg.cert,
    userId: cfg.userId,
    userName: cfg.userName,
    merchantId: cfg.merchantId,
    detectUrls: cfg.detectUrls,
    baseUrlImage: cfg.baseUrlImage,
    maxSessionMinutes: cfg.maxSessionMinutes,
  );

  runApp(const MyApp());
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
      builder: FlutterSmartDialog.init(builder: (context, child) {
        return GestureDetector(
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: MediaQuery(
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
  String _lineStatus = "正在线路检测...";
  String _versionNo = "";
  int _unread = 0;
  final Logman _logman = Logman.instance;
  final AppChatTheme _theme = AppChatTheme.random();

  @override
  void initState() {
    super.initState();

    QiChatUISDK.lineStatusStream.listen((status) {
      if (mounted) setState(() => _lineStatus = status);
    });
    QiChatUISDK.totalUnreadStream.listen((count) {
      if (mounted) setState(() => _unread = count);
    });

    _loadVersion();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        _logman.attachOverlay(context: context);
      }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
                    child:
                        const Text('联系客服', style: TextStyle(fontSize: 15)),
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openSettings,
        backgroundColor: _theme.tintColor,
        foregroundColor: Colors.white,
        tooltip: '设置',
        child: const Icon(Icons.settings),
      ),
    );
  }

  Future<void> _contactCustomerService() async {
    final ok = await QiChatUISDK.openCustomerService(context, theme: _theme);
    if (!ok && mounted) {
      SmartDialog.showToast('线路未就绪，请稍后再试');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BWSettingViewController()),
    );
    // 设置页改完配置后重启 SDK
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
