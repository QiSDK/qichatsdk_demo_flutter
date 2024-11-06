
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:qichatsdk_demo_flutter/util/util.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/src/int64.dart';

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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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

  @override
  void dispose() {
    super.dispose();
  }

  _pickImage() async {
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      List<int> imageBytes = await photo.readAsBytes();
      Uint8List val = Uint8List.fromList(imageBytes);
      upload(val, false);
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
      final Response response = await dio.post(apiUrl, data: formData,
          onSendProgress: (int sent, int total) {
        debugPrint(
            'Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
      });

      if (response.statusCode == 200) {
        final String filePath = response.data.toString();
        debugPrint(filePath);
        if (filePath.isNotEmpty) {
          widget.onUploadSuccess(baseUrlImage + filePath, isVideo);
        }
        debugPrint('上传成功: $filePath');
      } else {
        debugPrint('上传失败：${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('上传失败：$e');
    }
  }
}
