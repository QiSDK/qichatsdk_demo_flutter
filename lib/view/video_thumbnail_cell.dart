

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
  String get msgTime => widget.message.metadata?['msgTime'] ?? '';
  final _toolTipController = SuperTooltipController();
  Uint8List? thumbnail;

  @override
   void initState() {
    super.initState();
    getThumbnail();
  }

  Future<void> getThumbnail() async {
    if (widget.message is types.VideoMessage){

      if (Platform.isWindows || Platform.isMacOS){
        final data = await rootBundle
            .load('assets/png/defaultthumbnail.jpg'); // replace with your image path
        thumbnail = data.buffer.asUint8List();
      }else {
        var uri = (widget.message as types.VideoMessage).uri;
        var t = await Util().generateThumbnail(uri);
        var f = File(t);
        thumbnail = await f.readAsBytes();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  _localImage() {
    if (thumbnail == null){
      return  CircularProgressIndicator(
        color: Colors.red,
      );
    }else{
      return Image.memory(
        thumbnail!,
        fit: BoxFit.contain,
        width: 300,
        height: 300,
      );
    }
  }

  _remoteImag(){
    return CachedNetworkImage(
      key: Key(widget.message.remoteId.toString()),
      width: 200,
      height: 150,
      imageUrl: content,
    );
  }

  buildGptMessage(BuildContext context) {
    return SuperTooltip(
      content: buildToolAction(),
      controller: _toolTipController,
        child: Container(
            padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
            color: widget.message.author.id == widget.chatId
            ? Colors.blueAccent
            : Colors.blue.shade100, child:   Row( children: [
            IconButton(onPressed: () async {
        SmartDialog.showLoading(msg:"正在下载");

        var downloaded = await ArticleRepository().downloadVideo(widget.message.uri.replaceFirst("master.m3u8", "index.mp4"));
        SmartDialog.dismiss();
        if (downloaded){
        SmartDialog.showToast("下载成功");
        }else{
        SmartDialog.showToast("下载失败");
        }

        }, icon: Icon(Icons.save_alt_sharp, color: Colors.black, size: 30)),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "   " +  msgTime,
                style: TextStyle(
                    fontSize: 12,
                    color: widget.message.author.id == widget.chatId
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey),
              ), GestureDetector(
                  onLongPress: () {
                    _toolTipController.showTooltip();
                  },
                  onTap: ()  {
                    Navigator.push(
                        context,
                        MaterialPageRoute( builder: (context) => Fullvideoplayer(message: widget.message as types.VideoMessage)));
                  },
                  child:
                  Stack(
                      alignment: Alignment.center,
                      children: [
                        _localImage(),
                        Icon(Icons.slow_motion_video_outlined,
                            size: 50.0,
                            color: Colors.white.withOpacity(0.8))
                      ]
                  )
              ),
            ])])));
  }

  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  "视频", Int64.parseInt(widget.message.remoteId.toString()));
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
