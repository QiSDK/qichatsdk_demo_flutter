import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichat_ui_sdk/src/article_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixnum/src/int64.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:typed_data';
import '../util/util.dart';
import '../vc/FullImageView.dart';

class ImageThumbnailCellWidget extends StatefulWidget {
  types.ImageMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  ImageThumbnailCellWidget(
      {super.key,
        required this.chatId,
        required this.message,
        required this.messageWidth,
        required this.listener});

  @override
  State<ImageThumbnailCellWidget> createState() => _ImageThumbnailCellWidget();
}

class _ImageThumbnailCellWidget extends State<ImageThumbnailCellWidget> {
  types.Status? get state => widget.message.status;

  String get msgTime => Util().formatTimestamp(widget.message.createdAt ?? 0);
  final _toolTipController = SuperTooltipController();
  Uint8List? thumbnail;

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
    final provider = CachedNetworkImageProvider(widget.message.uri);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      final w = info.image.width;
      final h = info.image.height;
      debugPrint('[ImageCell] id=${widget.message.remoteId} '
          'resolved ${w}x$h');
      if (mounted) {
        setState(() => _isLandscape = w >= h);
      }
    }, onError: (e, _) {
      debugPrint('[ImageCell] resolve error: $e');
    });
    stream.addListener(listener);
    _imageStream = stream;
    _imageStreamListener = listener;
  }

  @override
  Widget build(BuildContext context) {
    return buildMessage(context);
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
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        imageUrl: widget.message.uri,
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

  buildMessage(BuildContext context) {
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
                      builder: (context) =>
                          FullImageView(message: widget.message)));
            },
            child: _remoteImag(),
          ),
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
                  "【图片】", Int64.parseInt(widget.message.remoteId.toString()));
              _toolTipController.hideTooltip();
            },
            child: buildRowText(Icons.sms, '回复')),
        TextButton(
            onPressed: () async {
              _toolTipController.hideTooltip();
              SmartDialog.showLoading(msg:"正在下载");
              var downloaded = await ArticleRepository().downloadVideo(widget.message.uri);
              SmartDialog.dismiss();
              if (downloaded){
                SmartDialog.showToast("下载成功");
              }else{
                SmartDialog.showToast("下载失败");
              }
            },
            child: buildRowText(Icons.download_outlined, '下载')),
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
