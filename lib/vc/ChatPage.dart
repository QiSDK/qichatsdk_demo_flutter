import 'dart:ffi';

import 'package:fixnum/src/int64.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:qichatsdk_demo_flutter/model/MyMsg.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart';
import 'package:qichatsdk_demo_flutter/vc/custom_bottom.dart';
import 'package:qichatsdk_demo_flutter/vc/message_cell.dart';
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
import '../view/tip_message.dart';

class ChatPage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    // _loadInitialMessages();
    initSDK();
  }

  void _loadInitialMessages() {
    // Load any initial messages if needed, or keep it empty for a new chat
    setState(() {
      _messages.addAll([
        types.TextMessage(
          author: _me,
          createdAt: DateTime.now().millisecondsSinceEpoch,
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
    var replyId = (_sendViewKey.currentState as ChatCustomBottomState).replyId;
    Constant.instance.chatLib.sendMessage(
        message.text, cMessage.MessageFormat.MSG_TEXT, consultId,
        replyMsgId: replyId, withAutoReply: withAutoReplyBuilder);
    withAutoReplyBuilder = null;
    debugPrint("replyId:$replyId");
    // types.TextMessage? replyModel;
    // try {
    //   replyModel = _messages.firstWhere((item) => item.id == '$replyId')
    //       as types.TextMessage;
    //   debugPrint("replyModel:${replyModel.toJson()}");
    // } catch (e) {
    //   print(e);
    // }

    // sending是转圈的状态
    final textMessage = types.TextMessage(
        author: _me,
        id: "${Constant.instance.chatLib.payloadId}",
        text: message.text,
        metadata: {
          'msgTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'replyText': _getReplyText(replyId.toString(), false)
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
        title: Text('Chat'),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        disableImageGallery: false,
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
            Constant.instance.chatLib.sendMessage(
                url, cMessage.MessageFormat.MSG_IMG, consultId, withAutoReply: withAutoReplyBuilder);
            var msg = types.ImageMessage(
                author: _me,
                uri: url,
                id: "${Constant.instance.chatLib.payloadId}",
                name: 'dd',
                size: 200,
                status: types.Status.sent,
                remoteId: '0');
            setState(() {
              _messages.insert(0, msg);
            });
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
      } else if (result.code == 1005) {
        Navigator.pop(context);
      } else {
        //showTip("在别处登录了")
        //toast("在别处登录了")
        //在此处退出聊天
      }
    }
  }

  @override
  void connected(SCHi c) {
    print("Connected with token: ${c.token}");
    xToken = c.token;
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
    updateMessageStatus(payloadId.toString(), types.Status.sent, msg.msgId.toString());
  }

  @override
  void msgDeleted(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    //_messages.removeWhere((p) => p.remoteId == msg.msgId );
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

      // composeLocalMsg("", "", "对方撤回了1条消息", "system", "", append: true);

      _updateUI("删除成功 msgId:${msg.msgId}");
      print("删除成功: ${msg.msgId} ");
    } else {
      print("删除失败");
    }
  }

  _updateUI(String info) {
    setState(() {});
  }

  void updateMessageStatus(String payloadId, types.Status newStatus, String msgId) {
    // Find the message by its id
    var index = _messages.indexWhere((p) => p.id == payloadId);
    // Check if message exists
    if (index != -1) {
      setState(() {
        // Create a new message object with the updated status
        _messages[index] = _messages[index].copyWith(status: newStatus, remoteId: msgId);
      });
    }
  }

  Future<void> getChatData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(PARAM_XTOKEN, xToken);

    //聊天记录
    var h = await ArticleRepository.queryHistory(consultId);
    _me = types.User(id: h?.request?.chatId ?? "");

    replyList = h?.replyList;
    _buildHistory(h?.list);

    //自动回复
    AutoReply? model =
        await ArticleRepository.queryAutoReply(consultId, workerId);
    print(model?.autoReplyItem?.qa);
    print(model?.autoReplyItem?.title);
    if (model != null) {
      setState(() {
        _messages.insert(
            0,
            types.TextMessage(
              metadata: model.toJson(),
              author: _client,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              text: 'autoReplay', // 根据这个字段来自定义界面
              id: _generateRandomId(),
              status: types.Status.sent,
            ));
      });
    }
  }

  @override
  void dispose() {
    print("chat page disposed");
    Constant.instance.chatLib.disconnect();
    Constant.instance.isConnected = false;
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
      model.msgTime = parseStringToDateTime(msg.msgTime);
      model.replyMsgId = msg.replyMsgId;
      composeLocalMsg(model);
      // composeLocalMsg(msg.image?.uri ?? "", msg.video?.uri ?? "", msg.content?.data ?? "", msg.sender.toString(), msg.msgId.toString());
    }
    if (mounted) {
      setState(() {});
    }
    ArticleRepository.markRead(consultId);
  }

  DateTime? parseStringToDateTime(String? str) {
    if (str == null || str.isEmpty) {
      return null; // 如果字符串为空或为 null，返回 null
    }

    try {
      return DateTime.parse(str); // 尝试将字符串转换为 DateTime
    } catch (e) {
      print('Error parsing string to DateTime: $e');
      return null; // 如果转换失败，返回 null
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
      msgTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(msgModel.msgTime!);
      milliSeconds = msgModel.msgTime!.millisecondsSinceEpoch;
    }

    var replyText = _getReplyText(msgModel.replyMsgId ?? "", insert);
    final sender = types.User(id: senderId);
    types.Message msg;
    if (imgUri.isNotEmpty) {
      var imgUrl = imgUri;
      if (!imgUri.contains("http")){
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
      var  url = videoUri;
      if (!imgUri.contains("http")){
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
          metadata: {'msgTime': msgTime,  'replyText': replyText},
          id: _generateRandomId(),
          status: types.Status.sent,
          remoteId: msgId);
    }

    insert ? _messages.insert(0, msg) : _messages.add(msg);

  }

  String _getReplyText(String replyMsgId, bool append){
    if (replyMsgId.isEmpty){
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
      }else{
        //历史记录
        if (replyList != null) {
          index = replyList!.indexWhere((p) => p.msgId == replyMsgId);

          if (index >= 0) {
              var msg = replyList![index];
             if ((msg.image?.uri ?? "").isNotEmpty) {
              replyTxt = "[图片]";
            } else if ((msg.video?.uri ?? "").isNotEmpty) {
              replyTxt = "[视频]";
            }else {
               replyTxt = msg.content?.data ?? "";
             } 
          }
        }
      }
    return replyTxt;
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
                status: types.Status.sent,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: _generateRandomId(),
                uri: imgUrl,
                name: '',
                size: 150,
              ));
        }  else {
          _messages.insert(
              0,
              types.TextMessage(
                author: _client,
                status: types.Status.sent,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: _generateRandomId(),
                text: msg,
              ));
        }
      }
    });
  }
}
