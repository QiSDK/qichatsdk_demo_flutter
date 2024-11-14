import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qichatsdk_demo_flutter/vc/BWSettingViewController.dart';
import 'package:qichatsdk_demo_flutter/article_repository.dart';
import 'package:qichatsdk_demo_flutter/vc/entrancePage.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:fixnum/src/int64.dart';
import 'package:qichatsdk_flutter/src/ChatLib.dart';
import 'package:window_manager/window_manager.dart';
import 'Constant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {

    // Must add this line.
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

  }
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

class _MyHomePageState extends State<MyHomePage> implements LineDetectDelegate {
  String _textContent = "正在线路检测。。。";

  @override
  void initState() {
    super.initState();

    if (domain.isEmpty) {
      print("开始线路检测");
      var lineDetect = LineDetectLib(
          "https://xxxcsapi.hfxg.xyz,https://csapi.hfxg.xyz,https://csapi.hfxg.xyz000",
          tenantId: 230);
      lineDetect.getLine();
      lineDetect.delegate = this;
    }
  }

  void _updateUI(String content) {
    setState(() {
      _textContent = "${content} \n";
    });
  }

  void _incrementCounter() {
    setState(() {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => BWSettingViewController()));
      //回复消息
      //Constant.instance.chatLib.sendMessage("hello chat sdk!", MessageFormat.MSG_TEXT, consultId, replyMsgId: 12344555555555544433);
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
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    if(domain.isEmpty){
                      SmartDialog.showToast("无可用线路");
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EntrancePage()));
                  },
                  child: const Text('联系客服', style: TextStyle(fontSize: 15))),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '$_textContent',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: '设置',
        child: const Icon(Icons.settings),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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
}
