import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoMessageWidget extends StatefulWidget {
  final types.VideoMessage message;

  VideoMessageWidget({super.key, required this.message});

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool urlError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('VideoMessageWidget=${widget.message.uri}');
    Uri? uri;
    try {
      uri = Uri.parse(widget.message.uri);
    } catch (e) {
      print(e);
    }
    if (uri != null) {
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      _videoPlayerController.initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: false,
            looping: false,
          );
        });
      });
    } else {
      setState(() {
        urlError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return urlError
        ? Container(
            child: Text('视频加载失败~'),
          )
        : Container(
            padding: EdgeInsets.all(8.0),
            child: _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
                    controller: _chewieController!,
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          );
  }
}
