
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
}
