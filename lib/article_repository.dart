import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:qichatsdk_demo_flutter/model/Sync.dart';
import 'api_service.dart';
import 'model/Entrance.dart';
import 'model/Result.dart';

class ArticleRepository {
  static const String publishPath = '/api/PublishWork';
  static const String articleListPath = '/api/MyWorks';
  static const String uploadAudioPath = '/api/PublishWork/';
  static const String queryEntrancePath = '/v1/api/query-entrance';
  static const String syncMessagePath = '/v1/api/message/sync';

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

      var result = Result<Entrance>.fromJson(
        resp,
            (json) => Entrance.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0 ){
        return result.data;
      }else{
        return null;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  static Future<Sync?> queryHistory() async {
    Resource res = Resource();
    res.path = syncMessagePath;
    var map = {'chatId': 0, "count": 50, "consultId": 1, "userId": 666665};
    var formData = FormData.fromMap(map);
    res.bodyParams = formData;

    try {
      var resp = await Api().post(res);
      var result = Result<Sync>.fromJson(
        resp,
            (json) => Sync.fromJson(json as Map<String, dynamic>),
      );

      if (result != null && (result.code ?? -1) == 0 ){
        return result.data;
      }else{
        return null;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
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
