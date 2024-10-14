import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:logman/logman.dart';

import '../Constant.dart';

class CustomInterceptors extends Interceptor {
  final _cache = <RequestOptions, String>{};
  final Logman _logman = Logman.instance;

  String loginToken =
      'Bearer ${const String.fromEnvironment('LOGIN_TOKEN', defaultValue: '')}';
  // 是否有网
  Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    final header = {'x-token': xToken};
    options.headers.addAll(header);
    if (kDebugMode) {
      debugPrint("loginToken:" + loginToken);
      final requestId = UniqueKey().toString();
      _cache[options] = requestId;
      final sentAt = DateTime.now();

      final requestRecord = NetworkRequestLogmanRecord(
        id: requestId,
        url: options.uri.toString(),
        method: options.method,
        headers: options.headers,
        body: dataToString(options.data),
        sentAt: sentAt,
      );
      _logman.networkRequest(requestRecord);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');

    if (kDebugMode) {
      final Map<String, String> responseHeaders = response.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );
      final id = _cache[response.requestOptions];
      final receivedAt = DateTime.now();

      final responseRecord = NetworkResponseLogmanRecord(
        id: id!,
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: dataToString(response.data),
        receivedAt: receivedAt,
        url: '',
      );

      _logman.networkResponse(responseRecord);
    }
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    print(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    isConnected().then((isConnectNetWork) {
      if (kDebugMode && !isConnectNetWork) {
        SmartDialog.showToast("当前网络不可用，请检查您的网络");
      }
    });
    int? errCode = err.response?.statusCode;
    print(err);
    var errorMsg = "";
    switch (errCode) {
      case 401:
        SmartDialog.showToast("用户未登陆或登陆已失效，请重新登陆", displayTime: Duration(seconds: 5));
        break;
      case 500:
        errorMsg = "服务器内部错误${errCode ?? ''}，请稍后再试";
        break;
      default:
        errorMsg = "未知错误${errCode ?? ''}";
    }

    if (kDebugMode) {
      if (errorMsg.isNotEmpty){
        SmartDialog.showToast(errorMsg);
        print(errorMsg);
      }
      final Map<String, String>? responseHeaders =
          err.response?.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );
      final id = _cache[err.requestOptions];

      final responseRecord = NetworkResponseLogmanRecord(
        id: id!,
        statusCode: err.response?.statusCode ?? 0,
        headers: responseHeaders,
        body: dataToString(err.response?.data),
        receivedAt: DateTime.now(),
        url: '',
      );

      _logman.networkResponse(responseRecord);
    }

    // showConfirmDialog(ctx: AppConfig.navigatorKey.currentContext!, title: title, confirm: confirm)
    super.onError(err, handler);
  }

  String dataToString(dynamic data) {
    if (data is Map) {
      return jsonEncode(data);
    } else if (data is List) {
      return jsonEncode(data);
    } else {
      if (data is FormData) {
        return readFormData(data);
      }
      return data.toString();
    }
  }

  String readFormData(FormData formData) {
    Map<String, dynamic> formDataMap = {};
    // Add form data field to formDataMap
    for (var field in formData.fields) {
      formDataMap[field.key] = field.value;
    }
    // Add form data files to formDataMap
    for (var field in formData.files) {
      MultipartFile file = field.value;
      formDataMap[field.key] = {
        'filename': file.filename,
        'length': file.length,
        'contentType': file.contentType.toString(),
        'headers': file.headers
      };
    }
    // Convert the map to a formatted JSON string
    return jsonEncode(formDataMap);
  }
}
