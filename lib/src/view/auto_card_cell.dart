import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../Constant.dart';
import '../model/AppChatTheme.dart';
import '../model/MessageItemOperateListener.dart';
import '../model/ServiceKeyword.dart';
import '../util/util.dart';

/// 渲染 `msgSourceType == MST_AUTO_CARD` 的卡片消息。
///
/// 消息体（[types.TextMessage.text]）是一条 [ServiceKeyword] 的 JSON：
/// - 标题 = `subject`；
/// - `content` 为数组（questionType 1）→ 渲染成一组可点选项按钮；
/// - `content` 为字符串（questionType 2）→ 渲染成正文段落 + 一个按钮。
///
/// 点击任一按钮时通过 [MessageItemOperateListener.onSendCardOption] 把选项文本
/// 当普通消息发送。
class AutoCardCell extends StatelessWidget {
  final types.TextMessage message;
  final int messageWidth;
  final String chatId;
  final MessageItemOperateListener listener;
  final AppChatTheme? theme;

  const AutoCardCell({
    super.key,
    required this.chatId,
    required this.message,
    required this.messageWidth,
    required this.listener,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final msgTime = Util().formatTimestamp(message.createdAt ?? 0);

    ServiceKeyword? card;
    try {
      final data = jsonDecode(message.text);
      if (data is Map<String, dynamic>) card = ServiceKeyword.fromJson(data);
    } catch (_) {
      card = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            msgTime,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: messageWidth.toDouble() * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: theme?.leftBubbleColor ?? Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: card == null
              ? Text(message.text)
              : _buildCard(card),
        ),
      ],
    );
  }

  Widget _buildCard(ServiceKeyword card) {
    final tint = theme?.tintColor ?? Colors.blue;
    final titleColor = theme?.leftBubbleTextColor ?? Colors.black87;
    final options = card.options;
    final body = card.contentText;
    final imageUrl = (card.rightImageUrl ?? '').trim();

    // 标题 + 正文列（左侧）。
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((card.subject ?? '').isNotEmpty)
          Text(
            card.subject!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.4,
            ),
          ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(fontSize: 13, color: tint, height: 1.4),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 精准问题可带右侧配图（rightImageUrl）；无图则整行只有文字。
        if (imageUrl.isEmpty)
          textColumn
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textColumn),
              const SizedBox(width: 10),
              _rightImage(imageUrl),
            ],
          ),
        const SizedBox(height: 4),
        // questionType 1：每个选项一个按钮。
        ...options.map((opt) => _optionButton(label: opt, tint: tint,
            onPressed: () => listener.onSendCardOption(opt))),
        // questionType 2：无选项数组时给一个按钮。
        // hasJump（jumpCategory 非 0 且 jumpUrl 非空）→ 请求跳转；
        // 否则回退成发送 subject 文本。
        if (options.isEmpty && (card.subject ?? '').isNotEmpty)
          card.hasJump
              ? _optionButton(
                  label: card.subject!,
                  tint: tint,
                  onPressed: () =>
                      listener.onCardJump(card.jumpUrl!, card.jumpCategory),
                )
              : _optionButton(
                  label: card.subject!,
                  tint: tint,
                  onPressed: () => listener.onSendCardOption(card.subject!),
                ),
      ],
    );
  }

  /// 右侧配图。绝对 URL 直接用；相对路径按 SDK 图片 CDN 前缀补全。
  /// 加载失败静默隐藏，不影响卡片其余内容。
  Widget _rightImage(String url) {
    final full = url.startsWith('http') ? url : '$baseUrlImage$url';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: full,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
        placeholder: (_, __) => const SizedBox(width: 64, height: 64),
      ),
    );
  }

  Widget _optionButton({
    required String label,
    required Color tint,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tint,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
