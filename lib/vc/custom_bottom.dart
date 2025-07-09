
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:fixnum/src/int64.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:file_picker/file_picker.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';

//import '../model/UploadPercent.dart';

typedef SubmittedAction = void Function(String val);

class ChatCustomBottom extends StatefulWidget {
  SubmittedAction onSubmitted;
  Function(Urls) onUploaded;
  ChatCustomBottom({
    super.key,
    required this.onSubmitted,
    required this.onUploaded
  });

  @override
  State<StatefulWidget> createState() => ChatCustomBottomState();
}

class ChatCustomBottomState extends State<ChatCustomBottom>
    with TickerProviderStateMixin implements UploadListener{
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
      child: Row(
        children: [
         Text('回复：$replyText'),
          IconButton(onPressed: (){
            hideReply();
          }, icon: Icon(Icons.close, color: Colors.blue, size: 20))
        ],
      )
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
                setState(() {
                  _emojiShowing = false;
                });
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
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) {
      result;
    } else {
    }

    XFile photo = result!.files.first.xFile;
    var ar = (photo?.name ?? "").split(".");
    if (ar.length < 2) {
      return SmartDialog.showToast("不能识别的文件");
    }
    if (photo != null) {
      List<int> imageBytes = await photo.readAsBytes();
      Uint8List val = Uint8List.fromList(imageBytes);
      UploadUtil(this, xToken, baseUrlApi()).upload(val, photo.path);
    }
  }

  @override
  void uploadFailed(String msg) {
    SmartDialog.showToast(msg);
    uploadProgress = 0;
  }

  @override
  void updateProgress(int progress) {
    SmartDialog.showLoading(msg:"正在上传 ${progress}%");
  }

  @override
  void uploadSuccess(Urls urls){
    uploadProgress = 0;
    widget.onUploaded(urls);
    SmartDialog.dismiss();
  }
}
