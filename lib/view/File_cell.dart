import 'dart:math';

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

  // _remoteImag(){
  //   return CachedNetworkImage(
  //     key: Key(widget.message.remoteId.toString()),
  //     fit: BoxFit.contain,
  //     width: 300,
  //     height: 300,
  //     imageUrl: widget.message.uri,
  //   );
  // }

  _localImag() {
    return Image.asset(
      displayFileThumbnail(widget.message.uri),
      fit: BoxFit.contain,
      width: 300,
      height: 300,
    );
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
    return SuperTooltip(
        content: buildToolAction(),
        controller: _toolTipController,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
          color: widget.message.author.id == widget.chatId
              ? Colors.blue
              : Colors.blue.shade100,
          child: _buildFileCell(),
          // Row(
          //   children: [
          //     IconButton(
          //         onPressed: () async {
          //           SmartDialog.showLoading(msg: "正在下载");
          //           var downloaded = await ArticleRepository()
          //               .downloadVideo(widget.message.uri);
          //           SmartDialog.dismiss();
          //           if (downloaded) {
          //             SmartDialog.showToast("下载成功");
          //           } else {
          //             SmartDialog.showToast("下载失败");
          //           }
          //         },
          //         icon: const Icon(Icons.save_alt_sharp,
          //             color: Colors.black, size: 30)),
          //     Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //       Text(
          //         "   " + msgTime,
          //         style: TextStyle(
          //             fontSize: 12,
          //             color: widget.message.author.id == widget.chatId
          //                 ? Colors.white.withOpacity(0.5)
          //                 : Colors.grey),
          //       ),
          //       GestureDetector(
          //         onLongPress: () {
          //           _toolTipController.showTooltip();
          //         },
          //         onTap: () async {
          //           var googleDocsUrl =
          //               "https://docs.google.com/gview?embedded=true&url=${widget.message.uri}";
          //           _launchInWebView(Uri.parse(googleDocsUrl));

          //           //_launchUrl(widget.message.uri);
          //           // Navigator.push(
          //           //     context,
          //           //     MaterialPageRoute( builder: (context) => FullImageWebView(message: widget.message)));
          //         },
          //         child: _localImag(),
          //       ),
          //     ])
          //   ],
          // )
        ));
  }

  _buildFileCell() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Image.asset(
            displayFileThumbnail(widget.message.uri),
            width: 40,
            height: 40,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.message.name),
              // 转kb或者M
              Text(_formatFileSize(widget.message.size.toInt())),
            ],
          )
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";

    final units = ["B", "KB", "MB", "GB", "TB"];
    int digitGroups = (log(bytes) / log(1024)).floor();

    // 限制在可用单位范围内
    digitGroups =
        digitGroups > units.length - 1 ? units.length - 1 : digitGroups;

    // 保留两位小数并移除末尾的0
    String size = (bytes / pow(1024, digitGroups)).toStringAsFixed(2);
    if (size.endsWith('.00')) {
      size = size.substring(0, size.length - 3);
    } else if (size.endsWith('0')) {
      size = size.substring(0, size.length - 1);
    }

    return "$size ${units[digitGroups]}";
  }

  buildToolAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
            onPressed: () {
              widget.listener.onReply(
                  "图片", Int64.parseInt(widget.message.remoteId.toString()));
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

  String displayFileThumbnail(String path) {
    // Extract the file extension
    String ext = path.split('.').last.toLowerCase();
    // Default icon for unknown file types
    var fileIcon = 'assets/png/unknown_default.png';
    // Determine the icon based on the file extension
    if (ext == 'pdf') {
      fileIcon = 'assets/png/pdf_default.png';
    } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
      fileIcon = 'assets/png/excel_default.png';
    } else if (ext == 'doc' || ext == 'docx') {
      fileIcon = 'assets/png/word_default.png';
    }

    return fileIcon;
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
