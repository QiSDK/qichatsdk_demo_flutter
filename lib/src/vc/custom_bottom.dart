import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fixnum/src/int64.dart';
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qichat_ui_sdk/src/Constant.dart';
import 'package:qichat_ui_sdk/src/vc/camera_page.dart';

import '../api/qichat_ui_sdk.dart';

typedef SubmittedAction = void Function(String val);

class ChatCustomBottom extends StatefulWidget {
  final SubmittedAction onSubmitted;
  final Function(Urls) onUploaded;
  final Function(int)? onProgress;

  /// 任何「占用底部」的子组件出现/消失时回调。
  /// 父级可据此隐藏悬浮在底部的 UI（如客服评价按钮），避免遮挡。
  /// 触发条件：emoji 面板 / 功能面板 / 回复条 任一可见即视为 expanded=true。
  final ValueChanged<bool>? onExpandedChanged;

  const ChatCustomBottom({
    super.key,
    required this.onSubmitted,
    required this.onUploaded,
    this.onProgress,
    this.onExpandedChanged,
  });

  @override
  State<StatefulWidget> createState() => ChatCustomBottomState();
}

class ChatCustomBottomState extends State<ChatCustomBottom>
    with TickerProviderStateMixin
    implements UploadListener {
  late final FocusNode focusNode = FocusNode();
  late final TextEditingController inputController = TextEditingController();
  String _lastWords = '';

  String replyText = '';
  Int64 replyId = Int64();

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _emojiEditingController = TextEditingController();

  bool _emojiShowing = false;
  bool _panelShowing = false;
  bool _isFilePickerShowing = false;
  bool _wasExpanded = false;

  static const String _svgPkg = 'qichat_ui_sdk';

  @override
  void initState() {
    super.initState();
    inputController.text = _lastWords;
    inputController.addListener(() {
      _lastWords = inputController.text;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    inputController.dispose();
    _emojiEditingController.dispose();
    super.dispose();
  }

  void _notifyExpanded() {
    final now = _emojiShowing || _panelShowing || replyText.isNotEmpty;
    if (now != _wasExpanded) {
      _wasExpanded = now;
      widget.onExpandedChanged?.call(now);
    }
  }

  void showReply(String val, Int64 id) {
    setState(() {
      replyText = val;
      replyId = id;
    });
    _notifyExpanded();
  }

  void hideReply() {
    setState(() {
      replyText = '';
      replyId = Int64(0);
    });
    _notifyExpanded();
  }

  void _togglePanel() {
    setState(() {
      _panelShowing = !_panelShowing;
      if (_panelShowing) _emojiShowing = false;
    });
    if (_panelShowing) {
      FocusScope.of(context).unfocus();
    }
    _notifyExpanded();
  }

  void _toggleEmoji() {
    setState(() {
      _emojiShowing = !_emojiShowing;
      if (_emojiShowing) _panelShowing = false;
    });
    if (_emojiShowing) {
      FocusScope.of(context).unfocus();
    }
    _notifyExpanded();
  }

  void _submit() {
    final text = inputController.text;
    inputController.clear();
    widget.onSubmitted(text);
    hideReply();
    setState(() {
      _emojiShowing = false;
      _panelShowing = false;
    });
    _notifyExpanded();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyText.isNotEmpty) _buildReplyBar(),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _buildInputRow(),
          ),
          if (_panelShowing) _buildActionPanel(),
          if (_emojiShowing) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '回复：$replyText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: hideReply,
            icon: const Icon(Icons.close, color: Colors.blue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              focusNode: focusNode,
              controller: inputController,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '说点什么吧',
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFFB0B0B0)),
              ),
              textInputAction: TextInputAction.send,
              onTap: () {
                if (_panelShowing || _emojiShowing) {
                  setState(() {
                    _panelShowing = false;
                    _emojiShowing = false;
                  });
                  _notifyExpanded();
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(
          asset: 'assets/svg/biaoqing.svg',
          onTap: _toggleEmoji,
        ),
        const SizedBox(width: 4),
        _IconBtn(
          asset: _panelShowing
              ? 'assets/svg/gengduo_0.svg'
              : 'assets/svg/gengduo_1.svg',
          onTap: _togglePanel,
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          _PanelAction(
            label: '图片',
            icon: SvgPicture.asset(
              'assets/svg/tupianxiazai.svg',
              package: _svgPkg,
              width: 28,
              height: 28,
            ),
            onTap: _onPickImageTap,
          ),
          _PanelAction(
            label: '视频',
            icon: const Icon(
              Icons.movie_outlined,
              size: 28,
              color: Color(0xFF333333),
            ),
            onTap: _onPickVideoTap,
          ),
          _PanelAction(
            label: '设备信息',
            icon: const Icon(
              Icons.phone_iphone,
              size: 28,
              color: Color(0xFF333333),
            ),
            onTap: _onDeviceInfoTap,
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, Emoji emoji) {
        setState(() {
          inputController.text = inputController.text + emoji.emoji;
        });
      },
      onBackspacePressed: () {
        setState(() {
          final text = inputController.text;
          if (text.isEmpty) return;
          if (text.length > 1 &&
              text.codeUnitAt(text.length - 1) > 0xd7ff) {
            inputController.text = text.substring(0, text.length - 2);
          } else {
            inputController.text = text.substring(0, text.length - 1);
          }
          inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: inputController.text.length),
          );
        });
      },
      textEditingController: _emojiEditingController,
      config: Config(
        height: 256,
        checkPlatformCompatibility: true,
        emojiViewConfig: EmojiViewConfig(
          emojiSizeMax: 28 *
              (foundation.defaultTargetPlatform == TargetPlatform.iOS
                  ? 1.20
                  : 1.0),
        ),
        swapCategoryAndBottomBar: false,
        skinToneConfig: const SkinToneConfig(),
        categoryViewConfig: const CategoryViewConfig(),
        bottomActionBarConfig: BottomActionBarConfig(
          showSearchViewButton: false,
          backgroundColor: Colors.grey.shade300,
          buttonIconColor: Colors.black,
        ),
      ),
    );
  }

  Future<void> _onPickImageTap() async {
    // Web / 桌面没有拍照，直接走文件选择
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      await _pickImageOrVideoFromFiles(false);
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('相册'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'camera') {
      final XFile? path = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
      if (path != null) _doUpload(path);
    } else if (choice == 'gallery') {
      await _pickFromGallery(false);
    }
  }

  Future<void> _onPickVideoTap() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      await _pickImageOrVideoFromFiles(true);
      return;
    }
    await _pickFromGallery(true);
  }

  void _onDeviceInfoTap() {
    setState(() => _panelShowing = false);
    _notifyExpanded();
    QiChatUISDK.openDeviceInfo(context);
  }

  Future<void> _pickFromGallery(bool isVideo) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    UploadUtil(this, xToken, baseUrlApi())
        .upload(Uint8List.fromList(bytes), file.path);
  }

  Future<void> _pickImageOrVideoFromFiles(bool isVideo) async {
    if (_isFilePickerShowing) return;
    _isFilePickerShowing = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isVideo
            ? ['mp4', 'mov', 'avi', 'mkv', 'flv']
            : ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
      );
      if (result == null || result.files.isEmpty) return;
      _doUpload(result.files.first.xFile);
    } catch (e) {
      SmartDialog.showToast('选择文件失败: $e');
    } finally {
      _isFilePickerShowing = false;
    }
  }

  Future<void> _doUpload(XFile photo) async {
    SmartDialog.showLoading(msg: '开始上传。。。');
    final ar = (photo.name).split('.');
    if (ar.length < 2) {
      SmartDialog.dismiss();
      SmartDialog.showToast('不能识别的文件');
      return;
    }
    final imageBytes = await photo.readAsBytes();
    final val = Uint8List.fromList(imageBytes);
    final pathOrName = kIsWeb ? photo.name : photo.path;
    UploadUtil(this, xToken, baseUrlApi()).upload(val, pathOrName);
  }

  @override
  void uploadFailed(String msg) {
    SmartDialog.dismiss();
    SmartDialog.showToast(msg);
    uploadProgress = 0;
  }

  @override
  void updateProgress(int progress) {
    widget.onProgress?.call(progress);
    SmartDialog.showLoading(msg: '正在上传 $progress%');
  }

  @override
  void uploadSuccess(Urls urls) {
    uploadProgress = 0;
    widget.onUploaded(urls);
    SmartDialog.dismiss();
  }
}

class _IconBtn extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _IconBtn({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SvgPicture.asset(
          asset,
          package: 'qichat_ui_sdk',
          width: 26,
          height: 26,
        ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _PanelAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
