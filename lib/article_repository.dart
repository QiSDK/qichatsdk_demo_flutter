import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'api_service.dart';
import 'model/Result.dart';

class ArticleRepository {
  static const String publishPath = '/api/PublishWork';
  static const String articleListPath = '/api/MyWorks';
  static const String favListPath = '/api/Favorites/';
  static const String myPublishPath = '/api/MyWorks/';
  static const String favPath = '/api/Favorites';
  static const String isMyFavPath = '/api/PublishWork/';
  static const String thumbupsPath = '/api/Thumbups';
  static const String delWorkPath = '/api/PublishWork';
  static const String delMyWorkPath = '/api/MyWorks/';
  static const String getMyPlaylistPath = '/api/MyWorkCategories/GetMyPlaylist';
  static const String addViewCountPath = '/api/MyWorks/AddViewCount/';
  static const String translatePath = '/api/Articles/';
  static const String updateWorkPath = '/api/PublishWork';
  static const String uploadAudioPath = '/api/PublishWork/';
  static const String addToWorkPath = '/api/PublishWork/addTextToWork';
  static const String queryEntrancePath = '/v1/api/query-entrance';

  //即时翻译，服务器不会保存结果
  static const String instantTranslatePath = '/api/Translate';


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

  static Future<dynamic> getMyPlaylist(String catName, {int? userId}) async {
    Resource res = Resource();
    res.path = getMyPlaylistPath;
    res.queryParams = {
      'userId': userId,
      'catName': catName
    };
    debugPrint("getMyPlaylist 请求参数：${res.queryParams}");
    try {
      var result = await Api().get(res);
      var data = result;
      return data;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  static Future<Entr> queryEntrance() async {
    Resource res = Resource();
    res.path = queryEntrancePath;
    debugPrint("queryEntrance 请求参数：${res.queryParams}");
    try {
      var result = await Api().post(res);
      var data = result;
      return data;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  static Future<dynamic> thumbups(Works model) async {
    Resource res = Resource();
    res.path = thumbupsPath;
    var map = model.toJson();
    res.bodyParams = map;
    try {
      var result = await Api().post(res);
      var data = result;
      return data;
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
