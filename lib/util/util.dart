import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class Util {
  static Future<String?> xFileToBase64(XFile xFile) async {
    try {
      // 读取文件字节
      File file = File(xFile.path);
      if (kDebugMode) {
        print('图片大小${file.readAsBytesSync().lengthInBytes / 1024 / 1024}');
      }

      List<int> imageBytes = await file.readAsBytes();

      // 将文件字节编码为Base64字符串
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error converting XFile to Base64: $e");
      return null;
    }
  }
}
