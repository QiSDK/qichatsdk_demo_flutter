import 'package:flutter/material.dart';
import 'package:qichatsdk_demo_flutter/BWSettingViewController.dart';
import 'package:qichatsdk_demo_flutter/article_repository.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';

import 'package:fixnum/src/int64.dart';
import 'package:qichatsdk_flutter/src/ChatLib.dart';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart';
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';


import 'Constant.dart';
import 'model/Custom.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

class _MyHomePageState extends State<MyHomePage> implements LineDetectDelegate, TeneasySDKDelegate{
  String _textContent = "正在初始化。。。";

  @override
  void initState() {
    super.initState();
  }

  Future<void> getEntrance() async {
    //entrance数据
    //var d = await ArticleRepository.queryEntrance();

    //聊天记录
    //var e = await ArticleRepository.queryHistory();
    //print(d);
  }

  void initSDK(){
    if (Constant.instance.isConnected){
      return;
    }
    print("正在初始化sdk");
    // Assign the listener to the ChatLib delegate
    Constant.instance.chatLib.delegate = this;

    // Initialize the chat library with necessary parameters
    Constant.instance.chatLib.initialize(
        userId: 230,
        cert: "COYBEAUYASDyASiG2piD9zE.te46qua5ha2r-Caz03Vx2JXH5OLSRRV2GqdYcn9UslwibsxBSP98GhUKSGEI0Z84FRMkp16ZK8eS-y72QVE2AQ",
        token: "",
        baseUrl: "wss://csapi.hfxg.xyz/v1/gateway/h5",
        sign: "9zgd9YUc",
        custom: getCustomParam("wang wu", 1, 0)
    );

    // Now the listener will receive the delegate events
    Constant.instance.chatLib.callWebSocket();
  }

  @override
  void receivedMsg(Message msg) {
    print("Received Message: ${msg}");
    if (msg.image.uri.isNotEmpty){
      _updateUI("Received Message: ${msg.image.uri}");
    }else if(msg.video.uri.isNotEmpty){
      _updateUI("Received Message: ${msg.video.uri}");
    }else{
      _updateUI("Received Message: ${msg.content}");
    }
  }

  @override
  void systemMsg(Result result) {
    print("System Message: ${result.message}");
    Constant.instance.isConnected = false;
    _updateUI("已断开：${result.code} ${result.message})");
    if (result.code == 1002 || result.code == 1010) {
      if (result.code == 1002){
        //showTip("无效的Token")
        //有时候服务器反馈的这个消息不准，可忽略它
      }else {
        //showTip("在别处登录了")
        //toast("在别处登录了")
        //在此处退出聊天
      }
    }
  }

  @override
  void connected(SCHi c) {
    print("Connected with token: ${c.token}");
    Constant.instance.isConnected = true;
    _updateUI("连接成功！");
  }

  @override
  void workChanged(SCWorkerChanged msg) {
    print("Worker Changed for Consult ID: ${msg.consultId}");
    _updateUI("客服更换成功，新worker id:${msg.workerId}");
    //客服更换之后，在这重新调用历史记录的接口，和更换客服头像、名字
  }

  @override
  void msgDeleted(Message msg, Int64 payloadId, String? errMsg) {
    _updateUI("删除成功 msgId:${msg.msgId}");
    print("删除成功: ${msg.msgId} ");
  }

  @override
  void msgReceipt(Message msg, Int64 payloadId, String? errMsg) {
    _updateUI("收到回执 payloadId:${payloadId}");
    print("收到回执 payloadId:${payloadId} msgId: ${msg.msgId}");
  }

  void _updateUI(String content){
    setState(() {
      _textContent = "${content} \n" ;
    });
  }

  void _incrementCounter() {
    setState(() {
      var consultId = Int64(1);
      Constant.instance.chatLib.sendMessage("hello chat sdk!", MessageFormat.MSG_TEXT, consultId);

      Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => BWSettingViewController())
      );
      //回复消息
      //Constant.instance.chatLib.sendMessage("hello chat sdk!", MessageFormat.MSG_TEXT, consultId, replyMsgId: 12344555555555544433);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Constant.instance.isConnected){
      print("开始线路检测");
      var lineDetect = LineDetectLib("https://xxxcsapi.hfxg.xyz,https://csapi.hfxg.xyz,https://csapi.hfxg.xyz000", tenantId: 230);
      lineDetect.getLine();
      lineDetect.delegate = this;
    }
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
            const Text(
              '消息演示:',
            ),
            Text(
              '$_textContent',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
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
    if (error.code == 1008){
      //无可用线路
    }
    print(error.message);
  }

  @override
  void useTheLine(String line) {
    initSDK();
    domain = line;
    getEntrance();
  }

}
