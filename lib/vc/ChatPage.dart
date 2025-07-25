import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_format/date_format.dart';
import 'package:fixnum/src/int64.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:qichatsdk_demo_flutter/model/MyMsg.dart';
import 'package:qichatsdk_demo_flutter/model/ReplyMessageItem.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart' as sy;
import 'package:qichatsdk_demo_flutter/model/TextImages.dart';
import 'package:qichatsdk_demo_flutter/model/Worker.dart';
import 'package:qichatsdk_demo_flutter/store/chat_store.dart';
import 'package:qichatsdk_demo_flutter/vc/custom_bottom.dart';
import 'package:qichatsdk_demo_flutter/view/File_cell.dart';
import 'package:qichatsdk_demo_flutter/view/message_cell.dart';
import 'package:qichatsdk_demo_flutter/view/image_thumbnail_cell.dart';
import 'package:qichatsdk_demo_flutter/view/text_images_cell.dart';
import 'package:qichatsdk_demo_flutter/view/text_media_cell.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';
import 'dart:math';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart'
    as cMessage;
import '../Constant.dart';
import '../article_repository.dart';
import '../model/Custom.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../model/TextBody.dart';
import '../util/util.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../view/video_thumbnail_cell.dart';

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
  var _friend = types.User(
    firstName: 'client',
    imageUrl: 'assets/png/qiliaoicon_withback.png',
    id: 'client',
    lastName: "客服",
  );
  GlobalKey _sendViewKey = GlobalKey();
  var consultId = Int64(1);
  List<MsgItem>? replyList;
  bool _isFirstLoad = true;
  var store = ChatStore();
  Timer? _timer;
  int _timerCount = 0;
  Worker? _worker;

  AutoScrollController _scrollController = AutoScrollController();

  AutoReply? _autoReplyModel;

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
      }
    });
  }

  String _generateRandomId() {
    return Random().nextInt(1000000).toString();
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    if (_me.id == "user") {
      SmartDialog.showToast("此时不能发消息，请检查网络或稍等片刻");
      return;
    }
    var replyId = (_sendViewKey.currentState as ChatCustomBottomState).replyId;
    Constant.instance.chatLib.sendMessage(
        message.text, cMessage.MessageFormat.MSG_TEXT, consultId,
        replyMsgId: replyId, withAutoReply: withAutoReplyBuilder);
    debugPrint("replyId:$replyId");

    // sending是转圈的状态
    final textMessage = types.TextMessage(
        author: _me,
        id: "${Constant.instance.chatLib.payloadId}",
        text: message.text,
        metadata: {
          'msgTime': DateTime.now().millisecondsSinceEpoch,
          'replyMsg': await _getReplyMessage(replyId.toString())
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: types.Status.sending);
    setState(() {
      _messages.insert(0, textMessage);
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
        showUserAvatars: true,
        showUserNames: true,
        theme: const DefaultChatTheme(
            inputBackgroundColor: Colors.lightBlue,
            primaryColor: Colors.blueAccent,
            inputTextColor: Colors.black),
        textMessageBuilder: (message, {int? messageWidth, bool? showName}) {
          if (message.text.contains("\"color\"")) {
            return TextMediaCell(
              message: message,
              chatId: _me.id,
              listener: this,
              messageWidth: messageWidth ?? 0,
            );
          } else if (message.text.contains("\"imgs\"")) {
            return TextImagesCell(
              message: message,
              chatId: _me.id,
              listener: this,
              messageWidth: messageWidth ?? 0,
            );
          } else {
            return TextMessageWidget(
              message: message,
              autoReply: _autoReplyModel,
              chatId: _me.id,
              listener: this,
              messageWidth: messageWidth ?? 0,
              onExpandAction: (index, val) {
                setState(() {
                  if (val) {
                    // If the current section is expanding
                    _autoReplyModel?.autoReplyItem?.qa
                        ?.asMap()
                        .forEach((i, qaItem) {
                      if (i != index) {
                        // Collapse all other sections
                        qaItem.isExpanded = false;
                      }
                    });
                  }
                  //_autoReplyModel?.autoReplyItem?.qa?[index].isExpanded = val; // Set the clicked section's state
                });
              },
            );
          }
        },
        videoMessageBuilder: (message, {int? messageWidth}) {
          return VideoThumbnailCellWidget(
            message: message,
            chatId: _me.id,
            listener: this,
            messageWidth: messageWidth ?? 0,
          );
        },
        imageMessageBuilder: (message, {int? messageWidth}) {
          return ImageThumbnailCellWidget(
            message: message,
            chatId: _me.id,
            listener: this,
            messageWidth: messageWidth ?? 0,
          );
        },
        fileMessageBuilder: (message, {int? messageWidth}) {
          return FileCellWidget(
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
            onUploaded: (Urls urls) {
              if ((urls.uri ?? "").isEmpty) {
                SmartDialog.showToast("上传错误，返回路径为空！");
                return;
              }
              var ext = (urls.uri ?? "").split(".").lastOrNull ?? "#";

              debugPrint('上传成功 URL:${baseUrlImage + (urls.uri ?? "")}');
              if (videoTypes.contains(ext)) {
                print("发送视频消息");
                var videoUrl = urls.hlsUri == null ? urls.uri : urls.hlsUri;
                Constant.instance.chatLib.sendVideoMessage(urls.uri ?? "",
                    urls.thumbnailUri ?? "", urls.hlsUri ?? "", consultId,
                    withAutoReply: withAutoReplyBuilder);
                var msg = types.VideoMessage(
                    author: _me,
                    uri: baseUrlImage + (videoUrl ?? ""),
                    metadata: {
                      'msgTime': Util.convertDateToString(DateTime.now()),
                      'thumbnailUri': baseUrlImage + (urls.thumbnailUri ?? "")
                    },
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    id: "${Constant.instance.chatLib.payloadId}",
                    name: 'dd',
                    size: 200,
                    status: types.Status.sending,
                    remoteId: '0');
                setState(() {
                  _messages.insert(0, msg);
                });
              } else {
                print("发送文件消息-${urls.uri}");
                if (fileTypes.contains(ext)) {
                  Constant.instance.chatLib.sendMessage(urls.uri ?? "",
                      cMessage.MessageFormat.MSG_FILE, consultId,
                      withAutoReply: withAutoReplyBuilder,
                      fileSize: urls.size ?? 0,
                      fileName: urls.fileName ?? '');
                  var msg = types.FileMessage(
                      author: _me,
                      uri: baseUrlImage + (urls.uri ?? ""),
                      metadata: {
                        'msgTime': Util.convertDateToString(DateTime.now())
                      },
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      id: "${Constant.instance.chatLib.payloadId}",
                      name: urls.fileName ?? '',
                      size: urls.size ?? 0,
                      status: types.Status.sent,
                      remoteId: '0');
                  setState(() {
                    _messages.insert(0, msg);
                  });
                } else {
                  Constant.instance.chatLib.sendMessage(
                      urls.uri ?? "", cMessage.MessageFormat.MSG_IMG, consultId,
                      withAutoReply: withAutoReplyBuilder);
                  var msg = types.ImageMessage(
                      author: _me,
                      uri: baseUrlImage + (urls.uri ?? ""),
                      metadata: {
                        'msgTime': Util.convertDateToString(DateTime.now())
                      },
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      id: "${Constant.instance.chatLib.payloadId}",
                      name: 'dd',
                      size: 200,
                      status: types.Status.sent,
                      remoteId: '0');
                  setState(() {
                    _messages.insert(0, msg);
                  });
                }
              }
            }),
      ),
    );
  }

  Widget customAvatarBuilder(String userId) {
    //var avatar = baseUrlImage + (store.workerAvatar ?? "");
    return Container(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        //child: const Icon(Icons.av_timer_sharp),
        child: CachedNetworkImage(
          //imageUrl: baseUrlImage + (store.workerAvatar ?? ""),
          imageUrl: baseUrlImage + (_worker?.avatar ?? ""),
          width: 30,
          height: 30,
          progressIndicatorBuilder: (context, url, downloadProgress) => Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: downloadProgress.progress,
                color: Colors.blue,
              ),
            ),
          ),
            errorWidget: (context, url, error) => Image.asset("png/imgloading")
          // errorWidget: (context, url, error)
          // {
          //   print("加载 avatar 失败 ${url}");
          //   return Image.asset("png/imgloading");
          // }
        ),
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
        token: xToken,
        baseUrl: "wss://" + domain + "/v1/gateway/h5",
        sign: "9zgd9YUc",
        custom: getCustomParam(userName, 1),
        maxSessionMinutes: maxSessionMins);

    // Now the listener will receive the delegate events
    Constant.instance.chatLib.callWebSocket();
  }

  @override
  Future<void> receivedMsg(cMessage.Message msg) async {
    if (msg.msgOp == cMessage.MessageOperate.MSG_OP_EDIT) {
      var index =
          _messages.indexWhere((p) => p.remoteId == msg.msgId.toString());
      if (index >= 0) {
        var metaData = _messages[index].metadata;
        _messages.removeAt(index);
        _messages.insert(
            index,
            types.TextMessage(
                author: types.User(id: msg.sender.toString()),
                text: msg.content.data,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                metadata: metaData,
                id: _generateRandomId(),
                status: types.Status.sent,
                remoteId: msg.msgId.toString()));
      }
    } else {
      if (msg.msgSourceType == MsgSourceType.MST_SYSTEM_AUTO_TRANSFER){
        print("这种消息是自动回复的消息，不会计入未读消息");
      }
      MsgItem item = MsgItem();
      item.sender = msg.sender.toString();
      item.msgId = msg.msgId.toString();
      item.msgTime = Util.convertDateToString(msg.msgTime.toDateTime());
      item.image = Media();
      item.image?.uri = msg.image.uri;

      item.file = Urls();
      item.file?.uri = msg.file.uri;
      item.file?.size = msg.file.size;
      item.file?.fileName = msg.file.fileName;

      item.video = Urls();
      if (msg.video.hlsUri.isNotEmpty) {
        item.video?.uri = msg.video.hlsUri;
      } else {
        item.video?.uri = msg.video.uri;
      }
      item.video?.thumbnailUri = msg.video.thumbnailUri;

      item.replyMsgId = msg.replyMsgId.toString();

      item.content = sy.Content();
      item.content?.data = msg.content.data;

      composeLocalMsg(item);
      print("Received Message: ${msg}");
    }
    _updateUI("info");
  }

  @override
  void systemMsg(Result result) {
    print("System Message: ${result.message} Code:${result.code}");
    Constant.instance.isConnected = false;
    if (result.code == 1002 || result.code == 1010 || result.code == 1005) {
      if (result.code == 1002) {
        //showTip("无效的Token")
        //有时候服务器反馈的这个消息不准，可忽略它
      } else if (result.code == 1005) {
        //会话超时，返回到之前页面
        SmartDialog.showToast("会话超时", displayTime: Duration(seconds: 3));
        Navigator.pop(context);
      } else {
        //在此处退出聊天
        SmartDialog.showToast("已在别处登录了", displayTime: Duration(seconds: 3));
        Navigator.pop(context);
      }
    } else {
      _getUnsentMessage();
    }
  }

  @override
  void connected(SCHi c) {
    print("Connected with token: ${c.token}");
    xToken = c.token;
    Constant.instance.isConnected = true;
    //_updateUI("连接成功！");
    //c.workerId;
    SmartDialog.showLoading();
    ArticleRepository.assignWorker(consultId).then((onValue) {
      if (onValue != null) {
        _worker = Worker(
            workerId: onValue.workerId,
            nick: onValue?.nick,
            avatar: onValue?.avatar);
        store.workerAvatar = _worker?.avatar ?? "";

        //_preWorker = _worker;//Worker(workerId: workerId, nick: onValue?.nick);
        getChatData(_worker!, false);
        store.loadingMsg = onValue?.nick ?? "..";
      } else {
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
    if ((_worker?.workerId ?? 0) > 0 &&
        (_worker?.workerId ?? 0) != msg.workerId) {
      consultId = msg.consultId;
      getChatData(
          Worker(
              workerId: msg.workerId,
              nick: msg.workerName,
              avatar: msg.workerAvatar),
          true);
      store.loadingMsg = msg.workerName;
    }
  }

  @override
  void msgReceipt(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    _updateUI("收到回执 payloadId:${payloadId}");
    print("收到回执 payloadId:${payloadId} msgId: ${msg.msgId}");
    updateMessageStatus(
        payloadId.toString(), types.Status.sent, msg.msgId.toString());
    withAutoReplyBuilder = null;
  }

  @override
  void msgDeleted(cMessage.Message msg, Int64 payloadId, String? errMsg) {
    var index = _messages.indexWhere((p) => p.remoteId == msg.msgId.toString());
    if (index >= 0) {
      _messages.removeAt(index);

      // MyMsg model = MyMsg();
      // model.text = '对方撤回了1条消息';
      // model.senderId = msg.sender.toString();
      // model.msgId = msg.msgId.toString();
      // model.msgTime = msg.msgTime.toDateTime();

      MsgItem item = MsgItem();
      item.content?.data = '对方撤回了1条消息';
      item.sender = msg.sender.toString();
      item.msgId = msg.msgId.toString();
      item.msgTime = Util.convertDateToString(msg.msgTime.toDateTime());

      composeLocalMsg(item, isTipText: true);
      _updateUI("删除成功 msgId:${msg.msgId}");
      print("删除成功: ${msg.msgId} ");
    } else {
      print("删除失败");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.length > 5) {
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
    //行不同
    //_scrollController?.scrollToIndex(_messages.length);
  }

  _updateUI(String info) {
    if (mounted) {
      print("_scrollToBottom 滑到底部了");
      _scrollToBottom();
      setState(() {});
    }
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

  Future<void> getChatData(Worker myWorker, bool workerChanged) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(PARAM_XTOKEN, xToken);
    _messages.clear();
    //SmartDialog.showLoading();
    //聊天记录
    var h = await ArticleRepository.queryHistory(consultId);
    _me = types.User(
        id: h?.request?.chatId ?? "0",
        imageUrl: 'assets/png/me_avatar.png',
        firstName: userName);
    replyList = h?.replyList;
    _buildHistory(h);

    SmartDialog.dismiss();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      //自动回复
      AutoReply? model = await ArticleRepository.queryAutoReply(
          consultId, myWorker.workerId ?? 0);
      print(model?.autoReplyItem?.qa);
      print(model?.autoReplyItem?.title);
      _autoReplyModel = model;
      if (model != null && (model.autoReplyItem?.qa?.length ?? 0) > 0) {
        _messages.insert(
            0,
            types.TextMessage(
              metadata: model.toJson(),
              author: _friend,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              text: 'autoReplay',
              // 根据这个字段来自定义界面
              id: _generateRandomId(),
              status: types.Status.sent,
            ));
      }
    }

    if (workerChanged) {
      _worker = myWorker;
    }

    var hello = "您好，${myWorker.nick}为您服务！";
    //您好，{转出会话客服账号} 已为您转接！{接收会话客服账号} 为您服务！
    setState(() {
      _messages.insert(
          0,
          types.TextMessage(
            author: _friend,
            metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: hello,
            // 根据这个字段来自定义界面
            id: _generateRandomId(),
            status: types.Status.sent,
          ));
      store.workerAvatar = myWorker.avatar ?? "";
    });
    //处理在无网、或断网情况下未发出去的消息
    _handleUnSent();
    ArticleRepository.markRead(consultId);
  }

  @override
  void dispose() {
    print("chat page disposed");
    Constant.instance.chatLib.disconnect();
    Constant.instance.isConnected = false;
    _timer?.cancel();
    _timer = null;
    SmartDialog.dismiss();
    _getUnsentMessage();
    super.dispose();
  }

  _buildHistory(Sync? h) {
    if (h == null || (h?.list?.length ?? 0) == 0) {
      return;
    }
    Constant.instance.chatId = h.request?.chatId ?? '0';
    Iterable<MsgItem> msgItems = h.list!;
    for (var msg in msgItems) {
      if (msg.msgOp == "MSG_OP_DELETE") {
        continue;
      }

      if (msg.workerChanged != null) {
        msg.content?.data = msg.workerChanged?.greeting ?? "";
        composeLocalMsg(msg, isHistory: true, isTipText: true);
      } else {
        composeLocalMsg(msg, isHistory: true);
      }
    }
  }

  _getUnsentMessage() {
    if (_messages.isEmpty) {
      return;
    }
    //把未发送的消息保存起来
    //if (unSentMessage == null || unSentMessage?.length == 0) {
    unSentMessage[consultId] =
        _messages.takeWhile((p) => p.status == types.Status.sending).toList();
    //}
    print("获取到未发送的消息总数${unSentMessage?.length}");
  }

  _handleUnSent() {
    print("处理未发送的消息 ${unSentMessage?.length}");
    if (Constant.instance.isConnected &&
        unSentMessage[consultId] != null &&
        unSentMessage[consultId]!.length > 0) {
      print("重发消息总数${unSentMessage?.length}");
      _messages.insertAll(0, unSentMessage[consultId]!);
      _updateUI("info");
      for (var msg in unSentMessage[consultId]!!) {
        print("重发消息${msg}");
        if (msg is types.TextMessage) {
          print("重发消息${(msg as types.TextMessage).text}");
          Constant.instance.chatLib
              .resendMSg(msg.text, consultId, Int64(int.parse(msg.id)));
        }
      }
      unSentMessage[consultId]!.clear();
    }
  }

  Future<types.Message?> composeLocalMsg(MsgItem msgModel,
      {bool isHistory = false,
      bool isTipText = false,
      bool onlyCompose = false}) async {
    String imgUri = msgModel.image?.uri ?? '';
    String videoUri = msgModel.video?.uri ?? '';
    String thumbnailUri = msgModel.video?.thumbnailUri ??
        'https://www.bing.com/th?id=OHR.GoldfinchSunflower_ROW8225520434_1920x1200.jpg&rf=LaDigue_1920x1200.jpg';
    String fileUri = msgModel.file?.uri ?? '';
    String text = msgModel.content?.data ?? '';
    String senderId = msgModel.sender ?? '';
    String msgId = msgModel.msgId ?? '';
    String? msgTime;
    int? milliSeconds;
    if (msgModel.msgTime != null) {
      msgTime = Util.convertTime(msgModel.msgTime!);
      milliSeconds =
          Util.parseStringToDateTime(msgModel.msgTime!)?.millisecondsSinceEpoch;
    }

    if (!thumbnailUri.contains("http")) {
      thumbnailUri = baseUrlImage + thumbnailUri;
    }

    // var replyText = _getReplyText(msgModel.replyMsgId ?? "", insert);
    ReplyMessageItem?
        replyMsg; // _getReplyMessage(msgModel.replyMsgId ?? "", insert);
    if ((msgModel.replyMsgId ?? "").length > 5) {
      replyMsg = isHistory
          ? _getReplyMessageFromHistory(msgModel.replyMsgId ?? "")
          : await _getReplyMessage(msgModel.replyMsgId ?? "");
    }
    var sender = types.User(id: senderId);

    if (msgModel.msgSourceType == "MST_SYSTEM_WORKER") {
      sender = _me;
    } else if (msgModel.msgSourceType == "MST_SYSTEM_CUSTOMER" ||
        msgModel.msgSourceType == "MST_AI") {
      sender = _friend;
    }

    if (sender.id == _me.id) {
      sender = _me;
    } else {
      _friend = types.User(
        firstName: 'client',
        //imageUrl: baseUrlImage + store.workerAvatar,
        imageUrl: baseUrlImage + (_worker?.avatar ?? ""),
        id: 'client',
        lastName: "客服",
      );
      sender = _friend;
    }
    types.Message? msg;
    if (fileUri.isNotEmpty) {
      if (!fileUri.contains("http")) {
        fileUri = baseUrlImage + fileUri;
      }
      msg = types.FileMessage(
          author: sender,
          createdAt: milliSeconds,
          uri: fileUri,
          //repliedMessage: replyMsg,
          id: _generateRandomId(),
          name: msgModel.file?.fileName ?? 'no file name',
          size: msgModel.file?.size ?? 0,
          metadata: {'msgTime': msgTime, 'replyMsg': replyMsg},
          status: types.Status.sent,
          remoteId: msgId);
    } else if (imgUri.isNotEmpty) {
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
          metadata: {'msgTime': msgTime, 'replyMsg': replyMsg},
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
          metadata: {
            'msgTime': msgTime,
            'thumbnailUri': thumbnailUri,
            'replyMsg': replyMsg
          },
          status: types.Status.sent,
          remoteId: msgId);
    } else if (text.isNotEmpty) {
      msg = types.TextMessage(
          author: sender,
          text: text,
          createdAt: milliSeconds,
          metadata: {
            'msgTime': msgTime,
            'tipText': isTipText,
            'replyMsg': replyMsg
          },
          id: _generateRandomId(),
          status: types.Status.sent,
          remoteId: msgId);
    } else {
      print("消息内容为空");
    }

    if (msg != null && !onlyCompose) {
      isHistory ? _messages.add(msg) : _messages.insert(0, msg);
      //_messages.add(msg);
      //_messages.insert(0, msg)  ;
    }
    return msg;
  }

  ReplyMessageItem? _getReplyMessageFromHistory(String replyMsgId) {
    if (replyMsgId.length < 5) {
      return null;
    }
    //types.Message? replyModel;
    ReplyMessageItem? replyItem;
    var index = -1;
    if (replyList != null) {
      index = replyList!.indexWhere((p) => p.msgId == replyMsgId);
      if (index >= 0) {
        var oriMsg = replyList![index];
        replyItem = _getReplyItem(oriMsg);
      }
    }
    return replyItem;
  }

  Future<ReplyMessageItem?> _getReplyMessage(String replyMsgId) async {
    if (replyMsgId.length < 5) {
      return null;
    }
    //types.Message? replyModel;
    ReplyMessageItem? replyItem;
    var index = -1;

    index = _messages.indexWhere((item) => item.remoteId == replyMsgId);
    if (index >= 0) {
      replyItem = ReplyMessageItem();
      var oriMsg = _messages[index];
      if (oriMsg.type == types.MessageType.text) {
        var txtMsg = (oriMsg as types.TextMessage).text;
        if (txtMsg.contains("\"color\"")) {
          final jsonData = jsonDecode(txtMsg);
          var result = TextBody.fromJson(
            jsonData,
          );
          txtMsg = result.content ?? "";
        } else if (txtMsg.contains("\"imgs\"")) {
          final jsonData = jsonDecode(txtMsg);
          var result = TextImages.fromJson(
            jsonData,
          );
          txtMsg = result.message ?? "";
        }
        replyItem?.content = txtMsg;
      } else if (oriMsg.type == types.MessageType.image) {
        replyItem?.fileName = (oriMsg as types.ImageMessage).uri;
      } else if (oriMsg.type == types.MessageType.video) {
        replyItem?.fileName = (oriMsg as types.VideoMessage).uri;
      } else if (oriMsg.type == types.MessageType.file) {
        replyItem?.fileName = (oriMsg as types.FileMessage).uri;
        replyItem?.size = (oriMsg as types.FileMessage).size.toInt();
      }
    } else {
      var messageResponse = await ArticleRepository.queryMessage(replyMsgId);
      final replyList = messageResponse?.replyList ?? [];
      replyItem = _getReplyItem(replyList[0]);
      print(s);
      Timer(const Duration(seconds: 1), () {
        _updateUI("info");
      });
    }
    return replyItem;
  }

  ReplyMessageItem _getReplyItem(MsgItem oriMsg) {
    var replyItem = ReplyMessageItem();
    if (oriMsg != null) {
      switch (oriMsg.msgFmt.toString()) {
        case "MSG_TEXT":
          var txtMsg = oriMsg.content?.data ?? "";
          if (txtMsg.contains("\"color\"")) {
            final jsonData = jsonDecode(txtMsg);
            var result = TextBody.fromJson(
              jsonData,
            );
            txtMsg = result.content ?? "";
          } else if (txtMsg.contains("\"imgs\"")) {
            final jsonData = jsonDecode(txtMsg);
            var result = TextImages.fromJson(
              jsonData,
            );
            txtMsg = result.message ?? "";
          }
          replyItem.content = txtMsg;
          break;
        case "MSG_IMG":
          replyItem.fileName = oriMsg.image?.uri ?? "";
          break;
        case "MSG_VIDEO":
          replyItem.fileName = oriMsg.video?.uri ?? "";
          break;
        case "MSG_FILE":
          replyItem.size = (oriMsg?.file?.size ?? 0);
          replyItem.fileName = oriMsg?.file?.uri;
          break;
      }
    }
    return replyItem;
  }

  void handleUnSent() {}

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
              author: _friend,
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
              author: _friend,
              metadata: {'msgTime': Util.convertDateToString(DateTime.now())},
              status: types.Status.sent,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: _generateRandomId(),
              text: msg,
            ));
      }
    }

    //滑动到底部
    //delayExecution(1, () => {
    _updateUI("info");
    // });
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        //上传视频的时候，在这里更新上传进度，对接开发人员可以有自己的办法，和聊天sdk无关。
        if (uploadProgress > 0 &&
            (uploadProgress < 67 || uploadProgress >= 70) &&
            uploadProgress < 96) {
          uploadProgress += 1;
          this.updateProgress(uploadProgress);
        }
        //每8秒检查一次状态
        if (_timerCount > 0 && _timerCount % 8 == 0) {
          //setState(() {
          print("检查sdk状态${DateTime.now()}");
          checkSDKStatus();
          //});
        }
        _timerCount += 1;
        // else {
        //   setState(() {
        //     _timerCount--;
        //   });
        // }
      },
    );
  }

  void checkSDKStatus() {
    if (Constant.instance.isConnected == false) {
      Constant.instance.chatLib.disconnect();
      initSDK();
    }
  }

  void updateProgress(int progress) {
    SmartDialog.showLoading(msg: "正在上传 ${progress}%");
  }
}
