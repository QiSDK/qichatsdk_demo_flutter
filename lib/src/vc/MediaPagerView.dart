import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../model/MediaItem.dart';
import 'ChatPage.dart';

class MediaPagerView extends StatefulWidget {
  final List<MediaItem>? items;
  final int initialIndex;
  final String? startUrl;

  const MediaPagerView({
    super.key,
    this.items,
    this.initialIndex = 0,
    this.startUrl,
  });

  @override
  State<MediaPagerView> createState() => _MediaPagerViewState();
}

class _MediaPagerViewState extends State<MediaPagerView>
    with SingleTickerProviderStateMixin {
  late List<MediaItem> _items;
  late PageController _pageController;
  late ValueNotifier<int> _currentIndex;

  double _dragOffset = 0;
  late AnimationController _resetController;
  Animation<double>? _resetAnimation;

  static const double _dismissThreshold = 120;
  static const double _fadeDistance = 400;

  @override
  void initState() {
    super.initState();

    final resolved = widget.items ?? ChatPage.currentMediaItems();
    var startIndex = widget.initialIndex;
    if (widget.startUrl != null && widget.startUrl!.isNotEmpty) {
      final i = resolved.indexWhere((m) => m.url == widget.startUrl);
      if (i >= 0) startIndex = i;
    }

    if (resolved.isEmpty && widget.startUrl != null) {
      _items = [MediaItem(url: widget.startUrl!, isVideo: false)];
      startIndex = 0;
    } else {
      _items = resolved;
    }

    if (startIndex < 0) startIndex = 0;
    if (startIndex >= _items.length) startIndex = _items.length - 1;

    _currentIndex = ValueNotifier<int>(startIndex);
    _pageController = PageController(initialPage: startIndex);

    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {
          _dragOffset = _resetAnimation?.value ?? 0;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: ValueListenableBuilder<int>(
          valueListenable: _currentIndex,
          builder: (_, i, __) => Text(
            _items.isEmpty ? '' : '${i + 1} / ${_items.length}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: _items.isEmpty
              ? const Center(
                  child: Text('没有媒体内容',
                      style: TextStyle(color: Colors.white)))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (i) => _currentIndex.value = i,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    if (item.isVideo) {
                      return _VideoPage(
                        url: item.url,
                        index: index,
                        currentIndex: _currentIndex,
                        onTapClose: () => Navigator.of(context).pop(),
                      );
                    }
                    return _ImagePage(
                      url: item.url,
                      onTap: () => Navigator.of(context).pop(),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ImagePage extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  const _ImagePage({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          width: MediaQuery.sizeOf(context).width,
          placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  final String url;
  final int index;
  final ValueNotifier<int> currentIndex;
  final VoidCallback onTapClose;

  const _VideoPage({
    required this.url,
    required this.index,
    required this.currentIndex,
    required this.onTapClose,
  });

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _vpc;
  ChewieController? _chewieController;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    widget.currentIndex.addListener(_syncPlayback);
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      _vpc = c;
      final isActive = widget.currentIndex.value == widget.index;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: c,
          aspectRatio: c.value.aspectRatio,
          autoPlay: isActive,
          looping: true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  void _syncPlayback() {
    if (!mounted || _vpc == null) return;
    if (widget.currentIndex.value == widget.index) {
      _vpc!.play();
    } else {
      _vpc!.pause();
    }
  }

  @override
  void dispose() {
    widget.currentIndex.removeListener(_syncPlayback);
    _chewieController?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Center(
        child: Text('视频加载失败~', style: TextStyle(color: Colors.white)),
      );
    }
    if (_chewieController == null ||
        _vpc?.value.isInitialized != true) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Chewie(controller: _chewieController!),
    );
  }
}
