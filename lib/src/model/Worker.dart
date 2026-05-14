class Worker {
  String? nick;
  String? avatar;
  int? workerId;
  String? nimid;
  String? tips;
  String? chatId;

  Worker(
      {this.nick,
        this.avatar,
        this.workerId,
        this.nimid,
        this.tips,
        this.chatId});

  Worker.fromJson(Map<String, dynamic> json) {
    nick = json['nick'];
    avatar = json['avatar'];
    workerId = json['workerId'];
    nimid = json['nimid'];
    tips = json['tips'];
    chatId = json['chatId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['nick'] = this.nick;
    data['avatar'] = this.avatar;
    data['workerId'] = this.workerId;
    data['nimid'] = this.nimid;
    data['tips'] = this.tips;
    data['chatId'] = this.chatId;
    return data;
  }
}