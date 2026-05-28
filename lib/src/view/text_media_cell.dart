import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:path_provider/path_provider.dart';
import 'package:qichat_ui_sdk/src/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichat_ui_sdk/src/model/TextBody.dart';
import 'package:qichat_ui_sdk/src/util/util.dart';
import 'package:qichat_ui_sdk/src/vc/MediaPagerView.dart';
import 'package:fixnum/src/int64.dart';
import '../article_repository.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:typed_data';

class TextMediaCell extends StatefulWidget {
  types.TextMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  TextMediaCell(
      {super.key,
      required this.chatId,
      required this.message,
      required this.messageWidth,
      required this.listener});

  @override
  State<TextMediaCell> createState() => _text_media_cell();
}

class _text_media_cell extends State<TextMediaCell> {
  types.Status? get state => widget.message.status;

  String get content => widget.message.text;
  String get msgTime => Util().formatTimestamp(widget.message.createdAt ?? 0);
  String mediaUrl = '';
  final _toolTipController = SuperTooltipController();
  bool isVideo = false;
  String msgTxt = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  Widget buildGptMessage(BuildContext context) {
    final isCurrentUser = widget.message.author.id == widget.chatId;
    final hasValidRemoteId = (widget.message.remoteId ?? "").length > 8;
    msgTxt = content;
    var msgSourceType = widget.message.metadata?["msgSourceType"] ?? "";
    if (msgSourceType == "MST_SYSTEM_CUSTOMER" || msgSourceType == "MST_SYSTEM_WORKER") {
      final jsonData = jsonDecode(content);
      var result = TextBody.fromJson(
        jsonData,
      );
      if ((result.content ?? "").isNotEmpty) {
        msgTxt = result.content ?? "";
      }
      if ((result.image ?? "").isNotEmpty) {
        mediaUrl = result.image ?? "";
      }
      if ((result.video ?? "").isNotEmpty) {
        mediaUrl = (result.video ?? "").trim();
        isVideo = true;
      }
    }

    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            msgTime,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        SuperTooltip(
          content: buildToolAction(),
          controller: _toolTipController,
          child: GestureDetector(
            onLongPress:
                (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) && hasValidRemoteId
                    ? () => _toolTipController.showTooltip()
                    : null,
            onSecondaryTapDown: (details) {
              if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS && hasValidRemoteId) {
                _toolTipController.showTooltip();
              }
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaPagerView(startUrl: mediaUrl),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : Colors.blue.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: isCurrentUser
                      ? const Radius.circular(16)
                      : Radius.zero,
                  topRight: isCurrentUser
                      ? Radius.zero
                      : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msgTxt,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 视频缩略图和图标
                  mediaUrl.isEmpty
                      ? Container()
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            _remoteImag(),
                            isVideo
                                ? Icon(
                                    Icons.slow_motion_video_outlined,
                                    size: 50.0,
                                    color: Colors.white.withOpacity(0.8),
                                  )
                                : Container(),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _remoteImag() {
    if (isVideo) {
      // var file = Image.asset("name").image
      return Image.asset(
        'assets/png/video_default.png',
        package: 'qichat_ui_sdk',
        fit: BoxFit.contain,
        width: 300,
        height: 300,
      );
    } else {
      return CachedNetworkImage(
        key: Key(widget.message.remoteId.toString()),
        width: 200,
        height: 150,
        imageUrl: mediaUrl,
      );
    }
  }

  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  msgTxt, Int64.parseInt(widget.message.remoteId.toString()));
              _toolTipController.hideTooltip();
            },
            child: buildRowText(Icons.sms, '回复')),
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
}
