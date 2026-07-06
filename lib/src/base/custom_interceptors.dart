import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:uuid/uuid.dart';

import '../Constant.dart';
import '../netlog/network_log.dart';
import '../netlog/network_log_buffer.dart';

class CustomInterceptors extends Interceptor {
  static const String _traceHeader = 'x-trace-id';

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
    options.headers.addAll(header);
    options.headers.addAll({_traceHeader: uuid});
    // 始终记录网络日志（对齐 Android/iOS 端始终采集），供 QiChatUISDK.openNetworkLog 查看。
    // 用 x-trace-id 作为 id，onResponse/onError 时按同一 header 匹配回来补全响应。
    NetworkLogBuffer.instance.addRequest(NetworkLog(
      id: uuid,
      url: options.uri.toString(),
      method: options.method,
      requestHeaders: Map<String, dynamic>.from(options.headers),
      requestBody: options.data == null ? null : dataToString(options.data),
      sentAt: DateTime.now(),
    ));
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    //print(
     //   'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');

    final id = response.requestOptions.headers[_traceHeader] as String?;
    if (id != null) {
      NetworkLogBuffer.instance.completeResponse(id, (log) {
        log.statusCode = response.statusCode ?? 0;
        log.responseBody =
            response.data == null ? null : dataToString(response.data);
        log.duration = DateTime.now().difference(log.sentAt);
        final (code, msg) = _parseApiCodeMsg(response.data);
        log.apiCode = code;
        log.apiMsg = msg;
      });
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
    final id = err.requestOptions.headers[_traceHeader] as String?;
    if (id != null) {
      NetworkLogBuffer.instance.completeResponse(id, (log) {
        log.statusCode = err.response?.statusCode ?? -1;
        log.responseBody = err.response?.data == null
            ? null
            : dataToString(err.response!.data);
        log.duration = DateTime.now().difference(log.sentAt);
        log.error = err.message ?? err.toString();
        final (code, msg) = _parseApiCodeMsg(err.response?.data);
        log.apiCode = code;
        log.apiMsg = msg;
      });
    }

    // showConfirmDialog(ctx: AppConfig.navigatorKey.currentContext!, title: title, confirm: confirm)
    super.onError(err, handler);
  }

  /// 从响应体解析业务层 code / msg（对齐 Android/iOS）。无法解析时返回 (-1, '')。
  (int, String) _parseApiCodeMsg(dynamic data) {
    try {
      Map? map;
      if (data is Map) {
        map = data;
      } else if (data is String && data.trim().startsWith('{')) {
        map = jsonDecode(data) as Map;
      }
      if (map == null) return (-1, '');
      final code = map['code'];
      final msg = map['msg'];
      final codeInt =
          code is int ? code : int.tryParse('$code') ?? -1;
      return (codeInt, msg?.toString() ?? '');
    } catch (_) {
      return (-1, '');
    }
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
