
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:video_player/video_player.dart';
//import 'package:video_player_win/video_player_win.dart' as winVideoPlayer;

class Fullvideoplayer extends StatefulWidget {
  final types.VideoMessage message;
  const Fullvideoplayer({super.key, required this.message});

  @override
  State<Fullvideoplayer> createState() => _FullvideoplayerState();
}

class _FullvideoplayerState extends State<Fullvideoplayer> {

  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool urlError = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    Uri? uri;
    try {

      uri = Uri.parse(widget.message.uri);
      print("视频地址:${widget.message.uri}");
      //uri = Uri.parse("https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8");
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      await _videoPlayerController.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: true,
          looping: true,
        );
      });
    } catch (e) {
      print(e);
      setState(() {
        urlError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFf8f8f8),
        appBar: AppBar(
          title: const Text(
            '客服',
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: _initBody());
  }

   _initBody(){
    return urlError
        ? Container(
      child: Text('视频加载失败~'),
    )
        : Container(
      padding: EdgeInsets.all(8.0),
      child: _chewieController != null &&
          _chewieController
              ?.videoPlayerController.value.isInitialized ==
              true
          ? Chewie(
        controller: _chewieController!,
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}