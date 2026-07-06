import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:logman/logman.dart';
import 'package:uuid/uuid.dart';

import '../Constant.dart';

class CustomInterceptors extends Interceptor {
  final _cache = <RequestOptions, String>{};
  final Logman _logman = Logman.instance;

  // 是否有网
  Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    var header = {'x-token': xToken};
    if (xToken.isEmpty){
      header = {'x-token': cert};
    }
    String uuid = Uuid().v4();
    var traceHeader = {"x-trace-id": uuid};
    options.headers.addAll(header);
    options.headers.addAll(traceHeader);
    // 始终记录网络日志（对齐 Android/iOS 端始终采集），供 QiChatUISDK.openNetworkLog 查看
    _cache[options] = uuid;
    final requestRecord = NetworkRequestLogmanRecord(
      id: uuid,
      url: options.uri.toString(),
      method: options.method,
      headers: options.headers,
      body: dataToString(options.data),
      sentAt: DateTime.now(),
    );
    _logman.networkRequest(requestRecord);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    //print(
     //   'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');

    final id = _cache.remove(response.requestOptions);
    if (id != null) {
      final Map<String, String> responseHeaders = response.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );
      final responseRecord = NetworkResponseLogmanRecord(
        id: id,
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: dataToString(response.data),
        receivedAt: DateTime.now(),
        url: response.requestOptions.uri.toString(),
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

    if (kDebugMode && errorMsg.isNotEmpty) {
      SmartDialog.showToast(errorMsg);
      print(errorMsg);
    }

    // 始终记录网络日志（对齐 Android/iOS 端始终采集）
    final id = _cache.remove(err.requestOptions);
    if (id != null) {
      final Map<String, String>? responseHeaders =
          err.response?.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );

      final responseRecord = NetworkResponseLogmanRecord(
        id: id,
        statusCode: err.response?.statusCode ?? 0,
        headers: responseHeaders,
        body: dataToString(err.response?.data),
        receivedAt: DateTime.now(),
        url: err.requestOptions.uri.toString(),
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
