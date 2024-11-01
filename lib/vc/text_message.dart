import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TextMessageWidget extends StatefulWidget {
  types.TextMessage message;
  int messageWidth;
  TextMessageWidget({
    super.key,
    required this.message,
    required this.messageWidth,
  });

  @override
  State<TextMessageWidget> createState() => _TextMessageWidgetState();
}

class _TextMessageWidgetState extends State<TextMessageWidget> {
  types.Status? get state => widget.message.status;

  String get content => widget.message.text;
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
    if (state != null && state == types.Status.sending) {
      return buildLoading();
    }
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
        color:
            widget.message.author.id == 'user' ? Colors.white : Colors.black);
    if (content == 'autoReplay' && widget.message.metadata != null) {
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
                List<Related> relatedList = qa.related ?? [];
                return ExpansionPanel(
                    backgroundColor: bgColor,
                    isExpanded: qa.isExpanded ?? false,
                    headerBuilder: (ctx, val) {
                      return Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    width: 1,
                                    color: Colors.white.withOpacity(0.3)))),
                        child: Text(qa.question?.content?.data ?? ""),
                      );
                    },
                    body: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(relatedList.length, (i) {
                          Related data = relatedList[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(data.question?.content?.data ?? ''),
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
    if (widget.message.type == types.MessageType.image) {
      return CachedNetworkImage(
        key: Key(widget.message.text),
        width: 200,
        height: 150,
        imageUrl: widget.message.text,
      );
    }
    return Container(
      color: widget.message.author.id == 'user'
          ? Colors.blue
          : Colors.blue.shade100,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        content,
        style: textStyle,
      ),
    );
  }
}
