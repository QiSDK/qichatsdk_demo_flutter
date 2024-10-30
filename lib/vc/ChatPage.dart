

import 'dart:ffi';

import 'package:fixnum/src/int64.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'dart:math';
import 'package:qichatsdk_flutter/src/ChatLib.dart';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart' as cMessage;
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';

import '../Constant.dart';
import '../article_repository.dart';
import '../model/Custom.dart';


class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> implements TeneasySDKDelegate{
  final List<types.Message> _messages = [];
  final _user = types.User(id: 'user1'); // Local user ID
  final _user1 = types.User(id: 'user2'); // Local user ID
  var consultId = Int64(1);

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    initSDK();
  }

  void _loadInitialMessages() {

    // Load any initial messages if needed, or keep it empty for a new chat
    setState(() {
      _messages.addAll([
        types.TextMessage(
          author: _user,
          id: _generateRandomId(),
          text: 'Hello! How can I help you today?',
        ),
      ]);
    });
  }

  String _generateRandomId() {
    return Random().nextInt(1000000).toString();
  }

  void _handleSendPressed(types.PartialText message) {


    Constant.instance.chatLib.sendMessage("hello chat sdk!", cMessage.MessageFormat.MSG_TEXT, consultId);
    print("payloadid:${  Constant.instance.chatLib.payloadId }");
    var msg = types.ImageMessage(author: _user, uri: "https://www.bing.com/th?id=OHR.GreatOwl_ROW5336296654_1920x1200.jpg&rf=LaDigue_1920x1200.jpg", id: "${Constant.instance.chatLib.payloadId}", name: 'dd', size: 200, status: types.Status.sending, remoteId: '0');


    final textMessage = types.TextMessage(
      author: _user1,
      id: _generateRandomId(),
      text: message.text,
      status: types.Status.sending
    );


    
    setState(() {
      _messages.insert(0, textMessage);
      _messages.insert(0, msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        disableImageGallery: false,
        user: _user,
        theme: const DefaultChatTheme(
          inputBackgroundColor: Colors.lightBlue,
          primaryColor: Colors.blueAccent,
        ),
      ),
    );
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
        userId: userId,
        cert: cert,
        token: "",
        baseUrl: "wss://" + domain + "/v1/gateway/h5",
        sign: "9zgd9YUc",
        custom: getCustomParam("wang wu", 1, 0)
    );

    // Now the listener will receive the delegate events
    Constant.instance.chatLib.callWebSocket();
  }

  @override
  void receivedMsg(cMessage.Message msg) {
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

    getChatData();
  }

  @override
  void workChanged(SCWorkerChanged msg) {
    print("Worker Changed for Consult ID: ${msg.consultId}");
    _updateUI("客服更换成功，新worker id:${msg.workerId}");
    //客服更换之后，在这重新调用历史记录的接口，和更换客服头像、名字
  }

  @override
  void msgReceipt(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    _updateUI("收到回执 payloadId:${payloadId}");
    print("收到回执 payloadId:${payloadId} msgId: ${msg.msgId}");
    updateMessageStatus(payloadId.toString(), types.Status.sent);
  }

  @override
  void msgDeleted(cMessage.Message msg, Int64 payloadId, String? errMsg) {
      _updateUI("删除成功 msgId:${msg.msgId}");
      print("删除成功: ${msg.msgId} ");
  }

  _updateUI(String info){

  }

  void updateMessageStatus(String payloadId, types.Status newStatus) {
    // Find the message by its id
    var index = _messages.indexWhere((p) => p.id == payloadId);

    // Check if message exists
    if (index != -1) {
      setState(() {
        // Create a new message object with the updated status
        _messages[index] = _messages[index].copyWith(status: newStatus);
      });
    }
  }

  Future<void> getChatData() async {
    //var d = consultId.toInt();
    //聊天记录
    //var e = await ArticleRepository.queryHistory(consultId);
    var f = await ArticleRepository.queryAutoReply(consultId, workerId);
    print(f);
  }

}
