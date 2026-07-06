import 'dart:convert';

import 'package:flutter/material.dart';

import 'network_log.dart';
import 'network_log_buffer.dart';

/// 网络日志列表页 - 与 Android `NetworkLogActivity` / iOS `NetworkLogVC` 对齐。
/// 展示 UISDK 经由 Dio 发出的 HTTP 请求，点击进入详情。
class NetworkLogPage extends StatelessWidget {
  const NetworkLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('网络日志'),
        actions: [
          TextButton(
            onPressed: NetworkLogBuffer.instance.clear,
            child: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NetworkLog>>(
        valueListenable: NetworkLogBuffer.instance.logs,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('暂无网络请求', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _LogTile(log: logs[i]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final NetworkLog log;
  const _LogTile({required this.log});

  Color _statusColor() {
    final code = log.statusCode;
    if (code == null) return Colors.grey; // pending
    if (code >= 200 && code < 300) return const Color(0xFF4CAF50);
    if (code < 0) return const Color(0xFFF44336);
    return const Color(0xFFFF9800);
  }

  String _statusText() {
    final code = log.statusCode;
    if (code == null) return '···';
    return '$code';
  }

  String _shortPath() {
    try {
      return '${log.method} ${Uri.parse(log.url).path}';
    } catch (_) {
      return '${log.method} ${log.url}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = log.sentAt;
    final timeStr =
        '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
    final durationStr = log.duration == null
        ? '—'
        : '${log.duration!.inMilliseconds}ms';

    return ListTile(
      tileColor: Colors.white,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _shortPath(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusText(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _statusColor()),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$timeStr | $durationStr | apiCode:${log.apiCode}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NetworkLogDetailPage(log: log)),
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

/// 网络日志详情页 - 与 Android `NetworkLogDetailActivity` 对齐。以纯文本展示全部信息，可选中复制。
class NetworkLogDetailPage extends StatelessWidget {
  final NetworkLog log;
  const NetworkLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final b = StringBuffer();
    b.writeln('== 请求 ==');
    b.writeln('${log.method} ${log.url}');
    b.writeln();
    b.writeln('-- Headers --');
    final keys = log.requestHeaders.keys.toList()..sort();
    for (final k in keys) {
      b.writeln('$k: ${log.requestHeaders[k]}');
    }
    if (log.requestBody != null) {
      b.writeln();
      b.writeln('-- Request Body --');
      b.writeln(_formatJson(log.requestBody!));
    }

    b.writeln();
    b.writeln('== 响应 ==');
    b.writeln('HTTP Status: ${log.statusCode ?? '进行中'}');
    b.writeln('API Code: ${log.apiCode}');
    b.writeln('API Msg: ${log.apiMsg}');
    b.writeln('耗时: ${log.duration == null ? '—' : '${(log.duration!.inMilliseconds / 1000).toStringAsFixed(3)}s'}');
    b.writeln('时间: ${log.sentAt}');
    if (log.error != null) {
      b.writeln();
      b.writeln('-- Error --');
      b.writeln(log.error);
    }
    if (log.responseBody != null) {
      b.writeln();
      b.writeln('-- Response Body --');
      b.writeln(_formatJson(log.responseBody!));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('日志详情')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          b.toString(),
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  String _formatJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }
}
