import 'dart:async';
import 'dart:ffi';

import 'package:fixnum/src/int64.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:qichatsdk_demo_flutter/model/MyMsg.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart';
import 'package:qichatsdk_demo_flutter/model/Worker.dart';
import 'package:qichatsdk_demo_flutter/store/chat_store.dart';
import 'package:qichatsdk_demo_flutter/vc/custom_bottom.dart';
import 'package:qichatsdk_demo_flutter/vc/message_cell.dart';
import 'package:qichatsdk_demo_flutter/vc/video_cell.dart';
import 'dart:math';
import 'package:qichatsdk_flutter/src/ChatLib.dart';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart'
    as cMessage;
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../Constant.dart';
import '../article_repository.dart';
import '../model/Custom.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../util/util.dart';
import 'package:scroll_to_index/scroll_to_index.dart';


class ChatPage extends StatefulWidget {
  Int64 consultId = Int64.ZERO;

  ChatPage({super.key, required this.consultId});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    implements TeneasySDKDelegate, MessageItemOperateListener {
  final List<types.Message> _messages = [];
  var _me = const types.User(
    id: 'user',
  );
  final _client = const types.User(
    firstName: 'client',
    id: 'client',
  );
  GlobalKey _sendViewKey = GlobalKey();
  var consultId = Int64(1);
  List<MsgItem>? replyList;
   bool _isFirstLoad = true;
   var store = ChatStore();
  Timer? _timer;
  int _timerCount = 0;
  AutoScrollController _scrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();
    consultId = widget.consultId;
    // _loadInitialMessages();
    initSDK();
    startTimer();
    Connectivity().onConnectivityChanged.listen((onData) {
      if (onData is List<ConnectivityResult>) {
        if ((onData as List<ConnectivityResult>).first ==
            ConnectivityResult.none) {
          print("请检查网络${DateTime.now()}");
          Constant.instance.isConnected = false;
          //把未发送的消息保存起来
          _getUnsentMessage();
        }
      }});
  }

  String _generateRandomId() {
    return Random().nextInt(1000000).toString();
  }

  void _handleSendPressed(types.PartialText message) {
    if (_me.id == "user"){
      SmartDialog.showToast("此时不能发消息，请检查网络或稍等片刻");
      return;
    }
    var replyId = (_sendViewKey.currentState as ChatCustomBottomState).replyId;
    Constant.instance.chatLib.sendMessage(
        message.text, cMessage.MessageFormat.MSG_TEXT, consultId,
        replyMsgId: replyId, withAutoReply: withAutoReplyBuilder);
    withAutoReplyBuilder = null;
    debugPrint("replyId:$replyId");

    // sending是转圈的状态
    final textMessage = types.TextMessage(
        author: _me,
        id: "${Constant.instance.chatLib.payloadId}",
        text: message.text,
        metadata: {
          'msgTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'replyText': _getReplyText(replyId.toString(), true)
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: types.Status.sending);

    setState(() {
      _messages.insert(0, textMessage);
      //_messages.insert(0, imgMsg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(store.loadingMsg),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        disableImageGallery: false,
        scrollController: _scrollController,
        user: _me,
        // customMessageBuilder: (message, {messageWidth = 200}) {
        //   return TipMessage(message: message);
        // },
        showUserAvatars: false,
        showUserNames: true,
        theme: const DefaultChatTheme(
            inputBackgroundColor: Colors.lightBlue,
            primaryColor: Colors.blueAccent,
            inputTextColor: Colors.black),
        textMessageBuilder: (message, {int? messageWidth, bool? showName}) {
          return TextMessageWidget(
            message: message,
            chatId: _me.id,
            listener: this,
            messageWidth: messageWidth ?? 0,
          );
        },
        videoMessageBuilder: (message, {int? messageWidth}) {
          return VideoMessageWidget(
            message: message,
          );
        },
        avatarBuilder: (types.User user) {
          return customAvatarBuilder(user.id);
        },
        // customDateHeaderText: (DateTime? date) {
        //   if (date != null) {
        //     return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
        //   }
        //   return '';
        // },
        customBottomWidget: ChatCustomBottom(
          key: _sendViewKey,
          onSubmitted: (value) {
            final trimmedText = value.trim();
            if (trimmedText.isEmpty) {
              SmartDialog.showToast("消息不能为空");
              return;
            }
            final partialText = types.PartialText(text: trimmedText);
            _handleSendPressed(partialText);
          },
          onUploadSuccess: (String url, bool isVideo) {
            if (isVideo) {
              debugPrint('视频URL:$url');
              Constant.instance.chatLib.sendMessage(
                  url, cMessage.MessageFormat.MSG_VIDEO, consultId,
                  withAutoReply: withAutoReplyBuilder);
              var msg = types.VideoMessage(
                  author: _me,
                  uri: url,
                  metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
                  createdAt: DateTime.now().microsecondsSinceEpoch,
                  id: "${Constant.instance.chatLib.payloadId}",
                  name: 'dd',
                  size: 200,
                  status: types.Status.sending,
                  remoteId: '0');
              setState(() {
                _messages.insert(0, msg);
              });
            } else {
              Constant.instance.chatLib.sendMessage(
                  url, cMessage.MessageFormat.MSG_IMG, consultId,
                  withAutoReply: withAutoReplyBuilder);
              var msg = types.ImageMessage(
                  author: _me,
                  uri: url,
                  metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
                  createdAt: DateTime.now().microsecondsSinceEpoch,
                  id: "${Constant.instance.chatLib.payloadId}",
                  name: 'dd',
                  size: 200,
                  status: types.Status.sent,
                  remoteId: '0');
              setState(() {
                _messages.insert(0, msg);
              });
            }
          },
        ),
      ),
    );
  }

  Widget customAvatarBuilder(String userId) {
    return Container(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: const Icon(Icons.av_timer_sharp),
      ),
    );
  }

  void initSDK() {
    if (Constant.instance.isConnected) {
      return;
    }
    print("正在初始化sdk${DateTime.now()}");
    // Assign the listener to the ChatLib delegate
    Constant.instance.chatLib.delegate = this;

    // Initialize the chat library with necessary parameters
    Constant.instance.chatLib.initialize(
        userId: userId,
        cert: cert,
        token: "",
        baseUrl: "wss://" + domain + "/v1/gateway/h5",
        sign: "9zgd9YUc",
        custom: getCustomParam(userName, 1, 0));

    // Now the listener will receive the delegate events
    Constant.instance.chatLib.callWebSocket();
  }

  @override
  void receivedMsg(cMessage.Message msg) {
    if (msg.msgOp == cMessage.MessageOperate.MSG_OP_EDIT) {
      var index =
          _messages.indexWhere((p) => p.remoteId == msg.msgId.toString());
      if (index >= 0) {
        _messages.removeAt(index);
        _messages.insert(
            index,
            types.TextMessage(
                author: types.User(id: msg.sender.toString()),
                text: msg.content.data,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                metadata: {'msgTime': msg.msgTime},
                id: _generateRandomId(),
                status: types.Status.sent,
                remoteId: msg.msgId.toString()));
      }
    } else {
      MyMsg model = MyMsg();
      model.imgUri = msg.image.uri;
      model.videoUri = msg.video.uri;
      model.text = msg.content.data;
      model.senderId = msg.sender.toString();
      model.msgId = msg.msgId.toString();
      model.msgTime = msg.msgTime.toDateTime();
      model.replyMsgId = msg.replyMsgId.toString();
      composeLocalMsg(model, insert: true);
      print("Received Message: ${msg}");
    }
    _updateUI("info");
  }

  @override
  void systemMsg(Result result) {
    print("System Message: ${result.message}");
    Constant.instance.isConnected = false;
    print("已经断开");
    if (result.code == 1002 || result.code == 1010 || result.code == 1005) {
      if (result.code == 1002) {
        //showTip("无效的Token")
        //有时候服务器反馈的这个消息不准，可忽略它
      } else if (result.code == 1005) {//会话超时，返回到之前页面
        Navigator.pop(context);
      } else {
        //showTip("在别处登录了")
        //toast("在别处登录了")
        //在此处退出聊天
      }
    }else{
      _getUnsentMessage();
    }
  }

  @override
  void connected(SCHi c) {
    print("Connected with token: ${c.token}");
    xToken = c.token;
    Constant.instance.isConnected = true;
    _updateUI("连接成功！");
    //c.workerId;
     ArticleRepository.assignWorker(consultId).then((onValue){
       if (onValue != null) {
         getChatData(onValue.nick ?? "_");
         store.loadingMsg = onValue?.nick ?? "..";
       }else{
         store.loadingMsg = "分配客服失败";
         SmartDialog.showToast("分配客服失败");
       }
     });
  }

  @override
  void workChanged(SCWorkerChanged msg) {
    print("Worker Changed for Consult ID: ${msg.consultId}");
    _updateUI("客服更换成功，新worker id:${msg.workerId}");
    //客服更换之后，在这重新调用历史记录的接口，和更换客服头像、名字
    if (workerId > 0 && workerId != msg.workerId) {
      getChatData(msg.workerName);

      _messages.insert(
          0,
          types.TextMessage(
            author: _client,
            metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
            createdAt: DateTime
                .now()
                .millisecondsSinceEpoch,
            text: "您好，${msg.workerName}为您服务！",
            // 根据这个字段来自定义界面
            id: _generateRandomId(),
            status: types.Status.sent,
          ));
     }
  }

  @override
  void msgReceipt(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    _updateUI("收到回执 payloadId:${payloadId}");
    print("收到回执 payloadId:${payloadId} msgId: ${msg.msgId}");
    updateMessageStatus(
        payloadId.toString(), types.Status.sent, msg.msgId.toString());
  }

  @override
  void msgDeleted(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    var index = _messages.indexWhere((p) => p.remoteId == msg.msgId.toString());
    if (index >= 0) {
      _messages.removeAt(index);

      MyMsg model = MyMsg();
      model.imgUri = msg.image.uri;
      model.videoUri = msg.video.uri;
      model.text = '对方撤回了1条消息';
      model.senderId = msg.sender.toString();
      model.msgId = msg.msgId.toString();
      model.msgTime = msg.msgTime.toDateTime();
      composeLocalMsg(model, insert: true);
      _updateUI("删除成功 msgId:${msg.msgId}");
      print("删除成功: ${msg.msgId} ");
    } else {
      print("删除失败");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      //_scrollController?.scrollToIndex(_messages.length);
    });
  }

  _updateUI(String info) {
    setState(() {});
    _scrollToBottom();
  }

  void updateMessageStatus(
      String payloadId, types.Status newStatus, String msgId) {
    // Find the message by its id
    var index = _messages.indexWhere((p) => p.id == payloadId);
    // Check if message exists
    if (index != -1) {
      setState(() {
        // Create a new message object with the updated status
        _messages[index] =
            _messages[index].copyWith(status: newStatus, remoteId: msgId);
      });
    }
  }

  Future<void> getChatData(String workerName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(PARAM_XTOKEN, xToken);
    _messages.clear();
    //聊天记录
    var h = await ArticleRepository.queryHistory(consultId);
    _me = types.User(id: h?.request?.chatId ?? "");

    replyList = h?.replyList;
    _buildHistory(h?.list);

    if (_isFirstLoad) {
      _isFirstLoad = false;
      //自动回复
      AutoReply? model =
      await ArticleRepository.queryAutoReply(consultId, workerId);
      print(model?.autoReplyItem?.qa);
      print(model?.autoReplyItem?.title);
      if (model != null) {
        _messages.insert(
            0,
            types.TextMessage(
              metadata: model.toJson(),
              author: _client,
              createdAt: DateTime
                  .now()
                  .millisecondsSinceEpoch,
              text: 'autoReplay',
              // 根据这个字段来自定义界面
              id: _generateRandomId(),
              status: types.Status.sent,
            ));
      }

      setState(() {
        _messages.insert(
            0,
            types.TextMessage(
              author: _client,
              metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
              createdAt: DateTime
                  .now()
                  .millisecondsSinceEpoch,
              text: "您好，${workerName}为您服务！",
              // 根据这个字段来自定义界面
              id: _generateRandomId(),
              status: types.Status.sent,
            ));
      });
    }
    //处理在无网、或断网情况下未发出去的消息
    _handleUnSent();
  }

  @override
  void dispose() {
    print("chat page disposed");
    Constant.instance.chatLib.disconnect();
    Constant.instance.isConnected = false;
    _timer?.cancel();
    _timer = null;
    _getUnsentMessage();
    super.dispose();
  }

  _buildHistory(List<MsgItem>? msgItems) {
    if (msgItems == null) {
      return;
    }
    for (var msg in msgItems) {
      MyMsg model = MyMsg();
      model.imgUri = msg.image?.uri ?? '';
      model.videoUri = msg.video?.uri ?? '';
      model.text = msg.content?.data ?? '';
      model.senderId = msg.sender;
      model.msgId = msg.msgId;
      model.msgTime = Util.parseStringToDateTime(msg.msgTime);
      model.replyMsgId = msg.replyMsgId;
      composeLocalMsg(model);
      // composeLocalMsg(msg.image?.uri ?? "", msg.video?.uri ?? "", msg.content?.data ?? "", msg.sender.toString(), msg.msgId.toString());
    }
    if (mounted) {
      setState(() {});
    }
    ArticleRepository.markRead(consultId);
  }

  _getUnsentMessage(){
    if (_messages.isEmpty){
      return;
    }
    //把未发送的消息保存起来
    //if (unSentMessage == null || unSentMessage?.length == 0) {
      unSentMessage[consultId] =
          _messages.takeWhile((p) => p.status == types.Status.sending).toList();
    //}
    print("获取到未发送的消息总数${unSentMessage?.length}");
  }

  _handleUnSent(){
    print("处理未发送的消息 ${unSentMessage?.length}");
    if (Constant.instance.isConnected && unSentMessage[consultId] != null && unSentMessage[consultId]!.length > 0){
      print("重发消息总数${unSentMessage?.length}");
      _messages.insertAll(0, unSentMessage[consultId]!);
      _updateUI("info");
      for (var msg in unSentMessage[consultId]!!) {
        print("重发消息${msg}");
        if (msg is types.TextMessage) {
          print("重发消息${ (msg as types.TextMessage).text}");
         Constant.instance.chatLib.resendMSg(msg.text, consultId, Int64(int.parse(msg.id)));
        }
      }
      unSentMessage[consultId]!.clear();
    }
  }

  void composeLocalMsg(MyMsg msgModel, {bool insert = false}) {
    String imgUri = msgModel.imgUri ?? '';
    String videoUri = msgModel.videoUri ?? '';
    String text = msgModel.text ?? '';
    String senderId = msgModel.senderId ?? '';
    String msgId = msgModel.msgId ?? '';
    String? msgTime;
    int? milliSeconds;
    if (msgModel.msgTime != null) {
      msgTime = Util.convertDateToString(msgModel.msgTime);
      milliSeconds = msgModel.msgTime!.millisecondsSinceEpoch;
    }

    var replyText = _getReplyText(msgModel.replyMsgId ?? "", insert);
    final sender = types.User(id: senderId);
    types.Message msg;
    if (imgUri.isNotEmpty) {
      var imgUrl = imgUri;
      if (!imgUri.contains("http")) {
        imgUrl = baseUrlImage + imgUri;
      }
      msg = types.ImageMessage(
          author: sender,
          createdAt: milliSeconds,
          uri: imgUrl,
          id: _generateRandomId(),
          name: 'dd',
          size: 150,
          metadata: {'msgTime': msgTime},
          status: types.Status.sent,
          remoteId: msgId);
    } else if (videoUri.isNotEmpty) {
      var url = videoUri;
      if (!videoUri.contains("http")) {
        url = baseUrlImage + videoUri;
      }
      msg = types.VideoMessage(
          author: sender,
          uri: url,
          createdAt: milliSeconds,
          id: _generateRandomId(),
          name: 'dd',
          size: 150,
          metadata: {'msgTime': msgTime},
          status: types.Status.sent,
          remoteId: msgId);
    } else {
      msg = types.TextMessage(
          author: sender,
          text: text,
          createdAt: milliSeconds,
          metadata: {'msgTime': msgTime, 'replyText': replyText},
          id: _generateRandomId(),
          status: types.Status.sent,
          remoteId: msgId);
    }

    insert ? _messages.insert(0, msg) : _messages.add(msg);
  }

  String _getReplyText(String replyMsgId, bool append) {
    if (replyMsgId.isEmpty) {
      return "";
    }
    String replyTxt = "";
    types.Message? replyModel;
    var index = -1;
    if (append) {
      index = _messages.indexWhere((item) => item.remoteId == replyMsgId);
      if (index >= 0) {
        replyModel = _messages[index];
        if (replyModel is types.TextMessage) {
          replyTxt = (replyModel as types.TextMessage).text;
        } else if (replyModel is types.ImageMessage) {
          replyTxt = "[图片]";
        } else if (replyModel is types.VideoMessage) {
          replyTxt = "[视频]";
        }
        debugPrint("replyModel:${replyModel.toJson()}");
      }
    } else {
      //历史记录
      if (replyList != null) {
        index = replyList!.indexWhere((p) => p.msgId == replyMsgId);

        if (index >= 0) {
          var msg = replyList![index];
          if ((msg.image?.uri ?? "").isNotEmpty) {
            replyTxt = "[图片]";
          } else if ((msg.video?.uri ?? "").isNotEmpty) {
            replyTxt = "[视频]";
          } else {
            replyTxt = msg.content?.data ?? "";
          }
        }
      }
    }
    return replyTxt;
  }

  void handleUnSent(){

  }

  @override
  void onCopy(int position) {}

  @override
  void onDelete(int position) {}

  @override
  void onPlayImage(String url) {}

  @override
  void onPlayVideo(String url) {
    // TODO: implement onPlayVideo
  }

  @override
  void onQuote(int position) {
    // TODO: implement onQuote
  }

  @override
  void onReSend(int position) {
    // TODO: implement onReSend
  }

  @override
  void onReply(String val, Int64 replyId) {
    (_sendViewKey.currentState as ChatCustomBottomState)
        .showReply(val, replyId);
  }

  @override
  void onSendLocalMsg(String msg, bool isMe, [String msgType = "MSG_TEXT"]) {
    setState(() {
      if (isMe) {
        _messages.insert(
            0,
            types.TextMessage(
              author: _me,
              metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
              status: types.Status.sent,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: _generateRandomId(),
              text: msg,
            ));
      } else {
        if (msgType == "MSG_IMAGE") {
          final imgUrl = baseUrlImage + msg;
          _messages.insert(
              0,
              types.ImageMessage(
                author: _client,
                metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
                status: types.Status.sent,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: _generateRandomId(),
                uri: imgUrl,
                name: '',
                size: 150,
              ));
        } else {
          _messages.insert(
              0,
              types.TextMessage(
                author: _client,
                metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
                status: types.Status.sent,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: _generateRandomId(),
                text: msg,
              ));
        }
      }
    });
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
          (Timer timer) {
        //每8秒检查一次状态
        if (_timerCount > 0 && _timerCount % 8 == 0) {
          //setState(() {
          print("检查sdk状态");
          checkSDKStatus();
          //});
        }
        _timerCount +=1;
        // else {
        //   setState(() {
        //     _timerCount--;
        //   });
        // }
      },
    );
  }

  void checkSDKStatus(){
    if (Constant.instance.isConnected == false){
      Constant.instance.chatLib.disconnect();
      initSDK();
    }
  }
}
