import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichatsdk_demo_flutter/model/ReplyMessageItem.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart'
    as cmessage;
import 'package:fixnum/src/int64.dart';
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Constant.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../util/util.dart';
import 'dart:io';
import '../vc/FullImageView.dart';
import '../vc/FullVideoPlayer.dart';
import 'common_webview.dart';
import 'enhance_expansion_panel/enhance_expansion_panel.dart';

class TextMessageWidget extends StatefulWidget {
  types.TextMessage message;
  int messageWidth;
  String chatId;
  AutoReply? autoReply;
  MessageItemOperateListener listener;
  Function(int, bool) onExpandAction;
  TextMessageWidget(
      {super.key,
      required this.chatId,
      required this.message,
      required this.messageWidth,
      required this.listener,
      this.autoReply,
      required this.onExpandAction});

  @override
  State<TextMessageWidget> createState() => _TextMessageWidgetState();
}

class _TextMessageWidgetState extends State<TextMessageWidget> {
  types.Status? get state => widget.message.status;

  String get content => widget.message.text;
  //String get msgTime => widget.message.metadata?['msgTime'] ?? '';
  String get msgTime => Util().formatTimestamp(widget.message.createdAt ?? 0);

  ReplyMessageItem? replyItem;

  List<Qa> sectionList = [];
  AutoReply? autoReplyModel;
  final _toolTipController = SuperTooltipController();

  @override
  void initState() {
    super.initState();

    if (content == 'autoReplay' && widget.message.metadata != null) {
      if (widget.autoReply != null) {
        autoReplyModel = widget.autoReply;
        sectionList = autoReplyModel?.autoReplyItem?.qa ?? [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return getWidget(context);
  }

  getWidget(context) {
    if (state != null && state == types.Status.error) {
      return buildFail(context);
    }
    // if (state != null && state == types.Status.sending) {
    //   return buildLoading();
    // }
    // if (widget.message.metadata != null && widget.message.metadata!['isSystemMessage'] == true) {
    //  return buildTipMessage(widget.message);
    // }
    return buildGptMessage(context);
  }

  buildFail(context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {},
            child: const Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.redAccent,
                ),
                SizedBox(
                  width: 4,
                ),
                Text(
                  '消息失败了哦~',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  buildLoading() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ));
  }

  buildGptMessage(BuildContext context) {
    if (content == 'autoReplay' && widget.message.metadata != null) {
      return initAutoReplay();
    }
    if (widget.message.metadata != null && widget.message.metadata!['tipText'] == true) {
      return initWithdraws();
    }

    if (widget.message.metadata != null && widget.message.metadata!['replyMsg'] != null){
       replyItem = widget.message.metadata!['replyMsg'];
    }
    return buildNormalMessage();
  }

  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  content, Int64.parseInt(widget.message.remoteId.toString()));
              _toolTipController.hideTooltip();
            },
            child: buildRowText(Icons.sms, '回复')),
        TextButton(
            onPressed: () {
              FlutterClipboard.copy(content).then((value) {
                _toolTipController.hideTooltip().then((val) {
                  SmartDialog.showToast("已复制到剪切板");
                });
              });
            },
            child: buildRowText(Icons.copy, '复制'))
      ],
    );
  }

  buildRowText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.black54,
          size: 16,
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  buildNormalMessage() {
    var textStyle = TextStyle(
        fontSize: 14,
        color: widget.message.author.id == widget.chatId
            ? Colors.white
            : Colors.black);
    return   Container(
      color: widget.message.author.id == widget.chatId
          ? Colors.blue
          : Colors.blue.shade100,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
      SuperTooltip(
        content: buildToolAction(),
        controller: _toolTipController,child: Text(
            msgTime,
            style: TextStyle(
                fontSize: 12,
                color: widget.message.author.id == widget.chatId
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey),
          )),
          GestureDetector(
              onLongPress: ((Platform.isAndroid || Platform.isIOS) && (widget.message.remoteId ?? "").length > 8)
                  ? () => _toolTipController.showTooltip()
                  : null,
              onSecondaryTapDown: (details) {
                if (!Platform.isAndroid && !Platform.isIOS && (widget.message.remoteId ?? "").length > 8)  _toolTipController.showTooltip();
              },
           child:Container(
              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
              child:Text(
                content,
                style: textStyle,
              ))),  replyItem == null
              ? const SizedBox()
              : _buildFileCell()
        ],
      ),
    );
  }

  buildTipMessage(types.TextMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              message.metadata!['tipText'] ?? '',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  initWithdraws() {
    return SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // Set the desired width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                child:   Text(
                  msgTime,
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.message.author.id == widget.chatId
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey),
                )),
            Padding(
                padding: const EdgeInsets.all(5.0),
                child:   Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                )
            )
          ],
        ));
  }

  initAutoReplay() {
    var bgColor = Colors.blue.shade100;
    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            autoReplyModel?.autoReplyItem?.title ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          EnhanceExpansionPanelList(
            elevation: 0,
            expansionCallback: (index, expand) {
              sectionList[index].isExpanded = !expand;
              // 告诉外面的数据源，哪个展开了
              widget.onExpandAction(index, !expand);
            },
            dividerColor: Colors.white.withOpacity(0.3),
            children: List.generate(sectionList.length, (index) {
              Qa qa = sectionList[index];
              List<Qa> relatedList = qa.related ?? [];
              var canTapOnHeader = relatedList.isNotEmpty;
              return EnhanceExpansionPanel(
                  backgroundColor: bgColor,
                  canTapOnHeader: true,
                  isExpanded: qa.isExpanded ?? false,
                  arrowPosition: EnhanceExpansionPanelArrowPosition.tailing,
                  arrow: canTapOnHeader
                      ? const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.blue,
                        )
                      : Container(),
                  arrowExpanded: canTapOnHeader
                      ? const Icon(
                          Icons.keyboard_arrow_down_sharp,
                          color: Colors.blue,
                        )
                      : Container(),
                  headerBuilder: (ctx, val) {
                    return Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  width: 1,
                                  color: Colors.white.withOpacity(0.3)))),
                      child: InkWell(
                        onTap: () {
                          if (relatedList.isEmpty) {
                            qaClicked(qa);
                          }else{
                              sectionList[index].isExpanded = !(sectionList[index].isExpanded ?? false);
                              widget.onExpandAction(index, sectionList[index].isExpanded ?? false);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(qa.question?.content?.data ?? '',
                              style: TextStyle(
                                  color: qa.isClicked == true
                                      ? Colors.black26
                                      : Colors.black)),
                        ),
                      ),
                    );
                  },
                  body: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(relatedList.length, (i) {
                        Qa qa = relatedList[i];
                        return InkWell(
                          onTap: () {
                            qaClicked(qa);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(qa.question?.content?.data ?? '',
                                style: TextStyle(
                                    color: qa.isClicked == true
                                        ? Colors.grey
                                        : Colors.black)),
                          ),
                        );
                      }),
                    ),
                  ));
            }),
          )
        ],
      ),
    );
  }

  _buildFileCell() {
    var fileName = "";
    var fileSize;
    var url = "";
    var ext = replyItem?.fileName?.split(".").last ?? "";
    if (fileTypes.contains(ext)) {
      url = replyItem?.fileName ?? "";
      fileSize = replyItem?.size;
      fileName = url
          .split('/')
          .last;
    } else if (imageTypes.contains(ext)) {
      url = replyItem?.fileName ?? "";
      fileName = url
          .split('/')
          .last;
    } else if (videoTypes.contains(ext)) {
      url = replyItem?.fileName ?? "";
      fileName = url
          .split('/')
          .last;
    } else{
      fileName = replyItem?.content ?? "";
    }
    if (!url.contains("http")) {
      url = baseUrlImage + url;
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () async {
          var ext = fileName.split(".").last.toLowerCase();
          if (imageTypes.contains(ext)){
            Navigator.push(
                context,
                MaterialPageRoute( builder: (context) => FullImageView(message: null, url: url,)));
          }else if(videoTypes.contains(ext)){
            Navigator.push(
                context,
                MaterialPageRoute( builder: (context) => Fullvideoplayer(message: widget.message.repliedMessage as types.VideoMessage)));
          }else if(fileTypes.contains(ext)){
            var googleDocsUrl =
                "https://docs.google.com/gview?embedded=true&url=${url}";
            //_launchInWebView(Uri.parse(googleDocsUrl));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommonWebView(
                  url: googleDocsUrl,
                  title: "文件",
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            Text("回复："),
           if (ext.isNotEmpty) Image.asset(
              Util().displayFileThumbnail(fileName),
              width: 40,
              height: 40,
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName),
                // 转kb或者M
                if (fileSize != null) Text(Util().formatFileSize(fileSize)),
              ],
            )
            )
          ],
        ),
      ),
    );
  }

  void qaClicked(Qa? qa) {
    if (qa == null) return;

    if (qa.isClicked == true) {
      return;
    }
    setState(() {
      qa.isClicked = !(qa.isClicked ?? false);
    });

    String questionTxt = qa.question?.content?.data ?? "";
    String txtAnswer = qa.content ?? "null";

    withAutoReplyBuilder = cmessage.WithAutoReply();

    withAutoReplyBuilder?.title = questionTxt;
    withAutoReplyBuilder?.id = Int64(qa.id ?? 0);
    //withAutoReplyBuilder.createdTime = Utils().getNowTimeStamp();

    widget.listener.onSendLocalMsg(questionTxt, true);
    // Sending question message
    if (txtAnswer.isNotEmpty) {
      // Auto-reply
      var uAnswer = cmessage.MessageUnion();
      var uQC = cmessage.MessageContent();
      uQC.data = txtAnswer;
      uAnswer.content = uQC;
      withAutoReplyBuilder?.answers.add(uAnswer);
      widget.listener.onSendLocalMsg(txtAnswer, false);
    }

    for (var a in qa.answer ?? []) {
      if (a?.image?.uri != null) {
        // Auto-reply with image
        var uAnswer = cmessage.MessageUnion();
        var uQC = cmessage.MessageImage();
        uQC.uri = a.image!.uri!;
        uAnswer.image = uQC;
        withAutoReplyBuilder?.answers.add(uAnswer);
        widget.listener.onSendLocalMsg(a!.image!.uri!, false, "MSG_IMAGE");
      } else if (a?.content?.data != null) {
        var uAnswer = cmessage.MessageUnion();
        var uQC = cmessage.MessageContent();
        uQC.data = txtAnswer;
        uAnswer.content = uQC;
        withAutoReplyBuilder?.answers.add(uAnswer);
        widget.listener.onSendLocalMsg(a?.content?.data ?? "", false);
      }
    }
  }

  Future<void> _launchInWebView(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }
}
