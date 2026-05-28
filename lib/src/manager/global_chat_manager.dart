import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import 'package:fixnum/fixnum.dart';
import '../Constant.dart';
import '../config.dart';
import 'unread_manager.dart';
import '../model/Custom.dart';

/// 全局聊天管理器（单例模式）
/// 用于在应用的任何地方监听消息，并管理未读消息数
/// 参考 Android 版本的 GlobalChatManager
class GlobalChatManager
    with WidgetsBindingObserver
    implements TeneasySDKDelegate, LineDetectDelegate {
  // 私有构造函数
  GlobalChatManager._();

  // 单例实例
  static final GlobalChatManager _instance = GlobalChatManager._();

  // 获取单例
  static GlobalChatManager get instance => _instance;

  // 未读消息管理器
  final UnreadManager _unreadManager = UnreadManager.instance;

  // 当前打开的聊天页面的consultId，如果为null表示用户不在任何聊天页面
  int? _currentChatConsultId;

  // 是否已初始化
  bool _isInitialized = false;

  // 连接检查定时器
  Timer? _connectionTimer;

  // 连接检查间隔（6秒）
  static const Duration _connectionCheckInterval = Duration(seconds: 6);

  // 线路检测
  LineDetectLib? _lineDetect;
  final StreamController<String> _lineStatusController =
      StreamController<String>.broadcast();
  Completer<bool>? _lineReadyCompleter;

  /// 用户进入某个 consult 的 ChatPage 时 emit consultId
  /// 宿主可借此把"用户用过的 consult"持久化到自己的商户表里
  final StreamController<int> _consultEnteredController =
      StreamController<int>.broadcast();

  /// 线路检测状态文本流（'正在检测...' / '当前线路：xxx' / '无可用线路'）。
  Stream<String> get lineStatusStream => _lineStatusController.stream;

  /// 用户进入聊天页（非空 consultId）时触发的事件流
  Stream<int> get consultEnteredStream => _consultEnteredController.stream;

  /// 线路是否已就绪（domain 非空）。
  bool get isLineReady => QiChatConfig.current.domain.isNotEmpty;

  /// 初始化全局聊天管理器
  void initialize() {
    if (_isInitialized) {
      print('GlobalChatManager: 已经初始化，跳过重复初始化');
      return;
    }

    // 设置ChatLib的delegate为全局管理器
    Constant.instance.chatLib.delegate = this;
    _isInitialized = true;
    print('GlobalChatManager: 已初始化');

    // 注册应用生命周期观察者（要求 WidgetsFlutterBinding.ensureInitialized 已调用）
    WidgetsBinding.instance.addObserver(this);
    // 连接监控由 QiChatUISDK.init 在线路就绪后再启动，避免 domain 为空时空跑
  }

  /// 启动线路检测。若已检测过则直接返回。
  void startLineDetect() {
    if (isLineReady) {
      _lineStatusController.add('当前线路：${QiChatConfig.current.domain}');
      return;
    }
    _lineReadyCompleter ??= Completer<bool>();
    _lineStatusController.add('正在线路检测...');
    print("GlobalChatManager: 启动线路检测 ${QiChatConfig.current.detectUrls} 。。。");
    _lineDetect = LineDetectLib(
      QiChatConfig.current.detectUrls,
      tenantId: QiChatConfig.current.merchantId,
    );
    _lineDetect!.delegate = this;
    _lineDetect!.getLine();
  }

  /// 等待线路就绪。超时返回 false。
  Future<bool> waitLineReady({
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (isLineReady) return Future.value(true);
    _lineReadyCompleter ??= Completer<bool>();
    return _lineReadyCompleter!.future
        .timeout(timeout, onTimeout: () => false);
  }

  /// 根据需要建立连接
  void connectIfNeeded() {
    if (Constant.instance.chatLib.isConnected) {
      print('GlobalChatManager: SDK状态：已连接 ${DateTime.now()}');
      return;
    }

    // 确保domain已设置（使用线路检测得到的 domain）
    final line = QiChatConfig.current.domain;
    if (line.isEmpty) {
      print('GlobalChatManager: domain为空，无法连接');
      return;
    }

    // 检查是否需要初始化SDK
    if (Constant.instance.chatLib.payloadId == 0) {
      print('GlobalChatManager: 初始化SDK连接 ${DateTime.now()}');
      final wssUrl = "wss://$line/v1/gateway/h5";
      print('GlobalChatManager: wssUrl=$wssUrl');

      Constant.instance.chatLib.initialize(
        userId: userId,
        cert: cert,
        token: xToken.isEmpty ? cert : xToken,
        baseUrl: wssUrl,
        sign: "9zgd9YUc",
        custom: getCustomParam(userName, usertype),
        maxSessionMinutes: maxSessionMins,
      );

      try {
        Constant.instance.chatLib.makeConnect();
      } catch (e) {
        print('GlobalChatManager: 连接失败: $e');
      }
    } else {
      print('GlobalChatManager: 重新连接 ${DateTime.now()}');
      try {
        Constant.instance.chatLib.makeConnect();
      } catch (e) {
        print('GlobalChatManager: 重新连接失败: $e');
      }
    }
  }

  /// 开始连接监控
  void startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(_connectionCheckInterval, (timer) {
      connectIfNeeded();
    });
    print('GlobalChatManager: 开始连接监控');
  }

  /// 停止连接监控
  void stopConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    print('GlobalChatManager: 停止连接监控');
  }

  /// 停止全局聊天管理器
  /// 注意：故意不清空 UnreadManager，让多商户切换时其它商户的未读保留下来；
  /// 真正的"已读"清零由 ChatPage 进入时 [UnreadManager.clearUnread] 触发。
  void stop() {
    stopConnectionMonitoring();
    Constant.instance.chatLib.disconnect();
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _lineDetect = null;
    _lineReadyCompleter = null;
    _isInitialized = false;
    print('GlobalChatManager: 全局ChatLib已停止');
  }

  // ========== LineDetectDelegate ==========

  @override
  void useTheLine(String line) {
    QiChatConfig.current.domain = line;
    _lineStatusController.add('当前线路：$line');
    final c = _lineReadyCompleter;
    if (c != null && !c.isCompleted) c.complete(true);
    print('GlobalChatManager: 线路检测成功 $line');
  }

  @override
  void lineError(Result error) {
    if (error.code == 1008) {
      _lineStatusController.add('无可用线路');
    } else {
      _lineStatusController.add('线路检测异常：${error.message}');
    }
    final c = _lineReadyCompleter;
    if (c != null && !c.isCompleted) c.complete(false);
    print('GlobalChatManager: 线路检测失败 ${error.code} ${error.message}');
  }

  // ========== WidgetsBindingObserver ==========

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('GlobalChatManager: 应用恢复，检查连接');
      connectIfNeeded();
    } else if (state == AppLifecycleState.detached) {
      print('GlobalChatManager: 应用 detached，断开连接');
      Constant.instance.chatLib.disconnect();
    }
  }

  /// 设置当前打开的聊天页面的consultId
  /// 当用户进入聊天页面时调用
  void setCurrentChatConsultId(int? consultId) {
    _currentChatConsultId = consultId;
    print('GlobalChatManager: 当前聊天consultId=$consultId');
    if (consultId != null && !_consultEnteredController.isClosed) {
      _consultEnteredController.add(consultId);
    }
  }

  /// 获取当前打开的聊天页面的consultId
  int? getCurrentChatConsultId() {
    return _currentChatConsultId;
  }

  /// 用户是否在指定的聊天页面
  bool isInChatPage(int consultId) {
    return _currentChatConsultId == consultId;
  }

  @override
  void receivedMsg(Message msg) {
    print('GlobalChatManager: 收到消息 consultId=${msg.consultId}, msgId=${msg.msgId}');

    // 获取消息所属的consultId
    int consultId = msg.consultId.toInt();

    // 如果用户不在当前会话的聊天页面，则未读数+1
    if (!isInChatPage(consultId)) {
      // 判断是否是自动回复消息，自动回复消息不计入未读数
      if (msg.msgSourceType != MsgSourceType.MST_SYSTEM_AUTO_TRANSFER) {
        _unreadManager.incrementUnread(consultId);
      } else {
        print('GlobalChatManager: 自动回复消息不计入未读数');
      }
    } else {
      print('GlobalChatManager: 用户正在聊天页面，不计入未读数');
    }

    // 通知其他监听者（如果需要）
    _notifyReceivedMsg(msg);
  }

  @override
  void systemMsg(Result result) {
    if (result.code == 1010){
      GlobalChatManager.instance.stop();
    }
    print('GlobalChatManager: 系统消息 ${result.message}');
    _notifySystemMsg(result);
  }

  @override
  void connected(SCHi c) {
    xToken = c.token;
    print('GlobalChatManager: 连接成功 token=${c.token}');
    _notifyConnected(c);
  }

  @override
  void workChanged(SCWorkerChanged msg) {
    print('GlobalChatManager: 客服变更 consultId=${msg.consultId}');
    _notifyWorkChanged(msg);
  }

  @override
  void msgDeleted(Message msg, Int64 payloadId, String? errMsg) {
    print('GlobalChatManager: 消息删除 msgId=${msg.msgId}');
    _notifyMsgDeleted(msg, payloadId.toInt(), errMsg);
  }

  @override
  void msgReceipt(Message msg, Int64 payloadId, String? errMsg) {
    print('GlobalChatManager: 消息回执 msgId=${msg.msgId}');
    _notifyMsgReceipt(msg, payloadId.toInt(), errMsg);
  }

  // ========== 以下是通知其他监听者的方法 ==========
  // 可以使用StreamController或者回调函数列表来实现
  // 这里暂时使用简单的回调列表

  final List<void Function(Message)> _receivedMsgListeners = [];
  final List<void Function(Result)> _systemMsgListeners = [];
  final List<void Function(SCHi)> _connectedListeners = [];
  final List<void Function(SCWorkerChanged)> _workChangedListeners = [];
  final List<void Function(Message, int, String?)> _msgDeletedListeners = [];
  final List<void Function(Message, int, String?)> _msgReceiptListeners = [];

  /// 添加消息接收监听器
  void addReceivedMsgListener(void Function(Message) listener) {
    if (!_receivedMsgListeners.contains(listener)) {
      _receivedMsgListeners.add(listener);
    }
  }

  /// 移除消息接收监听器
  void removeReceivedMsgListener(void Function(Message) listener) {
    _receivedMsgListeners.remove(listener);
  }

  /// 添加系统消息监听器
  void addSystemMsgListener(void Function(Result) listener) {
    if (!_systemMsgListeners.contains(listener)) {
      _systemMsgListeners.add(listener);
    }
  }

  /// 移除系统消息监听器
  void removeSystemMsgListener(void Function(Result) listener) {
    _systemMsgListeners.remove(listener);
  }

  /// 添加连接成功监听器
  void addConnectedListener(void Function(SCHi) listener) {
    if (!_connectedListeners.contains(listener)) {
      _connectedListeners.add(listener);
    }
  }

  /// 移除连接成功监听器
  void removeConnectedListener(void Function(SCHi) listener) {
    _connectedListeners.remove(listener);
  }

  /// 添加客服变更监听器
  void addWorkChangedListener(void Function(SCWorkerChanged) listener) {
    if (!_workChangedListeners.contains(listener)) {
      _workChangedListeners.add(listener);
    }
  }

  /// 移除客服变更监听器
  void removeWorkChangedListener(void Function(SCWorkerChanged) listener) {
    _workChangedListeners.remove(listener);
  }

  /// 添加消息删除监听器
  void addMsgDeletedListener(void Function(Message, int, String?) listener) {
    if (!_msgDeletedListeners.contains(listener)) {
      _msgDeletedListeners.add(listener);
    }
  }

  /// 移除消息删除监听器
  void removeMsgDeletedListener(void Function(Message, int, String?) listener) {
    _msgDeletedListeners.remove(listener);
  }

  /// 添加消息回执监听器
  void addMsgReceiptListener(void Function(Message, int, String?) listener) {
    if (!_msgReceiptListeners.contains(listener)) {
      _msgReceiptListeners.add(listener);
    }
  }

  /// 移除消息回执监听器
  void removeMsgReceiptListener(void Function(Message, int, String?) listener) {
    _msgReceiptListeners.remove(listener);
  }

  // 通知所有监听者
  void _notifyReceivedMsg(Message msg) {
    for (var listener in _receivedMsgListeners) {
      listener(msg);
    }
  }

  void _notifySystemMsg(Result result) {
    for (var listener in _systemMsgListeners) {
      listener(result);
    }
  }

  void _notifyConnected(SCHi c) {
    for (var listener in _connectedListeners) {
      listener(c);
    }
  }

  void _notifyWorkChanged(SCWorkerChanged msg) {
    for (var listener in _workChangedListeners) {
      listener(msg);
    }
  }

  void _notifyMsgDeleted(Message msg, int payloadId, String? errMsg) {
    for (var listener in _msgDeletedListeners) {
      listener(msg, payloadId, errMsg);
    }
  }

  void _notifyMsgReceipt(Message msg, int payloadId, String? errMsg) {
    for (var listener in _msgReceiptListeners) {
      listener(msg, payloadId, errMsg);
    }
  }

  /// 清空所有监听器
  void clearAllListeners() {
    _receivedMsgListeners.clear();
    _systemMsgListeners.clear();
    _connectedListeners.clear();
    _workChangedListeners.clear();
    _msgDeletedListeners.clear();
    _msgReceiptListeners.clear();
  }
}
