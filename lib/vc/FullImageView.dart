
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullImageView extends StatefulWidget {
  final types.ImageMessage? message;
  final String? url;
  const FullImageView({super.key, required this.message, this.url});
  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late final WebViewController _controller;
  late String uri;
  @override
  void initState() {
    super.initState();


    init();
  }

  init() {
    if (widget.url != null){
      uri = widget.url ?? "";
    }else{
      uri = widget.message?.uri ?? "";
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
        body: _remoteImag());
  }

  _remoteImag() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
        child: CachedNetworkImage(
          key: Key(widget.message?.remoteId ?? ""),
          width: MediaQuery
              .sizeOf(context)
              .width,
          fit: BoxFit.cover,
          imageUrl: uri,
        ),
    );
  }
}