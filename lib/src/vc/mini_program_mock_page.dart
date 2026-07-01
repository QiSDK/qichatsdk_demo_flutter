import 'package:flutter/material.dart';

import '../model/AppChatTheme.dart';

/// 内置的「小程序页面」模拟页。
///
/// 当卡片带 `jumpUrl`（如 `pages/Withdraw/Record`）而宿主又没有通过
/// [QiChatUISDK.setCardJumpHandler] 注册自己的跳转处理器时，SDK 用本页兜底，
/// 让接入方在没有真实小程序运行时的情况下也能直观看到「跳转」发生。
///
/// 真实接入时，宿主应注册自己的处理器，把 [jumpUrl] 导航到真正的小程序容器 /
/// 原生页 / WebView；本页仅用于演示。
class MiniProgramMockPage extends StatelessWidget {
  final String jumpUrl;
  final int? jumpCategory;
  final AppChatTheme? theme;

  const MiniProgramMockPage({
    super.key,
    required this.jumpUrl,
    this.jumpCategory,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tint = theme?.tintColor ?? Colors.blue;
    final title = _titleFor(jumpUrl);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme?.gradientStartColor ?? tint,
        foregroundColor: theme?.tintColor ?? Colors.white,
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 64, color: tint),
              const SizedBox(height: 16),
              Text(
                '模拟打开小程序页面',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  jumpUrl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
              if (jumpCategory != null) ...[
                const SizedBox(height: 8),
                Text(
                  'jumpCategory：$jumpCategory',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                '这是 SDK 内置的占位页。真实接入时由宿主注册处理器，\n'
                '把此路径导航到真正的小程序 / 原生页 / WebView。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('返回聊天'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 从 `pages/Withdraw/Record` 这类路径粗略取一个可读标题（末段）。
  String _titleFor(String url) {
    final segs = url.split('/').where((s) => s.isNotEmpty).toList();
    return segs.isEmpty ? url : segs.last;
  }
}
