class Entrance {
  String? name;
  String? nick;
  String? avatar;
  String? guide;
  int? defaultConsultId;
  String? changeDefaultTime;
  List<Consults>? consults;

  Entrance(
      {this.name,
        this.nick,
        this.avatar,
        this.guide,
        this.defaultConsultId,
        this.changeDefaultTime,
        this.consults});

  Entrance.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    nick = json['nick'];
    avatar = json['avatar'];
    guide = json['guide'];
    defaultConsultId = json['defaultConsultId'];
    changeDefaultTime = json['changeDefaultTime'];
    if (json['consults'] != null) {
      consults = <Consults>[];
      json['consults'].forEach((v) {
        consults!.add(new Consults.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['nick'] = this.nick;
    data['avatar'] = this.avatar;
    data['guide'] = this.guide;
    data['defaultConsultId'] = this.defaultConsultId;
    data['changeDefaultTime'] = this.changeDefaultTime;
    if (this.consults != null) {
      data['consults'] = this.consults!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Consults {
  int? consultId;
  String? name;
  String? guide;
  List<Works>? works;
  int? unread;
  int? priority;
  int? bindingWorkerId;

  Consults(
      {this.consultId,
        this.name,
        this.guide,
        this.works,
        this.unread,
        this.priority,
        this.bindingWorkerId});

  Consults.fromJson(Map<String, dynamic> json) {
    consultId = json['consultId'];
    name = json['name'];
    guide = json['guide'];
    if (json['Works'] != null) {
      works = <Works>[];
      json['Works'].forEach((v) {
        works!.add(new Works.fromJson(v));
      });
    }
    unread = json['unread'];
    priority = json['priority'];
    bindingWorkerId = json['bindingWorkerId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['consultId'] = this.consultId;
    data['name'] = this.name;
    data['guide'] = this.guide;
    if (this.works != null) {
      data['Works'] = this.works!.map((v) => v.toJson()).toList();
    }
    data['unread'] = this.unread;
    data['priority'] = this.priority;
    data['bindingWorkerId'] = this.bindingWorkerId;
    return data;
  }
}

class Works {
  String? nick;
  String? avatar;
  int? workerId;
  String? nimId;
  String? connectState;
  String? onlineState;

  Works(
      {this.nick,
        this.avatar,
        this.workerId,
        this.nimId,
        this.connectState,
        this.onlineState});

  Works.fromJson(Map<String, dynamic> json) {
    nick = json['nick'];
    avatar = json['avatar'];
    workerId = json['workerId'];
    nimId = json['nimId'];
    connectState = json['connectState'];
    onlineState = json['onlineState'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['nick'] = this.nick;
    data['avatar'] = this.avatar;
    data['workerId'] = this.workerId;
    data['nimId'] = this.nimId;
    data['connectState'] = this.connectState;
    data['onlineState'] = this.onlineState;
    return data;
  }
}
