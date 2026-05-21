import 'dart:developer';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qichat_ui_sdk/src/Constant.dart';
import 'package:qichat_ui_sdk/src/model/AutoReply.dart';
import 'package:qichat_ui_sdk/src/model/Sync.dart';
import 'package:qichat_ui_sdk/src/model/Worker.dart';
import 'api_service.dart';
import 'model/Entrance.dart';
import 'model/Evaluation.dart';
import 'model/ReplyList.dart';
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
  static const String queryMessagePath = '/v1/api/message/reply-message/sync';
  static const String markReadPath = '/v1/api/chat/mark-read';
  static const String assignWorkerPath = '/v1/api/assign-worker';
  static const String queryAutoReplyPath = '/v1/api/query-auto-reply';
  static const String evaluationConfigPath = '/v1/tenant/evaluation/config/info';
  static const String evaluationStatusPath = '/v1/tenant/evaluation/status/get';
  static const String evaluationAddPath = '/v1/tenant/evaluation/add';

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
    var msgId = null;
    if (kDebugMode){
      l = 15;
     // msgId = "1331873452448907298";
    }
    var map = {
      'chatId': 0,
      "count": l,
      "consultId": consultId.toInt(),
      "userId": userId,
      "msgId": msgId,
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

  static Future<ReplyList?> queryMessage(String msgId) async {
    Resource res = Resource();
    res.path = queryMessagePath;

    var map = {
      'chatId': Constant.instance.chatId,
      "msgIds": [msgId]
    };
    res.bodyParams = map;
    try {
      var resp = await Api().post(res);
      var result = Result<ReplyList>.fromJson(
        resp,
            (json) => ReplyList.fromJson(json as Map<String, dynamic>),
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


  // MARK: - 客服满意度评价

  /// 获取评价配置
  static Future<EvaluationConfig?> evaluationConfig() async {
    Resource res = Resource();
    res.path = evaluationConfigPath;
    res.bodyParams = <String, dynamic>{};
    try {
      var resp = await Api().post(res);
      var result = Result<EvaluationConfig>.fromJson(
        resp,
        (json) => EvaluationConfig.fromJson(json as Map<String, dynamic>),
      );
      if ((result.code ?? -1) == 0) {
        return result.data;
      }
      _toastEvaluationError(result.msg);
      return null;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  /// 获取当前会话评价状态: 0-未评价 1-已评价 2-已关闭 3-空会话
  static Future<EvaluationStatus?> evaluationStatus(
      fixNum.Int64 consultId) async {
    Resource res = Resource();
    res.path = evaluationStatusPath;
    res.bodyParams = {"consultId": consultId.toInt()};
    try {
      var resp = await Api().post(res);
      var result = Result<EvaluationStatus>.fromJson(
        resp,
        (json) => EvaluationStatus.fromJson(json as Map<String, dynamic>),
      );
      if ((result.code ?? -1) == 0) {
        return result.data;
      }
      _toastEvaluationError(result.msg);
      return null;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  /// 提交评价 (close=1 表示用户拒绝评价；正常提交时 close=0)
  static Future<bool> addEvaluation(
      fixNum.Int64 consultId, int score, String remark, int close) async {
    Resource res = Resource();
    res.path = evaluationAddPath;
    res.bodyParams = {
      "consultId": consultId.toInt(),
      "score": score,
      "remark": remark,
      "close": close,
    };
    try {
      var resp = await Api().post(res);
      var result = Result<dynamic>.fromJson(resp, (json) => json);
      if ((result.code ?? -1) == 0) {
        return true;
      }
      _toastEvaluationError(result.msg);
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  static void _toastEvaluationError(String? msg) {
    final text = (msg ?? '').trim();
    if (text.isEmpty) return;
    SmartDialog.showToast(text);
  }

  Future<bool> downloadVideo(String url) async {
    try {
      // Initialize Dio
      Dio dio = Dio();
      var fileName = url.split("/").last;
      // Get the app's document directory to save the file
      Directory downloadDirectory = await getTemporaryDirectory();
      String? savePath = '${downloadDirectory.path}/$fileName';
      //String savePath = '/Users/xuefeng/Downloads/$fileName';

      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS)
      // Let the user choose the save location
       savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your file',
        fileName: fileName,
      );
      if (savePath == null) {
        print('Download cancelled by user');
        return false;
      }
      SmartDialog.showLoading();
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
