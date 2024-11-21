
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:webview_flutter/webview_flutter.dart';

class FullImageView extends StatefulWidget {
  final types.ImageMessage message;
  const FullImageView({super.key, required this.message});

  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late final WebViewController _controller;
  @override
  void initState() {
    super.initState();


    init();
  }

  init()  {

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
        body: _remoteImag());
  }

  _remoteImag(){
    return CachedNetworkImage(
      key: Key(widget.message.remoteId.toString()),
      width: MediaQuery.sizeOf(context).width,
      fit: BoxFit.cover,
      imageUrl: widget.message.uri,
    );
  }
}