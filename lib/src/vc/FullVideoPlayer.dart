
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:video_player/video_player.dart';
//import 'package:video_player_win/video_player_win.dart' as winVideoPlayer;

class Fullvideoplayer extends StatefulWidget {
  final types.VideoMessage? message;
  final String? videoUrl;
  const Fullvideoplayer({super.key, this.message, this.videoUrl});

  @override
  State<Fullvideoplayer> createState() => _FullvideoplayerState();
}

class _FullvideoplayerState extends State<Fullvideoplayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool urlError = false;

  double _dragOffset = 0;
  late AnimationController _resetController;
  Animation<double>? _resetAnimation;

  static const double _dismissThreshold = 120;
  static const double _fadeDistance = 400;

  @override
  void initState() {
    super.initState();

    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {
          _dragOffset = _resetAnimation?.value ?? 0;
        });
      });

    init();
  }

  init() async {
    Uri? uri;
    try {

      if ((widget.message?.uri ?? "").length > 0){
        uri = Uri.parse(widget.message?.uri ?? "");
      }else{
        uri = Uri.parse(widget.videoUrl ?? "");
      }

      print("视频地址:${uri}");
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

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset =
          (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > _dismissThreshold) {
      Navigator.of(context).pop();
    } else {
      _resetAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeOut));
      _resetController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgOpacity = (1 - (_dragOffset / _fadeDistance)).clamp(0.0, 1.0);
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(bgOpacity),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            '客服',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        body: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: _initBody(),
          ),
        ));
  }

   _initBody(){
    return urlError
        ? Center(
      child: Text(
        '视频加载失败~',
        style: TextStyle(color: Colors.white),
      ),
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
    _resetController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
