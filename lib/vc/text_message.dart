import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichatsdk_flutter/src/dartOut/api/common/c_message.pb.dart'
    as CMessage;
import 'package:fixnum/src/int64.dart';
import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';
import '../model/MessageItemOperateListener.dart';

class TextMessageWidget extends StatefulWidget {
  types.TextMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  TextMessageWidget(
      {super.key,
      required this.chatId,
      required this.message,
      required this.messageWidth,
      required this.listener});

  @override
  State<TextMessageWidget> createState() => _TextMessageWidgetState();
}

class _TextMessageWidgetState extends State<TextMessageWidget> {
  types.Status? get state => widget.message.status;

  String get content => widget.message.text;
  String get msgTime => widget.message.metadata?['msgTime'] ?? '';

  List<Qa> sectionList = [];
  AutoReply? autoReplyModel;

  @override
  void initState() {
    super.initState();

    if (content == 'autoReplay' && widget.message.metadata != null) {
      autoReplyModel = AutoReply.fromJson(widget.message.metadata!);
      sectionList = autoReplyModel?.autoReplyItem?.qa ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: getWidget(context),
    );
  }

  getWidget(context) {
    if (state != null && state == types.Status.error) {
      return buildFail(context);
    }
    // if (state != null && state == types.Status.sending) {
    //   return buildLoading();
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
                // SvgPicture.asset('assets/common/warn_error.svg'),
                SizedBox(
                  width: 4,
                ),
                Text(
                  '失败的样式',
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
        child: const Text('loading')
        // Lottie.asset(ThemeLottie.buttonLoading.path(), width: 80, height: 22),
        );
  }

  buildGptMessage(BuildContext context) {
    var textStyle = TextStyle(
        fontSize: 14,
        color: widget.message.author.id == widget.chatId
            ? Colors.white
            : Colors.black);
    if (content == 'autoReplay' && widget.message.metadata != null) {
      return initAutoReplay();
    }
    if (content.contains('对方撤回')) {
      return initWithdraws();
    }
    if (widget.message.type == types.MessageType.image) {
      return CachedNetworkImage(
        key: Key(widget.message.text),
        width: 200,
        height: 150,
        imageUrl: widget.message.text,
      );
    }
    return Container(
      color: widget.message.author.id == widget.chatId
          ? Colors.blue
          : Colors.blue.shade100,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msgTime,
            style: TextStyle(
                fontSize: 12,
                color: widget.message.author.id == widget.chatId
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey),
          ),
          Text(
            content,
            style: textStyle,
          ),
        ],
      ),
    );
  }

  initWithdraws() {
    return Text(
      content,
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    );
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
          ExpansionPanelList(
            elevation: 0,
            expansionCallback: (index, expand) {
              setState(() {
                sectionList[index].isExpanded = expand;
              });
            },
            dividerColor: Colors.white.withOpacity(0.3),
            children: List.generate(sectionList.length, (index) {
              Qa qa = sectionList[index];
              List<Qa> relatedList = qa.related ?? [];
              var canTapOnHeader = relatedList.length <= 0;
              return ExpansionPanel(
                  backgroundColor: bgColor,
                  canTapOnHeader: canTapOnHeader,
                  isExpanded: qa.isExpanded ?? false,
                  headerBuilder: (ctx, val) {
                    return Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  width: 1,
                                  color: Colors.white.withOpacity(0.3)))),
                      child: InkWell(
                        onTap: () {
                          //widget.listener.onSendLocalMsg(data.question?.content?.data ?? 'No data', true);
                          //widget.listener.onSendLocalMsg(data.content ?? 'No data', false);
                          //print('Tapped on: ${data.question?.content ?? 'No data'}');
                          if (relatedList.length <= 0) {
                            qaClicked(qa);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(qa.question?.content?.data ?? ''),
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
                        Qa data = relatedList[i];
                        return InkWell(
                          onTap: () {
                            //widget.listener.onSendLocalMsg(data.question?.content?.data ?? 'No data', true);
                            //widget.listener.onSendLocalMsg(data.content ?? 'No data', false);
                            //print('Tapped on: ${data.question?.content ?? 'No data'}');
                            qaClicked(data);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(data.question?.content?.data ?? ''),
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

  void qaClicked(Qa? qa) {
    if (qa == null) return;

    if (qa.clicked) {
      return;
    }

    String questionTxt = qa.question?.content?.data ?? "";
    String txtAnswer = qa.content ?? "null";

    var withAutoReplyBuilder = CMessage.WithAutoReply();

    withAutoReplyBuilder.title = questionTxt;
    withAutoReplyBuilder.id = Int64(qa.id ?? 0);
    //withAutoReplyBuilder.createdTime = Utils().getNowTimeStamp();

    widget.listener?.onSendLocalMsg(questionTxt, true);
    // Sending question message
    if (txtAnswer.isNotEmpty) {
      // Auto-reply
      widget.listener?.onSendLocalMsg(txtAnswer, false);
      qa.clicked = true;

      var uAnswer = CMessage.MessageUnion();
      var uQC = CMessage.MessageContent();
      uQC.data = txtAnswer;
      uAnswer.content = uQC;
      withAutoReplyBuilder.answers.add(uAnswer);
    }

    //if (multipAnswer.isNotEmpty) {
    for (var a in qa.answer ?? []) {
      if (a?.image?.uri != null) {
        // Auto-reply with image
        widget.listener?.onSendLocalMsg(a!.image!.uri!, false, "MSG_IMAGE");

        var uAnswer = CMessage.MessageUnion();
        var uQC = CMessage.MessageImage();
        uQC.uri = a.image!.uri!;
        uAnswer.image = uQC;
        withAutoReplyBuilder.answers.add(uAnswer);
      } else if (a?.content?.data != null) {
        widget.listener?.onSendLocalMsg(a?.content?.data ?? "", false);
        var uAnswer = CMessage.MessageUnion();
        var uQC = CMessage.MessageContent();
        uQC.data = txtAnswer;
        uAnswer.content = uQC;
        withAutoReplyBuilder.answers.add(uAnswer);
      }
      qa.clicked = true;
    }
    //}
  }
}
