
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qichatsdk_flutter/qichatsdk_flutter.dart';

class Sync {
  Request? request;
  List<MsgItem>? list;
  String? lastMsgId;
  String? nick;
  List<MsgItem>? replyList;

  Sync({this.request, this.list, this.lastMsgId, this.nick, this.replyList});

  Sync.fromJson(Map<String, dynamic> json) {
    request =
    json['request'] != null ? new Request.fromJson(json['request']) : null;
    if (json['list'] != null) {
      list = <MsgItem>[];
      json['list'].forEach((v) {
        list!.add(new MsgItem.fromJson(v));
      });
    }
    lastMsgId = json['lastMsgId'];
    nick = json['nick'];
    if (json['replyList'] != null) {
      replyList = <MsgItem>[];
      json['replyList'].forEach((v) {
        replyList!.add(new MsgItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.request != null) {
      data['request'] = this.request!.toJson();
    }
    if (this.list != null) {
      data['list'] = this.list!.map((v) => v.toJson()).toList();
    }
    data['lastMsgId'] = this.lastMsgId;
    data['nick'] = this.nick;
    if (this.replyList != null) {
      data['replyList'] = this.replyList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Request {
  String? chatId;
  String? msgId;
  int? count;
  bool? withLastOne;
  int? workerId;
  int? consultId;
  int? userId;

  Request(
      {this.chatId,
        this.msgId,
        this.count,
        this.withLastOne,
        this.workerId,
        this.consultId,
        this.userId});

  Request.fromJson(Map<String, dynamic> json) {
    chatId = json['chatId'];
    msgId = json['msgId'];
    count = json['count'];
    withLastOne = json['withLastOne'];
    workerId = json['workerId'];
    consultId = json['consultId'];
    userId = json['userId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatId'] = this.chatId;
    data['msgId'] = this.msgId;
    data['count'] = this.count;
    data['withLastOne'] = this.withLastOne;
    data['workerId'] = this.workerId;
    data['consultId'] = this.consultId;
    data['userId'] = this.userId;
    return data;
  }
}

class MsgItem {
  String? chatId;
  String? msgId;
  String? msgTime;
  String? sender;
  String? replyMsgId;
  String? msgOp;
  int? worker;
  Null? autoReplyFlag;
  String? msgFmt;
  String? consultId;
  List<WithAutoReplies>? withAutoReplies;
  String? msgSourceType;
  String? payloadId;
  Content? content;
  Media? image;
  Urls? video;
  Urls? file;
  WorkerChanged? workerChanged;

  MsgItem(
      {this.chatId,
        this.msgId,
        this.msgTime,
        this.sender,
        this.replyMsgId,
        this.msgOp,
        this.worker,
        this.autoReplyFlag,
        this.msgFmt,
        this.consultId,
        this.withAutoReplies,
        this.msgSourceType,
        this.payloadId,
        this.content,
        this.image,
        this.video,
        this.file,
        this.workerChanged
      });

  MsgItem.fromJson(Map<String, dynamic> json) {
    chatId = json['chatId'];
    msgId = json['msgId'];
    msgTime = json['msgTime'];
    sender = json['sender'];
    replyMsgId = json['replyMsgId'];
    msgOp = json['msgOp'];
    worker = json['worker'];
    autoReplyFlag = json['autoReplyFlag'];
    msgFmt = json['msgFmt'];
    consultId = json['consultId'];
    if (json['withAutoReplies'] != null) {
      withAutoReplies = <WithAutoReplies>[];
      json['withAutoReplies'].forEach((v) {
        withAutoReplies!.add(new WithAutoReplies.fromJson(v));
      });
    }
    msgSourceType = json['msgSourceType'];
    payloadId = json['payloadId'];
    image =
    json['image'] != null ? new Media.fromJson(json['image']) : null;
    video =
    json['video'] != null ? new Urls.fromJson(json['video']) : null;
    file =
    json['file'] != null ? new Urls.fromJson(json['file']) : null;
    content =
    json['content'] != null ? new Content.fromJson(json['content']) : null;
    workerChanged =
    json['workerChanged'] != null ? new WorkerChanged.fromJson(json['workerChanged']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatId'] = this.chatId;
    data['msgId'] = this.msgId;
    data['msgTime'] = this.msgTime;
    data['sender'] = this.sender;
    data['replyMsgId'] = this.replyMsgId;
    data['msgOp'] = this.msgOp;
    data['worker'] = this.worker;
    data['autoReplyFlag'] = this.autoReplyFlag;
    data['msgFmt'] = this.msgFmt;
    data['consultId'] = this.consultId;
    if (this.withAutoReplies != null) {
      data['withAutoReplies'] =
          this.withAutoReplies!.map((v) => v.toJson()).toList();
    }
    data['msgSourceType'] = this.msgSourceType;
    data['payloadId'] = this.payloadId;
    if (this.content != null) {
      data['content'] = this.content!.toJson();
    }
    if (this.image != null) {
      data['image'] = this.image!.toJson();
    }
    if (this.video != null) {
      data['video'] = this.video!.toJson();
    }
    if (this.file != null) {
      data['file'] = this.file!.toJson();
    }

    if (this.workerChanged != null) {
      data['workerChanged'] = this.workerChanged!.toJson();
    }
    return data;
  }
}

class WithAutoReplies {
  String? id;
  String? title;
  String? createdTime;
  List<Answers>? answers;

  WithAutoReplies({this.id, this.title, this.createdTime, this.answers});

  WithAutoReplies.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    createdTime = json['createdTime'];
    if (json['answers'] != null) {
      answers = <Answers>[];
      json['answers'].forEach((v) {
        answers!.add(new Answers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['createdTime'] = this.createdTime;
    if (this.answers != null) {
      data['answers'] = this.answers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Answers {
  Content? content;

  Answers({this.content});

  Answers.fromJson(Map<String, dynamic> json) {
    content =
    json['content'] != null ? new Content.fromJson(json['content']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.content != null) {
      data['content'] = this.content!.toJson();
    }
    return data;
  }
}

class Content {
  String? data;

  Content({this.data});

  Content.fromJson(Map<String, dynamic> json) {
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    return data;
  }
}


class Media {
  String? uri;

  Media({this.uri});

  Media.fromJson(Map<String, dynamic> json) {
    uri = json['uri'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uri'] = this.uri;
    return data;
  }
}

class WorkerChanged {
  String? workerClientId;
  int? workerId;
  String? name;
  String? avatar;
  String? greeting;
  String? state;
  String? consultId;

  WorkerChanged(
      {this.workerClientId,
        this.workerId,
        this.name,
        this.avatar,
        this.greeting,
        this.state,
        this.consultId});

  WorkerChanged.fromJson(Map<String, dynamic> json) {
    workerClientId = json['workerClientId'];
    workerId = json['workerId'];
    name = json['name'];
    avatar = json['avatar'];
    greeting = json['greeting'];
    state = json['State'];
    consultId = json['consultId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['workerClientId'] = this.workerClientId;
    data['workerId'] = this.workerId;
    data['name'] = this.name;
    data['avatar'] = this.avatar;
    data['greeting'] = this.greeting;
    data['State'] = this.state;
    data['consultId'] = this.consultId;
    return data;
  }
}