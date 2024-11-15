import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/src/int64.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

typedef SubmittedAction = void Function(String val);

class ChatCustomBottom extends StatefulWidget {
  SubmittedAction onSubmitted;
  Function(String, bool) onUploadSuccess;

  ChatCustomBottom({
    super.key,
    required this.onSubmitted,
    required this.onUploadSuccess,
  });

  @override
  State<StatefulWidget> createState() => ChatCustomBottomState();
}

class ChatCustomBottomState extends State<ChatCustomBottom>
    with TickerProviderStateMixin {
  late FocusNode focusNode = FocusNode();
  late TextEditingController inputController = TextEditingController();
  var lastWords = '';
  BoxDecoration boxDecoration = const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16), topRight: Radius.circular(16)),
  );
  void Function(void Function())? setDialogState;
  String replyText = '';
  Int64 replyId = Int64();
  final ImagePicker picker = ImagePicker();
  bool _emojiShowing = false;
  final emojiEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    inputController.text = lastWords;
    focusNode.addListener(
      () {},
    );
    inputController.addListener(() {
      lastWords = inputController.text.toString();
    });
  }

  showReply(String val, Int64 id) {
    setState(() {
      replyText = val;
      replyId = id;
    });
  }

  hideReply() {
    setState(() {
      replyText = '';
      replyId = Int64(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        replyText.isEmpty ? Container() : _initReply(),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          color: Colors.blue.shade100,
          child: buildInput(),
        ),
        !_emojiShowing
            ? Container()
            : EmojiPicker(
                onEmojiSelected: (category, Emoji emoji) {
                  // Do something when emoji is tapped (optional)
                  setState(() {
                    inputController.text = inputController.text + emoji.emoji;
                  });
                },
                onBackspacePressed: () {
                  // Do something when the user taps the backspace button (optional)
                  // Set it to null to hide the Backspace-Button
                  setState(() {
                    if (inputController.text.isNotEmpty) {
                      // Check if the last character is an emoji or other multi-code-unit character
                      String currentText = inputController.text;

                      // Try to safely remove the last emoji or character (multi-unit or single unit)
                      if (currentText.length > 1 &&
                          currentText.codeUnitAt(currentText.length - 1) >
                              0xd7ff) {
                        // It's an emoji or multi-unit character
                        inputController.text = currentText.substring(
                            0,
                            currentText.length -
                                2); // Remove last emoji (2 Unicode units)
                      } else {
                        // Remove a single character (normal character)
                        inputController.text =
                            currentText.substring(0, currentText.length - 1);
                      }

                      // Move the cursor to the end after removing the character
                      inputController.selection = TextSelection.fromPosition(
                          TextPosition(offset: inputController.text.length));
                    }
                  });
                },
                textEditingController:
                    emojiEditingController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    // Issue: https://github.com/flutter/flutter/issues/28894
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
                      buttonIconColor: Colors.black),
                ),
              )
      ],
    );
  }

  _initReply() {
    return Container(
      color: Colors.grey.shade200,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text('回复：$replyText'),
    );
  }

  Widget buildInput() {
    inputController.text = lastWords;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: initTextInputWidget(),
          )
        ],
      ),
    );
  }

  initTextInputWidget() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 6, 0),
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                _pickImage();
              },
              icon: const Icon(Icons.photo)),
          IconButton(
              onPressed: () {
                _pickEmoji();
              },
              icon: const Icon(Icons.emoji_emotions)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                focusNode: focusNode,
                controller: inputController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  inputController.clear();
                  widget.onSubmitted(value);
                  hideReply();
                },
              ),
            ),
          ),
          IconButton(
              onPressed: () {
                widget.onSubmitted(inputController.text);
                inputController.clear();
                FocusScope.of(context).unfocus();
                // 放在最后，清空
                hideReply();
              },
              icon: const Icon(
                Icons.send,
                color: Colors.grey,
              ))
        ],
      ),
    );
  }

  _pickEmoji() {
    setState(() {
      _emojiShowing = !_emojiShowing;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _pickImage() async {
    //await picker.pickImage(source: ImageSource.gallery);
    final XFile? photo = await picker.pickMedia();
    var isVideo = true;
    var imageTypes = {
      "tif",
      "tiff",
      "bmp",
      "jpg",
      "jpeg",
      "png",
      "gif",
      "webp",
      "ico",
      "svg"
    };
    var ar = (photo?.name ?? "").split(".");
    if (ar.length > 1) {
      if (imageTypes.contains(ar.last)) {
        isVideo = false;
      }
    } else {
      if (ar[0].isNotEmpty) {
        return SmartDialog.showToast("不能识别的文件");
      }
    }

    if (photo != null) {
      List<int> imageBytes = await photo.readAsBytes();
      Uint8List val = Uint8List.fromList(imageBytes);
      upload(val, isVideo);
    }
  }

  Future<void> upload(Uint8List imgData, bool isVideo) async {
    // 设置URL
    final String apiUrl = '$baseUrlApi/v1/assets/upload/';

    Dio dio = Dio();
    dio.options.headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'multipart/form-data',
      'X-Token': xToken,
    };

    final String fileName = isVideo ? 'file.mp4' : 'file.png';
    final String mimeType = isVideo ? 'video/mp4' : 'image/png';

    // 创建表单数据
    FormData formData = FormData.fromMap({
      'type': 4,
      'myFile': MultipartFile.fromBytes(
        imgData,
        filename: fileName,
      ),
    });

    debugPrint('xToken=$xToken');

    try {
      SmartDialog.showLoading(msg: "上传中");
      final Response response = await dio.post(apiUrl, data: formData,
          onSendProgress: (int sent, int total) {
        debugPrint(
            'Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
      });

      if (response.statusCode == 200) {
        final String filePath = response.data.toString();
        debugPrint(filePath);
        if (filePath.isNotEmpty) {
          widget.onUploadSuccess(filePath, isVideo);
        }
        SmartDialog.dismiss();
        debugPrint('上传成功: $filePath');
      } else {
        debugPrint('上传失败：${response.statusMessage}');
        SmartDialog.dismiss();
      }
    } catch (e) {
      debugPrint('上传失败：$e');
      SmartDialog.dismiss();
    }
  }
}
