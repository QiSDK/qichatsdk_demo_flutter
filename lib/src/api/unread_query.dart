import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../model/Entrance.dart';
import '../model/Result.dart';

/// Stateless 未读查询：不依赖 [QiChatConfig.current]，可被宿主在多商户场景下
/// 并行调用，互不干扰。
///
/// 调用链：先对 [detectUrls] 做一轮 verify ping 挑出一条健康线路，再用 [cert]
/// 作为 `x-token` 调 `/v1/api/query-entrance`，把每个 consult 的 unread 解出来。
class UnreadQuery {
  UnreadQuery._();

  static const String _verifyPath = '/v1/api/verify';
  static const String _entrancePath = '/v1/api/query-entrance';

  /// 返回 `consultId -> unread` 的 Map。任何失败都返回空 Map（debugPrint 记录原因）。
  /// 不写 [UnreadManager]：合并策略由宿主决定。
  static Future<Map<int, int>> fetch({
    required String cert,
    required int merchantId,
    required String detectUrls,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final domain = await _detectLine(
      detectUrls: detectUrls,
      tenantId: merchantId,
      timeout: timeout,
    );
    if (domain == null) {
      debugPrint('[UnreadQuery] merchant=$merchantId 线路检测失败');
      return const {};
    }
    return _queryEntrance(domain: domain, cert: cert, timeout: timeout);
  }

  /// 对 [detectUrls] 里的每个候选 URL 并行 POST verify，返回第一个返回
  /// 200 且 body 含 "tenantId" 的 host（含端口）。整个过程不读不写任何全局态。
  static Future<String?> _detectLine({
    required String detectUrls,
    required int tenantId,
    required Duration timeout,
  }) async {
    final urls = detectUrls
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.startsWith('http'))
        .toList();
    if (urls.isEmpty) return null;

    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {'Content-Type': 'application/json'},
    ));
    final completer = Completer<String?>();
    var pending = urls.length;
    final body = {'gnsId': 'wcs', 'tenantId': tenantId};

    void finishMiss() {
      if (completer.isCompleted) return;
      if (--pending == 0) completer.complete(null);
    }

    Future<void> probe(String base) async {
      final url = '$base$_verifyPath';
      try {
        final resp = await dio.post<String>(
          url,
          data: body,
          options: Options(
            headers: {'x-trace-id': const Uuid().v4()},
            responseType: ResponseType.plain,
          ),
        );
        if (completer.isCompleted) return;
        final ok = resp.statusCode == 200 &&
            (resp.data ?? '').contains('tenantId');
        if (!ok) {
          finishMiss();
          return;
        }
        final uri = Uri.parse(url);
        var host = uri.host;
        if (uri.port != 80 && uri.port != 443) host = '$host:${uri.port}';
        completer.complete(host);
      } catch (_) {
        finishMiss();
      }
    }

    for (final base in urls) {
      // ignore: discarded_futures
      probe(base);
    }

    final result = await completer.future
        .timeout(timeout, onTimeout: () => null);
    dio.close(force: true);
    return result;
  }

  static Future<Map<int, int>> _queryEntrance({
    required String domain,
    required String cert,
    required Duration timeout,
  }) async {
    // 独立 Dio 实例：不挂 CustomInterceptors（后者从全局 xToken 读 header），
    // 直接用 cert 当 x-token（服务端在 xToken 缺失时本就走 cert 鉴权）。
    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'x-token': cert,
        'x-trace-id': const Uuid().v4(),
      },
    ));
    try {
      final resp = await dio.post('https://$domain$_entrancePath');
      final result = Result<Entrance?>.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => json == null
            ? null
            : Entrance.fromJson(json as Map<String, dynamic>),
      );
      if ((result.code ?? -1) != 0 || result.data?.consults == null) {
        debugPrint(
            '[UnreadQuery] entrance code=${result.code} msg=${result.msg}');
        return const {};
      }
      final map = <int, int>{};
      for (final c in result.data!.consults!) {
        final cid = c.consultId;
        final unread = c.unread ?? 0;
        if (cid != null && cid > 0 && unread > 0) {
          map[cid] = unread;
        }
      }
      return map;
    } catch (e) {
      debugPrint('[UnreadQuery] entrance 请求失败 domain=$domain: $e');
      return const {};
    } finally {
      dio.close(force: true);
    }
  }
}
