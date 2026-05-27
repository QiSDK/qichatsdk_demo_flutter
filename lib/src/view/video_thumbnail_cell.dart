

import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:path_provider/path_provider.dart';
import 'package:qichat_ui_sdk/src/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qichat_ui_sdk/src/util/util.dart';
import 'package:qichat_ui_sdk/src/vc/FullVideoPlayer.dart';
import 'package:fixnum/src/int64.dart';
import '../article_repository.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:typed_data';

class VideoThumbnailCellWidget extends StatefulWidget {
  types.VideoMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  VideoThumbnailCellWidget(
      {super.key,
        required this.chatId,
        required this.message,
        required this.messageWidth,
        required this.listener});

  @override
  State<VideoThumbnailCellWidget> createState() => _VideoThumbnailCellWidget();
}

class _VideoThumbnailCellWidget extends State<VideoThumbnailCellWidget> {
  types.Status? get state => widget.message.status;

  String content = "";
  String get msgTime => Util().formatTimestamp(widget.message.createdAt ?? 0);
  String get thumbnailUri => widget.message.metadata?['thumbnailUri'] ?? '';
  final _toolTipController = SuperTooltipController();

  bool? _isLandscape;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _resolveOrientation();
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  void _resolveOrientation() {
    if (thumbnailUri.isEmpty) return;
    final provider = CachedNetworkImageProvider(thumbnailUri);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      final w = info.image.width;
      final h = info.image.height;
      debugPrint('[VideoCell] id=${widget.message.remoteId} '
          'resolved ${w}x$h');
      if (mounted) {
        setState(() => _isLandscape = w >= h);
      }
    }, onError: (e, _) {
      debugPrint('[VideoCell] resolve error: $e');
    });
    stream.addListener(listener);
    _imageStream = stream;
    _imageStreamListener = listener;
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  Size _calculateSize() {
    const landscape = Size(214, 120);
    const portrait = Size(120, 214);
    if (_isLandscape == null) return landscape;
    return _isLandscape! ? landscape : portrait;
  }

  _remoteImag(){
    final size = _calculateSize();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        key: Key(widget.message.remoteId.toString()),
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        imageUrl: thumbnailUri,
      ),
    );
  }

  buildGptMessage(BuildContext context) {
    final isCurrentUser = widget.message.author.id == widget.chatId;
    final hasValidRemoteId = (widget.message.remoteId ?? "").length > 8;
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
              onLongPress: (!kIsWeb &&
                          (Platform.isAndroid || Platform.isIOS)) &&
                      hasValidRemoteId
                  ? () => _toolTipController.showTooltip()
                  : null,
              onSecondaryTapDown: (details) {
                if (!kIsWeb &&
                    !Platform.isAndroid &&
                    !Platform.isIOS &&
                    hasValidRemoteId) {
                  _toolTipController.showTooltip();
                }
              },
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Fullvideoplayer(
                            message:
                                widget.message as types.VideoMessage)));
              },
              child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _remoteImag(),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          size: 36, color: Colors.white),
                    ),
                  ])),
        ),
      ],
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
        TextButton(onPressed: () async {
          SmartDialog.showLoading(msg:"正在下载");
          var downloaded = await ArticleRepository().downloadVideo(widget.message.uri.replaceFirst("master.m3u8", "index.mp4"));
          SmartDialog.dismiss();
          if (downloaded){
            final onMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
            SmartDialog.showToast(onMobile ? "已保存到相册" : "下载成功");
          }else{
            SmartDialog.showToast("下载失败");
          }
        }, child: buildRowText(Icons.download_outlined, '下载'))
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
