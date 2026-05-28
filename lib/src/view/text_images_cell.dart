import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:path_provider/path_provider.dart';
import 'package:qichat_ui_sdk/src/Constant.dart';
import 'package:qichat_ui_sdk/src/model/AutoReply.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:qichat_ui_sdk/src/model/TextBody.dart';
import 'package:qichat_ui_sdk/src/util/util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qichat_ui_sdk/src/vc/FullImageView.dart';
import 'package:qichat_ui_sdk/src/vc/FullVideoPlayer.dart';
import 'package:fixnum/src/int64.dart';
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import '../article_repository.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:typed_data';

import '../model/TextImages.dart';

class TextImagesCell extends StatefulWidget {
  types.TextMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  TextImagesCell(
      {super.key,
      required this.chatId,
      required this.message,
      required this.messageWidth,
      required this.listener});

  @override
  State<TextImagesCell> createState() => _text_images_cell();
}

class _text_images_cell extends State<TextImagesCell> {
  types.Status? get state => widget.message.status;

  String get content => widget.message.text;
  String get msgTime => Util().formatTimestamp(widget.message.createdAt ?? 0);
  List<String> mediaUrls = [];
  final _toolTipController = SuperTooltipController();
  bool isVideo = false;
  String msgTxt = '';
  Color? textColor;

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    if (hex == "red") return Colors.red;
    if (hex == "blue") return Colors.blue;
    if (hex == "yellow") return Colors.yellow;
    if (hex == "green") return Colors.green;
    if (hex == "purple") return Colors.purple;
    var h = hex.trim().replaceFirst('#', '').replaceFirst('0x', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  Widget buildGptMessage(BuildContext context) {
    final isCurrentUser = widget.message.author.id == widget.chatId;
    final hasValidRemoteId = (widget.message.remoteId ?? "").length > 8;
    msgTxt = content;
    textColor = null;
    var msgSourceType = widget.message.metadata?["msgSourceType"] ?? "";
    if (content.contains("\"imgs\"")) {
      final jsonData = jsonDecode(content);
      var result = TextImages.fromJson(
        jsonData,
      );
      if ((result.message ?? "").isNotEmpty) {
        msgTxt = result.message ?? "";
      }
        mediaUrls = result.imgs;
    } else if (msgSourceType == "MST_SYSTEM_CUSTOMER" || msgSourceType == "MST_SYSTEM_WORKER") {
      try {
        final jsonData = jsonDecode(content);
        if (jsonData is Map<String, dynamic>) {
          var result = TextBody.fromJson(jsonData);
          if ((result.content ?? "").isNotEmpty) {
            msgTxt = result.content ?? "";
          }
          if ((result.image ?? "").isNotEmpty) {
            mediaUrls = (result.image ?? "").split(";");
          } else if ((result.video ?? "").isNotEmpty) {
            mediaUrls = (result.video ?? "").split(";");
          }
          textColor = _parseHexColor(result.color);
        } else {
          msgTxt = content;
        }
      } catch (_) {
        msgTxt = content;
      }
    }

    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            msgTime,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: widget.messageWidth.toDouble() * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.blue.shade100,
            borderRadius: BorderRadius.only(
              topLeft:
                  isCurrentUser ? const Radius.circular(16) : Radius.zero,
              topRight:
                  isCurrentUser ? Radius.zero : const Radius.circular(16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SuperTooltip(
                  content: buildToolAction(),
                  controller: _toolTipController,
                  popupDirection: TooltipDirection.up,
                  minimumOutsideMargin: 20.0,
                  arrowLength: 10.0,
                  arrowBaseWidth: 15.0,
                  borderRadius: 8.0,
                  constraints: const BoxConstraints(
                    minHeight: 0.0,
                    maxHeight: 50.0,
                    minWidth: 0.0,
                    maxWidth: 50.0,
                  ),
                  child: GestureDetector(
                      onLongPress:
                          (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) &&
                                  hasValidRemoteId
                              ? () => _toolTipController.showTooltip()
                              : null,
                      onSecondaryTapDown: (details) {
                        if (!kIsWeb &&
                            !Platform.isAndroid &&
                            !Platform.isIOS &&
                            hasValidRemoteId) {
                          _toolTipController.showTooltip();
                        }
                      },
                      child: Html(
                        data: msgTxt,
                        shrinkWrap: true,
                        onLinkTap: (url, attributes, element) async {
                          if (url == null) return;
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            color: textColor ??
                                (isCurrentUser ? Colors.white : Colors.black),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "a": Style(
                            color: isCurrentUser
                                ? Colors.white
                                : Colors.blue.shade800,
                            textDecoration: TextDecoration.underline,
                          ),
                        },
                      )),
                ),
                if (mediaUrls.isNotEmpty) const SizedBox(height: 8),
                // 图片网格显示
                mediaUrls.isEmpty
                    ? Container()
                    : Container(
                        constraints: BoxConstraints(
                          maxWidth: widget.messageWidth.toDouble() * 0.8,
                        ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: mediaUrls.length == 1 ? 1 : (mediaUrls.length <= 4 ? 2 : 3),
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: mediaUrls.length,
                        itemBuilder: (context, index) {
                          var ext =
                              mediaUrls[index].split(".").last.toLowerCase();
                          var mediaUrl = baseUrlImage + mediaUrls[index];
                          if (mediaUrls[index].contains("http")) {
                            mediaUrl = mediaUrls[index];
                          }
                          return GestureDetector(
                            onTap: () {
                              if (videoTypes.contains(ext)) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Fullvideoplayer(
                                            videoUrl: mediaUrl)));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullImageView(
                                        url: mediaUrl,
                                      ),
                                    ));
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: videoTypes.contains(ext)
                                  ? Image.asset(
                                      "assets/png/video_default.png",
                                      package: 'qichat_ui_sdk')
                                  : CachedNetworkImage(
                                      imageUrl: mediaUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
      ],
    );
  }

  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  msgTxt, Int64.parseInt(widget.message.remoteId.toString()));
              _toolTipController.hideTooltip();
            },
            child: buildRowText(Icons.sms, '回复')),
        TextButton(
            onPressed: () {
              FlutterClipboard.copy(msgTxt).then((value) {
                _toolTipController.hideTooltip().then((val) {
                  SmartDialog.showToast("已复制到剪切板");
                });
              });
            },
            child: buildRowText(Icons.copy, '复制'))
      ],
    );
  }

  buildRowText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.black54,
          size: 16,
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}
