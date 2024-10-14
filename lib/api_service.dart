import 'package:flutter/cupertino.dart';
import 'package:qichatsdk_demo_flutter/Constant.dart';
import 'base/custom_interceptors.dart';
import 'package:dio/dio.dart';

class Resource {
  String path = '';
  Map<String, dynamic>? queryParams;
  Object? bodyParams;
  Map<String, dynamic>? headers;
  Options? options;
}

class Api {
  Dio dio;
  Api() : dio = Dio() {
    // 设置 Dio 的一些默认配置（如果需要）
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 45); // 接收超时
    dio.interceptors.add(CustomInterceptors());
  }

  Future<dynamic> _attemptRequest(
    String path, {
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final url = '$baseUrlApi$path';

    try {
      final response = await dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      //AppConfig.globalStore.currentApi = server;
      return response.data;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<dynamic> get(Resource resource) {
    return _attemptRequest(resource.path,
        method: 'GET', queryParameters: resource.queryParams);
  }

  Future<dynamic> post(Resource resource) {
    return _attemptRequest(resource.path,
        method: 'POST',
        data: resource.bodyParams,
        queryParameters: resource.queryParams);
  }

  Future<dynamic> put(Resource resource) {
    return _attemptRequest(resource.path,
        method: 'PUT',
        data: resource.bodyParams,
        queryParameters: resource.queryParams);
  }

  Future<dynamic> delete(Resource resource) {
    return _attemptRequest(resource.path,
        method: 'DELETE',
        data: resource.bodyParams,
        queryParameters: resource.queryParams);
  }
}
