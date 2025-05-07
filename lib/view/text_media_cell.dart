import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:path_provider/path_provider.dart';
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichatsdk_demo_flutter/util/util.dart';
import 'package:qichatsdk_demo_flutter/vc/FullVideoPlayer.dart';
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

  String content = "";
  String get msgTime => widget.message.metadata?['msgTime'] ?? '';
  String get thumbnailUri => widget.message.metadata?['thumbnailUri'] ?? '';
  final _toolTipController = SuperTooltipController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  _remoteImag() {
    return CachedNetworkImage(
      key: Key(widget.message.remoteId.toString()),
      width: 200,
      height: 150,
      imageUrl: thumbnailUri,
    );
  }

  Widget buildGptMessage(BuildContext context) {
    final isCurrentUser = widget.message.author.id == widget.chatId;
    final hasValidRemoteId = (widget.message.remoteId ?? "").length > 8;

    return SuperTooltip(
      content: buildToolAction(),
      controller: _toolTipController,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blueAccent : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部时间和标题
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msgTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "abc 视频：666666用户推送",
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 视频缩略图和图标
            GestureDetector(
              onLongPress: (Platform.isAndroid || Platform.isIOS) && hasValidRemoteId
                  ? () => _toolTipController.showTooltip()
                  : null,
              onSecondaryTapDown: (details) {
                if (!Platform.isAndroid && !Platform.isIOS && hasValidRemoteId) {
                  _toolTipController.showTooltip();
                }
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Fullvideoplayer(
                      message: widget.message as types.VideoMessage,
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _remoteImag(), // 你应定义该函数返回 Widget
                  Icon(
                    Icons.slow_motion_video_outlined,
                    size: 50.0,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  "【视频】", Int64.parseInt(widget.message.remoteId.toString()));
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
