import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';
//import 'package:qichatsdk_flutter/src/dartOut/gateway/g_gateway.pb.dart';


class QiChatListener implements TeneasySDKDelegate {

  // 页面携带参数
  // 回调：收到客服发来的消息
  final void Function(Message) onReceivedMsg;
  // 回调：收到系统消息
  final void Function(Result) onSystemMsg;
  // 回调：连接成功
  final void Function(SCHi) onConnected;
  // 回调：客服变更
  final void Function(SCWorkerChanged) onWorkChanged;
  // 回调：消息删除
  final void Function(Message, int, String?) onMsgDeleted;
  // 回调：消息回执
  final void Function(Message, int, String?) onMsgReceipt;

  static QiChatListener? _instance;

  factory QiChatListener({
    required void Function(Message) onReceivedMsg,
    required void Function(Result) onSystemMsg,
    required void Function(SCHi) onConnected,
    required void Function(SCWorkerChanged) onWorkChanged,
    required void Function(Message, int, String?) onMsgDeleted,
    required void Function(Message, int, String?) onMsgReceipt,
  }) {
    _instance ??= QiChatListener._internal(
      onReceivedMsg: onReceivedMsg,
      onSystemMsg: onSystemMsg,
      onConnected: onConnected,
      onWorkChanged: onWorkChanged,
      onMsgDeleted: onMsgDeleted,
      onMsgReceipt: onMsgReceipt,
    );
    return _instance!;
  }

  QiChatListener._internal({
    required this.onReceivedMsg,
    required this.onSystemMsg,
    required this.onConnected,
    required this.onWorkChanged,
    required this.onMsgDeleted,
    required this.onMsgReceipt,
  });

  @override
  void receivedMsg(msg) {
    //MyLogger.w("收到客服发来的消息: $msg");
    onReceivedMsg.call(msg);
  }

  @override
  void systemMsg(result) {
    //MyLogger.w("系统消息: ${result.message}");
    onSystemMsg.call(result);
  }

  @override
  void connected(c) async {
    //MyLogger.w("起聊连接成功 -> token: ${c.token}");
    onConnected.call(c);
  }

  @override
  void workChanged(msg) {
    //MyLogger.w("客服更改为 -> Consult ID: ${msg.consultId}");
    onWorkChanged.call(msg);

    // $core.int? workerId,
    // $core.String? workerName,
    // $core.String? workerAvatar,
    // $fixnum.Int64? target,
    // WorkerChangedReason? reason,
    // $fixnum.Int64? consultId,
  }

  @override
  void msgDeleted(msg, payloadId, errMsg) {
    //MyLogger.w("删除成功: ${msg.msgId} ");
    //onMsgDeleted.call(msg, payloadId.toString().toInt(), errMsg);
  }

  @override
  void msgReceipt(msg, payloadId, errMsg) {
    //MyLogger.w("收到回执 payloadId:$payloadId msgId: ${msg.msgId}");
    //onMsgReceipt.call(msg, payloadId.toString().toInt(), errMsg);
  }
}
