import 'Sync.dart';

class ReplyList {
  List<MsgItem>? replyList;

  ReplyList({this.replyList});

  ReplyList.fromJson(Map<String, dynamic> json) {
    if (json['replyList'] != null) {
      replyList = <MsgItem>[];
      json['replyList'].forEach((v) {
        replyList!.add(new MsgItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.replyList != null) {
      data['replyList'] = this.replyList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}