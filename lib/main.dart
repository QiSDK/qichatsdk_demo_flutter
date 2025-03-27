import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qichatsdk_demo_flutter/util/util.dart';
import 'package:qichatsdk_demo_flutter/vc/BWSettingViewController.dart';
import 'package:qichatsdk_demo_flutter/vc/entrancePage.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'Constant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 WebView 平台
  if (Platform.isIOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  } else if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();

    // 对于 macOS，我们可能需要使用不同的实现或者禁用 WebView
    debugPrint('WebView may not be fully supported on macOS');
  } else {
    debugPrint('WebView is not supported on this platform');
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Must add this line.
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(900, 675),
      center: true,
      fullScreen: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  lines = prefs.getString(PARAM_LINES) ?? lines;
  cert = prefs.getString('PARAM_CERT') ?? cert;
  merchantId = (prefs.getInt('PARAM_MERCHANT_ID') ?? merchantId);
  userId = (prefs.getInt('PARAM_USER_ID') ?? userId);
  userName = prefs.getString('PARAM_USERNAME') ?? userName;
  baseUrlImage = prefs.getString('PARAM_ImageBaseURL') ?? baseUrlImage;
  maxSessionMins = (prefs.getInt('PARAM_MAXSESSIONMINS') ?? maxSessionMins);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(size: 15), // Set global icon size for AppBar
        ),
      ),
      builder: FlutterSmartDialog.init(builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
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
      home: const MyHomePage(title: 'Qi Chat Demo App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver
    implements LineDetectDelegate {
  String _textContent = "正在线路检测。。。";
  String _verionNo = "";
  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
    loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // This is similar to `onResume`
      print("App has resumed");
      // Perform the actions you want when the page is resumed
      //loadData();
    }
  }

  Future<void> loadData() async {
    //if (domain.isEmpty) {
    print("开始线路检测");
    var lineDetect = LineDetectLib(lines, tenantId: merchantId);
    lineDetect.getLine();
    lineDetect.delegate = this;
    //}

    _verionNo = await Util().getAppVersion();
  }

  void _updateUI(String content) {
    setState(() {
      _textContent = "${content} \n";
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    if (domain.isEmpty) {
                      SmartDialog.showToast("无可用线路");
                      return;
                    }
                    _navigateToPageB();
                  },
                  child: const Text('联系客服', style: TextStyle(fontSize: 15))),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '$_textContent',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '版本号：$_verionNo',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSettings,
        tooltip: '设置',
        child: const Icon(Icons.settings),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _navigateToPageB() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntrancePage()),
    );

    // Call loadData when returning from Page B
    loadData();
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BWSettingViewController()),
    );

    // Call loadData when returning from Page B
    loadData();
  }

  @override
  void lineError(Result error) {
    if (error.code == 1008) {
      //无可用线路
      _updateUI("无可用线路");
      print("无可用线路");
    }
    //print(error.message);
  }

  @override
  void useTheLine(String line) {
    domain = line;
    _updateUI("当前线路：${domain}");
    //initSDK();
    //getEntrance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
}
