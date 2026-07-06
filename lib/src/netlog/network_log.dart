/// UISDK 一次 HTTP 请求的完整日志（请求 + 响应关键数据）。
///
/// 数据来源为 `CustomInterceptors`（Dio 拦截器），捕获经由 [Api] 发出的所有请求。
/// 与 Android `NetworkLog.kt` / iOS `NetworkLog.swift` 对齐。
///
/// Dio 拦截器的请求、响应是分两次回调（onRequest / onResponse / onError），
/// 因此请求字段 final、响应字段可后填：先在 onRequest 建一条 pending 记录，
/// 收到响应后用 [id]（x-trace-id）匹配回来补全。
class NetworkLog {
  /// 唯一标识（等于请求的 x-trace-id），用于把响应匹配回对应请求
  final String id;

  /// 完整请求 URL
  final String url;

  /// HTTP 方法（GET / POST ...）
  final String method;

  /// HTTP 请求头
  final Map<String, dynamic> requestHeaders;

  /// 请求体明文，无请求体时为 null
  final String? requestBody;

  /// 请求发出的时间戳
  final DateTime sentAt;

  /// HTTP 响应状态码：null=进行中，-1=网络错误
  int? statusCode;

  /// 响应体字符串，无响应体或读取失败时为 null
  String? responseBody;

  /// 业务层响应码（ReturnData.code），无法解析时为 -1
  int apiCode;

  /// 业务层响应消息（ReturnData.msg），无法解析时为空串
  String apiMsg;

  /// 网络错误描述，无错误时为 null
  String? error;

  /// 从发送请求到收到响应的耗时，收到响应前为 null
  Duration? duration;

  NetworkLog({
    required this.id,
    required this.url,
    required this.method,
    required this.requestHeaders,
    required this.requestBody,
    required this.sentAt,
    this.statusCode,
    this.responseBody,
    this.apiCode = -1,
    this.apiMsg = '',
    this.error,
    this.duration,
  });

  /// 是否仍在等待响应
  bool get isPending => statusCode == null;
}
