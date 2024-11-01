import 'dart:ffi';
import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:qichatsdk_demo_flutter/model/Sync.dart';

class AutoReply {
  AutoReplyItem? autoReplyItem;

  AutoReply({this.autoReplyItem});

  AutoReply.fromJson(Map<String, dynamic> json) {
    autoReplyItem = json['autoReplyItem'] != null
        ? new AutoReplyItem.fromJson(json['autoReplyItem'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.autoReplyItem != null) {
      data['autoReplyItem'] = this.autoReplyItem!.toJson();
    }
    return data;
  }
}

class AutoReplyItem {
  String? id;
  String? name;
  String? title;
  List<Qa>? qa;
  int? delaySec;
  List<Int64>? workerId;
  List<String>? workerNames;

  AutoReplyItem(
      {this.id,
      this.name,
      this.title,
      this.qa,
      this.delaySec,
      this.workerId,
      this.workerNames});

  AutoReplyItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    title = json['title'];
    if (json['qa'] != null) {
      qa = <Qa>[];
      json['qa'].forEach((v) {
        qa!.add(new Qa.fromJson(v));
      });
    }
    delaySec = json['delaySec'];
    // if (json['workerId'] != null) {
    //   workerId = <Int64>[];
    //   json['workerId'].forEach((v) {
    //     workerId!.add(new Int64.fromJson(v));
    //   });
    // }
    // if (json['workerNames'] != null) {
    //   workerNames = <Null>[];
    //   json['workerNames'].forEach((v) {
    //     workerNames!.add(new Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['title'] = this.title;
    if (this.qa != null) {
      data['qa'] = this.qa!.map((v) => v.toJson()).toList();
    }
    data['delaySec'] = this.delaySec;
    // if (this.workerId != null) {
    //   data['workerId'] = this.workerId!.map((v) => v.toJson()).toList();
    // }
    // if (this.workerNames != null) {
    //   data['workerNames'] = this.workerNames!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Qa {
  Int64? id;
  bool clicked = false;
  Question? question;
  String? content;
  List<Question>? answer;
  List<Related>? related;
  bool? isExpanded;

  Qa({this.id, this.question, this.content, this.answer, this.related});

  Qa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    question = json['question'] != null
        ? new Question.fromJson(json['question'])
        : null;
    content = json['content'];
    if (json['answer'] != null) {
      answer = <Question>[];
      json['answer'].forEach((v) {
        answer!.add(new Question.fromJson(v));
      });
    }
    if (json['related'] != null) {
      related = <Related>[];
      json['related'].forEach((v) {
        related!.add(new Related.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.question != null) {
      data['question'] = this.question!.toJson();
    }
    data['content'] = this.content;
    if (this.answer != null) {
      data['answer'] = this.answer!.map((v) => v.toJson()).toList();
    }
    if (this.related != null) {
      data['related'] = this.related!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Question {
  String? chatId;
  String? msgId;
  Null? msgTime;
  String? sender;
  String? replyMsgId;
  String? msgOp;
  int? worker;
  Null? autoReplyFlag;
  String? msgFmt;
  String? consultId;
  List<Null>? withAutoReplies;
  String? msgSourceType;
  String? payloadId;
  Content? content;

  Question(
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
      this.content});

  Question.fromJson(Map<String, dynamic> json) {
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
    // if (json['withAutoReplies'] != null) {
    //   withAutoReplies = <Null>[];
    //   json['withAutoReplies'].forEach((v) {
    //     withAutoReplies!.add(new Null.fromJson(v));
    //   });
    // }
    msgSourceType = json['msgSourceType'];
    payloadId = json['payloadId'];
    content =
        json['content'] != null ? new Content.fromJson(json['content']) : null;
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
    // if (this.withAutoReplies != null) {
    //   data['withAutoReplies'] =
    //       this.withAutoReplies!.map((v) => v.toJson()).toList();
    // }
    data['msgSourceType'] = this.msgSourceType;
    data['payloadId'] = this.payloadId;
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

class Related {
  int? id;
  Question? question;
  String? content;
  List<Question>? answer;

  Related({this.id, this.question, this.content, this.answer});

  Related.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    question = json['question'] != null
        ? new Question.fromJson(json['question'])
        : null;
    content = json['content'];
    if (json['answer'] != null) {
      answer = <Question>[];
      json['answer'].forEach((v) {
        answer!.add(new Question.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.question != null) {
      data['question'] = this.question!.toJson();
    }
    data['content'] = this.content;
    if (this.answer != null) {
      data['answer'] = this.answer!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
