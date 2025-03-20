
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../base/custom_interceptors.dart';
import '../model/Result.dart' as re;
import '../model/UploadPercent.dart';

abstract class UploadListener {
  void uploadSuccess(Urls path, bool isVideo);
  void updateProgress(int progress);
  void uploadFailed(String msg);
}

class UploadUtil {

  UploadListener? listener;

  //, filePath: String?, fileSize: Int32 = 0
  Future<void> upload(Uint8List imgData,
      bool isVideo, UploadListener? mylistener, String? filePath, int length) async {
    this.listener = mylistener;
    // 设置URL
    final String apiUrl = '${baseUrlApi()}/v1/assets/upload-v4';

    var ext = "";
    if (filePath != null) {
      ext = filePath?.split(".").last ?? "#";

      if (!Constant.instance.imageTypes.contains(ext) &&
          !Constant.instance.fileTypes.contains(ext) &&
          !Constant.instance.videoTypes.contains(ext)) {
        listener?.uploadFailed("不支持的文件格式");
        return;
      }
    }


    // let ext = filePath?.split(separator: ".").last?.lowercased() ?? "$"
    //
    // //目前只有pdf, word, excel等文件，filePath才不为空
    // if (filePath != nil && !fileTypes.contains(ext)){
    //   self.listener?.uploadFailed(msg: "不支持的文件格式")
    //   return
    // }


    Dio dio = Dio();
    // 设置 Dio 的一些默认配置（如果需要）
    dio.options.connectTimeout = const Duration(minutes: 10);
    dio.options.receiveTimeout = const Duration(minutes: 15); // 接收超时
    dio.options.sendTimeout = const Duration(minutes: 15); // 接收超时
    dio.interceptors.add(CustomInterceptors());
    uploadProgress = 1;
    listener?.updateProgress(uploadProgress);

    dio.options.headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'multipart/form-data',
      'X-Token': xToken,
    };

    // final String fileName = isVideo ? '${DateTime
    //     .now()
    //     .millisecond}file.mp4' : '${DateTime
    //     .now()
    //     .millisecond}file.jpg';

    final String fileName = '${DateTime
        .now()
        .millisecond}.${ext}';

    //final String mimeType = isVideo ? 'video/mp4' : 'image/png';

    // 创建表单数据
    FormData formData = FormData.fromMap({
      'type': '4',
      'myFile': MultipartFile.fromBytes(
        imgData,
        filename: fileName,
      ),
    });

    debugPrint('xToken=$xToken');
    try {
      SmartDialog.showLoading(msg: "上传中");
      Constant.instance.chatLib.idleTimes = 0;
      final Response response = await dio.post(apiUrl, data: formData,
          onSendProgress: (int sent, int total) {
            // debugPrint(
            //     'Upload Progress: ${(sent / total * 100).toStringAsFixed(
            //         0)}% ${DateTime.now()}');
          }, onReceiveProgress: (int rece, int total) {
            // debugPrint(
            //     'Receive Progress: ${(rece / total * 100).toStringAsFixed(
            //         0)}% ${DateTime.now()}');
          });
      Constant.instance.chatLib.idleTimes = 0;
      if (response.statusCode == 200) {
        final responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        var result = re.Result<re.FilePath>.fromJson(
          responseData,
              (json) => re.FilePath.fromJson(json as Map<String, dynamic>),
        );
        final String filePath = result.data?.filePath ?? "";
        debugPrint(filePath);
        if (filePath.isNotEmpty) {
          var urls = Urls();
          urls.uri = filePath;
          urls.size = length;
          urls.fileName = fileName;
          listener?.uploadSuccess(urls, false);
        }
        print('上传成功: $filePath ${DateTime.now()}');
      } else if (response.statusCode == 202) {
        if (uploadProgress < 70){
          uploadProgress = 70;
        }else{
          uploadProgress += 10;
        }
        listener?.updateProgress(uploadProgress);
        final responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        var result = re.Result<String>.fromJson(
          responseData as Map<String, dynamic>, // Cast to Map<String, dynamic>
              (json) => json as String, //
        );
        print('获得上传地址=${ result.data ?? ""}');
        subscribeToSee(apiUrl + "?uploadId=${ result.data ?? ""}");
      } else {
        print('上传失败：${response.statusMessage}');
        listener?.uploadFailed('上传失败：${response.statusCode} - ${response.statusMessage}');
      }
    } catch (e) {
      listener?.uploadFailed('上传失败：${e.toString()}');
      print('上传失败：$e ${DateTime.now()}');
      SmartDialog.dismiss();
    } finally {
      print('上传 finally ${DateTime.now()}');
    }
  }

  Future<void> subscribeToSee(String url) async {
    // 设置URL
    //final String apiUrl = '${baseUrlApi()}/v1/assets/upload-v4';

    Dio dio = Dio();
    // 设置 Dio 的一些默认配置（如果需要）
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(minutes: 10); // 接收超时
    dio.options.sendTimeout = const Duration(minutes: 5); // 接收超时
    dio.interceptors.add(CustomInterceptors());

    dio.options.headers = {
      'Accept': 'text/event-stream',
      'X-Token': xToken,
    };

    debugPrint('xToken=$xToken');
    // try {
    //SmartDialog.showLoading(msg: "上传中");
    Constant.instance.chatLib.idleTimes = 0;
    final Response response = await dio.get(url,
        onReceiveProgress: (int rece, int total) {
          debugPrint(
              'Receive Progress: ${(rece / total * 100).toStringAsFixed(
                  0)}% ${DateTime.now()}');
        });
    Constant.instance.chatLib.idleTimes = 0;
    if (response.statusCode == 200) {
      listener?.updateProgress(99);
      print("上传成功：${response.statusCode}");
      final body = response.data;

      if (body != null) {
        final strData = body;
        final lines = strData.split("\n");
        var event = "";
        var data = "";

        print("上传监听返回 $strData");

        if (lines.isEmpty) {
          listener?.uploadFailed("数据为空，上传失败");
          return;
        }

        for (var line in lines) {
          if (line.startsWith("event:")) {
            event = line.replaceFirst("event:", "");
          } else if (line.startsWith("data:")) {
            data = line.replaceFirst("data:", "");
            final result = UploadPercent.fromJson(jsonDecode(data));

            if (result.percentage == 100 && result.data != null) {
              listener?.uploadSuccess(result.data!, true);
              print("上传成功 ${result.data?.uri}");
              print("${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now())} 上传进度 ${result.percentage}");
            } else {
              listener?.updateProgress(result.percentage ?? 0);
              print("${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now())} 上传进度 ${result.percentage}");
            }
          }
        }
      }
    }else{
      listener?.uploadFailed('上传失败：${response.statusCode} - ${response.statusMessage}');
    }
  }
}