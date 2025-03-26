
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:qichatsdk_demo_flutter/article_repository.dart';
import 'package:fixnum/src/int64.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/MessageItemOperateListener.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:typed_data';
import 'package:macos_webview_kit/macos_webview_kit.dart';

import '../util/util.dart';

class FileCellWidget extends StatefulWidget {
  types.FileMessage message;
  int messageWidth;
  String chatId;
  MessageItemOperateListener listener;
  FileCellWidget(
      {super.key,
      required this.chatId,
      required this.message,
      required this.messageWidth,
      required this.listener});

  @override
  State<FileCellWidget> createState() => _FileCellWidget();
}

class _FileCellWidget extends State<FileCellWidget> {
  types.Status? get state => widget.message.status;
  final _macosWebviewKitPlugin = MacosWebviewKit();
  String get msgTime => widget.message.metadata?['msgTime'] ?? '';
  final _toolTipController = SuperTooltipController();
  Uint8List? thumbnail;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildGptMessage(context);
  }

  buildLoading() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ));
  }

  buildGptMessage(BuildContext context) {
    return
      Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: widget.message.author.id == widget.chatId
              ? Colors.blue
              : Colors.blue.shade100,
          //child: _buildFileCell(),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //
            mainAxisAlignment: MainAxisAlignment.start,
              children: [
        Text(
          textAlign: TextAlign.start, // Aligns text to the right
          "   " + msgTime,
          style: TextStyle(
              fontSize: 12,
              color: widget.message.author.id == widget.chatId
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey),
        ),
        SuperTooltip(
            content: buildToolAction(),
            controller: _toolTipController,
            child:  Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          SmartDialog.showLoading(msg: "正在下载");
                          var downloaded = await ArticleRepository()
                              .downloadVideo(widget.message.uri);
                          SmartDialog.dismiss();
                          if (downloaded) {
                            SmartDialog.showToast("下载成功");
                          } else {
                            SmartDialog.showToast("下载失败");
                          }
                        },
                        icon: const Icon(Icons.save_alt_sharp,
                            color: Colors.black, size: 30)),

                    GestureDetector(
                      onLongPress: ((Platform.isAndroid || Platform.isIOS) && (widget.message.remoteId ?? "").length > 8)
                          ? () => _toolTipController.showTooltip()
                          : null,
                      onSecondaryTapDown: (details) {
                        if (!Platform.isAndroid && !Platform.isIOS && (widget.message.remoteId ?? "").length > 8)  _toolTipController.showTooltip();
                      },
                      onTap: () async {
                        var googleDocsUrl =
                            "https://docs.google.com/gview?embedded=true&url=${widget.message.uri}";
                        _launchInWebView(Uri.parse(googleDocsUrl));

                        //_launchUrl(widget.message.uri);
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute( builder: (context) => FullImageWebView(message: widget.message)));
                      },
                      child: _buildFileCell(),
                    ),

                  ],
                )
            ),]));
  }

  _buildFileCell() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Image.asset(
            Util().displayFileThumbnail(widget.message.uri),
            width: 40,
            height: 40,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.message.name),
              // 转kb或者M
              Text(Util().formatFileSize(widget.message.size.toInt())),
            ],
          )
        ],
      ),
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
                  "【文件】", Int64.parseInt(widget.message.remoteId.toString()));
              _toolTipController.hideTooltip();
            },
            child: buildRowText(Icons.sms, '回复')),
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

  Future<void> _launchUrl(Uri _url) async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchInBrowserView(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchInWebView(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }
}
