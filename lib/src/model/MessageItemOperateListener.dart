
import 'package:fixnum/src/int64.dart';

abstract class MessageItemOperateListener {
  void onDelete(int position);
  void onCopy(int position);
  void onReSend(int position);
  void onQuote(int position);
  void onSendLocalMsg(String msg, bool isMe, [String msgType = "MSG_TEXT"]);
  void onPlayVideo(String url);
  void onPlayImage(String url);
  void onReply(String val, Int64 replyId);

  /// 点击自动卡片（MST_AUTO_CARD）上的选项时回调：把 [text] 当作普通文本消息真正发送出去。
  void onSendCardOption(String text);
}
