import 'dart:ui';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_qichat_sdk/flutter_qichat_sdk.dart';
import 'package:flutter_qichat_sdk/src/dartOut/api/common/c_message.pb.dart'
    as cmessage;
import 'package:intl/intl.dart';

import 'config.dart';
import 'model/Entrance.dart';

// SharedPreferences 持久化键。仅 example demo 使用——SDK 通过 init() 直接传值。
const String PARAM_USER_ID = "USER_ID";
const String PARAM_CERT = "CERT";
const String PARAM_MERCHANT_ID = "MERCHANT_ID";
const String PARAM_LINES = "LINES";
const String PARAM_ImageBaseURL = "IMAGEURL";
const String PARAM_USERTYPE = "USERTYPE";
const String PARAM_XTOKEN = "HTTPTOKEN";

// ===========================================================================
// 顶层兼容访问器：转发到 QiChatConfig.current。
//
// 为避免重写约 90 处历史引用（cert / userId / xToken / domain ...），保留
// 顶层名称作为 getter/setter；真实状态在 QiChatConfig。新代码请直接使用
// QiChatConfig.current.X。
// ===========================================================================

String get cert => QiChatConfig.current.cert;
set cert(String v) => QiChatConfig.current.cert = v;

int get userId => QiChatConfig.current.userId;
set userId(int v) => QiChatConfig.current.userId = v;

String get userName => QiChatConfig.current.userName;
set userName(String v) => QiChatConfig.current.userName = v;

int get merchantId => QiChatConfig.current.merchantId;
set merchantId(int v) => QiChatConfig.current.merchantId = v;

String get tenantName => QiChatConfig.current.tenantName;
set tenantName(String v) => QiChatConfig.current.tenantName = v;

String get lines => QiChatConfig.current.detectUrls;
set lines(String v) => QiChatConfig.current.detectUrls = v;

String get baseUrlImage => QiChatConfig.current.baseUrlImage;
set baseUrlImage(String v) => QiChatConfig.current.baseUrlImage = v;

int get maxSessionMins => QiChatConfig.current.maxSessionMinutes;
set maxSessionMins(int v) => QiChatConfig.current.maxSessionMinutes = v;

int get usertype => QiChatConfig.current.userType;
set usertype(int v) => QiChatConfig.current.userType = v;

String get xToken => QiChatConfig.current.xToken;
set xToken(String v) => QiChatConfig.current.xToken = v;

String get domain => QiChatConfig.current.domain;
set domain(String v) => QiChatConfig.current.domain = v;

Entrance? get entrance => QiChatConfig.current.entrance;
set entrance(Entrance? v) => QiChatConfig.current.entrance = v;

cmessage.WithAutoReply? get withAutoReplyBuilder =>
    QiChatConfig.current.withAutoReplyBuilder;
set withAutoReplyBuilder(cmessage.WithAutoReply? v) =>
    QiChatConfig.current.withAutoReplyBuilder = v;

Map<Int64, List<types.Message>> get unSentMessage =>
    QiChatConfig.current.unSentMessage;

ReportRequest get reportRequest => QiChatConfig.current.reportRequest;

String baseUrlApi() => QiChatConfig.current.baseUrlApi;

// ===========================================================================
// 时间与日期工具
// ===========================================================================

const String serverTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'";
const String serverDateFormat = "yyyy-MM-dd'T'HH:mm:ssZ";

String convertDateStringToString(String datStr) {
  DateTime? date = stringToDate(datStr, serverDateFormat);
  if (date != null) {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(date);
  } else {
    return datStr;
  }
}

DateTime? stringToDate(String datStr, [String format = serverDateFormat]) {
  try {
    return DateFormat(format).parse(datStr);
  } catch (e) {
    return null;
  }
}

GoogleProtobufTimestamp stringToTimeStamp(String datStr) {
  DateTime date = stringToDate(datStr, serverTimeFormat) ?? DateTime.now();
  DateTime localDate = Constant.converDateToSystemZoneDate(date);
  return intervalToTimeStamp(localDate.millisecondsSinceEpoch / 1000);
}

GoogleProtobufTimestamp intervalToTimeStamp(double timeInterval) {
  int seconds = timeInterval.toInt();
  return GoogleProtobufTimestamp(seconds: seconds, nanos: 0);
}

void delayExecution(double seconds, Function completion) {
  Future.delayed(Duration(seconds: seconds.toInt()), () {
    completion();
  });
}

class ChatModel {
  // 历史占位
}

class GoogleProtobufTimestamp {
  int seconds;
  int nanos;

  GoogleProtobufTimestamp({required this.seconds, required this.nanos});
}

// ===========================================================================
// UI 常量
// ===========================================================================

const double iconWidth = 38.0;
const double imgHeight = 114.0;
const Color titleColour = Color(0xFF484848);
const Color timeColor = Color(0xFFC4C4C4);
const Color chatBackColor = Colors.grey;
const Color panelBack = Colors.lightBlueAccent;

// ===========================================================================
// Constant 单例。历史代码用 Constant.instance.chatLib 访问 ChatLib，
// 现转发到 QiChatConfig.current.chatLib，保证全局唯一。
// ===========================================================================

class Constant {
  static Constant? _instance;

  Constant._();

  static Constant get instance => _instance ??= Constant._();

  ChatLib get chatLib => QiChatConfig.current.chatLib;

  String get chatId => QiChatConfig.current.chatId;
  set chatId(String v) => QiChatConfig.current.chatId = v;

  static DateTime converDateToSystemZoneDate(DateTime date) {
    return date.toLocal();
  }
}
