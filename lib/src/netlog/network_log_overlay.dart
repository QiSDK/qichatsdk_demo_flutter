import 'package:flutter/material.dart';

import 'network_log_page.dart';

/// 网络日志悬浮按钮 - 与 Android/iOS `NetworkLogFloatingButton` 对齐。
/// 用 [OverlayEntry] 在最上层显示一个可拖动的圆形按钮，点击打开 [NetworkLogPage]。
class NetworkLogOverlay {
  NetworkLogOverlay._();

  static OverlayEntry? _entry;

  /// 显示悬浮按钮。[context] 需处于 App 的 [Navigator]/[Overlay] 之下（通常是首页 context）。幂等。
  static void show(BuildContext context) {
    if (_entry != null) return;
    // 按钮插进最顶层 overlay 保证可见；但根 overlay（可能是 SmartDialog 的）不在
    // Navigator 之下，点击跳转要用调用方 context 里的 Navigator，二者分开取。
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (overlay == null || navigator == null) return;
    final entry = OverlayEntry(
      builder: (_) => _DraggableLogButton(
        onTap: () {
          navigator.push(
            MaterialPageRoute(builder: (_) => const NetworkLogPage()),
          );
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// 隐藏悬浮按钮。幂等。
  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _DraggableLogButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DraggableLogButton({required this.onTap});

  @override
  State<_DraggableLogButton> createState() => _DraggableLogButtonState();
}

class _DraggableLogButtonState extends State<_DraggableLogButton> {
  static const double _size = 50;
  Offset? _pos; // 左上角坐标，null 表示用默认位置

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    // 默认停靠：右侧、竖直 65% 处
    final pos = _pos ??
        Offset(screen.width - _size - 16, screen.height * 0.65);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          final next = pos + d.delta;
          setState(() {
            _pos = Offset(
              next.dx.clamp(0.0, screen.width - _size),
              next.dy.clamp(
                media.padding.top,
                screen.height - _size - media.padding.bottom,
              ),
            );
          });
        },
        onTap: widget.onTap,
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            color: Color(0xD92196F3), // systemBlue @ 0.85
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('日志',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }
}
