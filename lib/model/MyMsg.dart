class MyMsg {
  String? imgUri;
  String? videoUri;
  String? text;
  String? senderId;
  String? msgId;
  DateTime? msgTime;

  MyMsg({
    this.imgUri,
    this.videoUri,
    this.text,
    this.senderId,
    this.msgId,
    this.msgTime,
  });

  MyMsg.fromJson(Map<String, dynamic> json) {
    imgUri = json['imgUri'];
    videoUri = json['videoUri'];
    text = json['text'];
    senderId = json['senderId'];
    msgId = json['msgId'];
    msgTime = json['msgTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imgUri'] = this.imgUri;
    data['videoUri'] = this.videoUri;
    data['text'] = this.text;
    data['senderId'] = this.senderId;
    data['msgId'] = this.msgId;
    data['msgTime'] = this.msgTime;

    return data;
  }
}
