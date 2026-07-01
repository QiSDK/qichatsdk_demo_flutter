
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

  /// 点击带 `jumpUrl` 的自动卡片按钮时回调：请求「打开」小程序页面。
  ///
  /// [jumpUrl] 为小程序页面路径（如 `pages/Withdraw/Record`），[jumpCategory]
  /// 为跳转类型。具体如何打开由宿主注册的处理器决定，未注册时 SDK 用内置模拟页兜底。
  void onCardJump(String jumpUrl, int? jumpCategory);
}
