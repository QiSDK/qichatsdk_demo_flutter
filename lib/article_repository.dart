import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'package:qichatsdk_demo_flutter/model/AutoReply.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart';
import 'package:qichatsdk_demo_flutter/model/Worker.dart';
import 'api_service.dart';
import 'model/Entrance.dart';
import 'model/Result.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:fixnum/src/int64.dart' as fixNum;
import 'package:file_picker/file_picker.dart';

class ArticleRepository {
  static const String publishPath = '/api/PublishWork';
  static const String articleListPath = '/api/MyWorks';
  static const String uploadAudioPath = '/api/PublishWork/';
  static const String queryEntrancePath = '/v1/api/query-entrance';
  static const String syncMessagePath = '/v1/api/message/sync';
  static const String markReadPath = '/v1/api/chat/mark-read';
  static const String assignWorkerPath = '/v1/api/assign-worker';
  static const String queryAutoReplyPath = '/v1/api/query-auto-reply';

  static Future<dynamic> articleList(int pageNum, {int? thumpCount}) async {
    Resource res = Resource();
    res.path = articleListPath;
    res.queryParams = {'PageNumber': pageNum, 'PageSize': 30};
    if (thumpCount != null) {
      res.queryParams = {
        'PageNumber': pageNum,
        'PageSize': 100,
        "thumpCount": thumpCount
      };
    }
    try {
      var result = await Api().get(res);
      var data = result;
      return data;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  static Future<Entrance?> queryEntrance() async {
    Resource res = Resource();
    res.path = queryEntrancePath;
    debugPrint("queryEntrance 请求参数：${res.queryParams}");
    try {
      var resp = await Api().post(res);

      var result = Result<Entrance?>.fromJson(
        resp,
        (json) => json == null
            ? null
            : Entrance.fromJson(json as Map<String, dynamic>),
      );

      if ((result.code ?? -1) == 0) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      log(e.toString());
      //rethrow;
    }
  }

  static Future<bool> markRead(fixNum.Int64 consultId) async {
    Resource res = Resource();
    res.path = markReadPath;
    var map = {
      "consultId": consultId.toInt(),
    };
    res.bodyParams = map;

    try {
      var resp = await Api().post(res);
      var result = Result<Sync>.fromJson(
        resp,
            (json) => Sync.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  static Future<Sync?> queryHistory(fixNum.Int64 consultId) async {
    Resource res = Resource();
    res.path = syncMessagePath;

    var l = 50;
    if (kDebugMode){
      l = 5;
    }
    var map = {
      'chatId': 0,
      "count": l,
      "consultId": consultId.toInt(),
      "userId": userId
    };
    //var formData = FormData.fromMap(map);
    res.bodyParams = map;

    try {
      var resp = await Api().post(res);
      var result = Result<Sync>.fromJson(
        resp,
            (json) => Sync.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }


  static Future<AutoReply?> queryAutoReply(
      fixNum.Int64 consultId, int workerId) async {
    Resource res = Resource();
    res.path = queryAutoReplyPath;
    //{
    //   "consultId": 2,
    //   "workerId": 4
    // }
    var map = {"consultId": consultId.toInt(), "workerId": workerId};
    //var formData = FormData.fromMap(map);
    res.bodyParams = map;

    try {
      var resp = await Api().post(res);
      var result = Result<AutoReply>.fromJson(
        resp,
            (json) => AutoReply.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      log(e.toString());
      //rethrow;
    }
  }

  static Future<Worker?> assignWorker(
      fixNum.Int64 consultId) async {
    Resource res = Resource();
    res.path = assignWorkerPath;
    var map = {"consultId": consultId.toInt()};
    res.bodyParams = map;

    try {
      var resp = await Api().post(res);
      var result = Result<Worker>.fromJson(
        resp,
            (json) => Worker.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      log(e.toString());
      //rethrow;
    }
  }


  Future<bool> downloadVideo(String url) async {
    try {
      // Initialize Dio
      Dio dio = Dio();
      var fileName = url.split("/").last;
      // Get the app's document directory to save the file
      //Directory downloadDirectory = await getTemporaryDirectory();
      //String savePath = '${downloadDirectory.path}/$fileName';
      //String savePath = '/Users/xuefeng/Downloads/$fileName';

      // Let the user choose the save location
      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your file',
        fileName: fileName,
      );
      // Start downloading
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Print download progress
            print('Download Progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      return true;
      print('File saved to $savePath');
    } catch (e) {
      return false;
      print('Error downloading file: $e');
    }
  }


  static Future<dynamic> uploadAudio(
      int workId, MultipartFile file, String lang) async {
    Resource res = Resource();
    res.path = '$uploadAudioPath$workId';
    var map = {'File': file, "WorkId": workId, "Lang": lang};
    var formData = FormData.fromMap(map);
    res.bodyParams = formData;
    try {
      var result = await Api().put(res);
      var data = result;
      return data;
    } catch (e) {
      log(e.toString());
      print("上传音频失败${res.queryParams}");
      rethrow;
    }
  }
}
