
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichat_ui_sdk/src/Constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullImageView extends StatefulWidget {
  final types.ImageMessage? message;
  final String? url;
  const FullImageView({super.key, this.message, this.url});
  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  late String uri;

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

  init() {
    if (widget.url != null) {
      uri = widget.url ?? "";
    } else {
      uri = widget.message?.uri ?? "";
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
  void dispose() {
    _resetController.dispose();
    super.dispose();
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
          onTap: () => Navigator.of(context).pop(),
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: _remoteImag(),
          ),
        ));
  }

  _remoteImag() {
    return Center(
      child: CachedNetworkImage(
        key: Key(widget.message?.remoteId ?? ""),
        width: MediaQuery.sizeOf(context).width,
        fit: BoxFit.contain,
        imageUrl: uri,
      ),
    );
  }
}
