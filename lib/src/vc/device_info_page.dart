import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gal/gal.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';
import '../model/AppChatTheme.dart';

/// 设备信息页面。展示当前设备 / 应用 / SDK 线路状态，支持保存为图片。
///
/// 由 [QiChatUISDK.openDeviceInfo] 推入。宿主在 iOS 上需自行在 Info.plist 添加
/// `NSPhotoLibraryAddUsageDescription`，否则保存图片会被系统拒绝。
class DeviceInfoPage extends StatefulWidget {
  final AppChatTheme? theme;

  const DeviceInfoPage({super.key, this.theme});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  late final AppChatTheme _theme = widget.theme ?? AppChatTheme.random();
  final GlobalKey _cardKey = GlobalKey();
  Timer? _ticker;

  String _phoneModel = '—';
  String _appName = '—';
  String _osVersion = '—';
  String _appVersion = '—';
  String _packageName = '—';
  String _now = '—';

  @override
  void initState() {
    super.initState();
    _loadStaticInfo();
    _now = _formatNow();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = _formatNow());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadStaticInfo() async {
    final results = await Future.wait([
      _readDeviceInfo(),
      _readPackageInfo(),
    ]);
    if (!mounted) return;
    final device = results[0];
    final pkg = results[1];
    setState(() {
      _phoneModel = device['model'] ?? '—';
      _osVersion = device['os'] ?? '—';
      _appName = pkg['appName'] ?? '—';
      _appVersion = pkg['version'] ?? '—';
      _packageName = pkg['packageName'] ?? '—';
    });
  }

  Future<Map<String, String>> _readDeviceInfo() async {
    if (kIsWeb) return {};
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return {
          'model': _iosMarketingName(info.utsname.machine) ?? info.utsname.machine,
          'os': 'iOS_${info.systemVersion}',
        };
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return {
          'model': info.model,
          'os': 'Android_${info.version.release}',
        };
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, String>> _readPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return {
        'appName': info.appName,
        'version': '${info.version}_${info.buildNumber} (V3)',
        'packageName': info.packageName,
      };
    } catch (_) {
      return {};
    }
  }

  String _formatNow() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)} '
        '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
  }

  /// 当前线路：在 detectUrls(逗号分隔) 中找到 domain 的下标，转成「线路N」。
  String _currentLine() {
    final cfg = QiChatConfig.current;
    if (cfg.domain.isEmpty) return '—';
    final urls = cfg.detectUrls.split(',').map((s) => s.trim()).toList();
    for (var i = 0; i < urls.length; i++) {
      final u = urls[i];
      if (u.contains(cfg.domain) || cfg.domain.contains(_hostOf(u))) {
        return '线路${i + 1}';
      }
    }
    return cfg.domain;
  }

  String _hostOf(String url) {
    final stripped = url.replaceAll(RegExp(r'^https?://'), '');
    final slash = stripped.indexOf('/');
    return slash >= 0 ? stripped.substring(0, slash) : stripped;
  }

  String _memberAccount() {
    final cfg = QiChatConfig.current;
    if (cfg.userName.isNotEmpty) return cfg.userName;
    return cfg.userId == 0 ? '—' : cfg.userId.toString();
  }

  Future<void> _saveAsImage() async {
    try {
      final ctx = _cardKey.currentContext;
      if (ctx == null) {
        SmartDialog.showToast('保存失败');
        return;
      }
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        SmartDialog.showToast('保存失败');
        return;
      }
      final name = 'device_info_${DateTime.now().millisecondsSinceEpoch}';
      try {
        await Gal.putImageBytes(bytes, name: name);
        SmartDialog.showToast('已保存到相册');
      } on GalException catch (_) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          SmartDialog.showToast('未授予相册权限');
          return;
        }
        await Gal.putImageBytes(bytes, name: name);
        SmartDialog.showToast('已保存到相册');
      }
    } catch (e) {
      SmartDialog.showToast('保存失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _Row(label: '会员账号', value: _memberAccount()),
      const _Divider(),
      _Row(label: '手机型号', value: _phoneModel),
      const _Divider(),
      _Row(label: '应用名称', value: _appName),
      const _Divider(),
      _Row(label: '手机系统版本', value: _osVersion),
      const _Divider(),
      _Row(label: 'APP当前版本', value: _appVersion),
      const _Divider(),
      _Row(label: '当前时间', value: _now),
      const _Divider(),
      _Row(label: '应用包名', value: _packageName),
      const _Divider(),
      const _Row(label: '登录IP', value: '—', multiLine: true),
      const _Divider(),
      _Row(label: '当前线路', value: _currentLine()),
      const _Divider(),
      const _Row(label: '线路等级', value: '—'),
      const _Divider(),
      const _Row(label: '线路扫描', value: '—', multiLine: true),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('设备信息'),
        backgroundColor: _theme.gradientStartColor,
        foregroundColor: _theme.tintColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '保存为图片',
            icon: const Icon(Icons.save_alt),
            onPressed: _saveAsImage,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: _theme.linearGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: RepaintBoundary(
              key: _cardKey,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// iOS utsname.machine 内部代号 → 营销名映射。
  /// 命中部分主流机型即可；未命中返回 null，由调用方 fallback 原值。
  String? _iosMarketingName(String code) => _kIosMarketingNames[code];
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;

  const _Row({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF9AA0A6),
    );
    const labelStyle = TextStyle(
      fontSize: 15,
      color: Color(0xFF1A1A1A),
      fontWeight: FontWeight.w500,
    );

    if (multiLine) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 8),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
    );
  }
}

const Map<String, String> _kIosMarketingNames = {
  // iPhone 12 系列
  'iPhone13,1': 'iPhone 12 mini',
  'iPhone13,2': 'iPhone 12',
  'iPhone13,3': 'iPhone 12 Pro',
  'iPhone13,4': 'iPhone 12 Pro Max',
  // iPhone 13 系列
  'iPhone14,4': 'iPhone 13 mini',
  'iPhone14,5': 'iPhone 13',
  'iPhone14,2': 'iPhone 13 Pro',
  'iPhone14,3': 'iPhone 13 Pro Max',
  // iPhone 14 系列
  'iPhone14,7': 'iPhone 14',
  'iPhone14,8': 'iPhone 14 Plus',
  'iPhone15,2': 'iPhone 14 Pro',
  'iPhone15,3': 'iPhone 14 Pro Max',
  // iPhone 15 系列
  'iPhone15,4': 'iPhone 15',
  'iPhone15,5': 'iPhone 15 Plus',
  'iPhone16,1': 'iPhone 15 Pro',
  'iPhone16,2': 'iPhone 15 Pro Max',
  // iPhone 16 系列
  'iPhone17,3': 'iPhone 16',
  'iPhone17,4': 'iPhone 16 Plus',
  'iPhone17,1': 'iPhone 16 Pro',
  'iPhone17,2': 'iPhone 16 Pro Max',
  // 模拟器
  'i386': 'iOS Simulator',
  'x86_64': 'iOS Simulator',
  'arm64': 'iOS Simulator',
};
