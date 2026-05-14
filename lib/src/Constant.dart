import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_qichat_sdk/src/ChatLib.dart';
import 'package:flutter_qichat_sdk/src/dartOut/api/common/c_message.pb.dart'
as cmessage;
import 'package:fixnum/src/int64.dart';
import 'package:intl/intl.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'model/Entrance.dart';

const String PARAM_USER_ID = "USER_ID";
const String PARAM_CERT = "CERT";
const String PARAM_MERCHANT_ID = "MERCHANT_ID";
const String PARAM_LINES = "LINES";
const String PARAM_ImageBaseURL = "IMAGEURL";
const String PARAM_USERTYPE = "USERTYPE";

// These are the values to be configured in settings

//String cert = "COEBEAUYASDjASiewpj-8TE.-1R9Mw9xzDNrSxoQ5owopxciklACjBUe43NANibVuy-XPlhqnhAOEaZpxjvTyJ6n79P5bUBCGxO7PcEFQ9p9Cg";
//String cert = "COgBEAUYASDzASitlJSF9zE.5uKWeVH-7G8FIgkaLIhvzCROkWr4D3pMU0-tqk58EAQcLftyD2KBMIdYetjTYQEyQwWLy7Lfkm8cs3aogaThAw";
//String cert = "COYBEAUYASDyASiG2piD9zE.te46qua5ha2r-Caz03Vx2JXH5OLSRRV2GqdYcn9UslwibsxBSP98GhUKSGEI0Z84FRMkp16ZK8eS-y72QVE2AQ";
int merchantId = 230;
int userId = 666667; // Example: 1125324

String lines = "https://csapi.hfxg.xyz,https://xxx.qixin14.xxx";
String baseUrlImage = "https://imagesacc.hfxg.xyz"; // For constructing image URLs
String cert = "COYBEAIYwNgoIPIBKIOzgtGXMg.-t5P7JEo-Dg7nlJpu6uZzNJE3QtRaJV9bE1yhZqduThDLHE6MGxCBFuwF38v5z5SJhoD40fmwAtPj4iIL9iPAQ";

// String cert = "CAEQBRgBIIcCKPHr3dPoMg.ed_euM3a4Ew7QTiJKg4XQskD5KTzvqXdFKRPnVyNmyZNF-Cyq7g9XMr3a41OvVtoovp15IBrfYveDZTJPEldBA";
// String lines = "https://d2jt4g8mgfvbcl.cloudfront.net";
// String baseUrlImage = "https://d2uzsk40324g7l.cloudfront.net";

String xToken = "";
String domain = "";  // Domain
//String baseUrlApi = "https://$domain";  // For data requests and image uploads

String baseUrlApi(){
  return "https://$domain";
}
//int workerId = -1;
String userName ='王五';
int maxSessionMins = 300;
int usertype = 2;

// Unsent messages list
Map<Int64, List<types.Message>> unSentMessage = {Int64(0): []};
//List<types.Message>? unSentMessage;

ReportRequest reportRequest = ReportRequest();

const String PARAM_XTOKEN = "HTTPTOKEN";

const String serverTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'";
Entrance? entrance;

// UI constants
const double iconWidth = 38.0;
const double imgHeight = 114.0;
const Color titleColour = Color(0xFF484848);
const Color timeColor = Color(0xFFC4C4C4);

const Color chatBackColor = Colors.grey;
const Color panelBack = Colors.lightBlueAccent;

const String serverDateFormat = "yyyy-MM-dd'T'HH:mm:ssZ";

//var withAutoReplyBuilder = cmessage.WithAutoReply();
cmessage.WithAutoReply? withAutoReplyBuilder;

// Function to convert a date string to another formatted string
String convertDateStringToString(String datStr) {
  DateTime? date = stringToDate(datStr, serverDateFormat);
  if (date != null) {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(date);
  } else {
    return datStr;
  }
}

// Function to convert a string to DateTime
DateTime? stringToDate(String datStr, [String format = serverDateFormat]) {
  try {
    return DateFormat(format).parse(datStr);
  } catch (e) {
    return null;
  }
}

// Function to convert a string to Google Protobuf Timestamp
GoogleProtobufTimestamp stringToTimeStamp(String datStr) {
  DateTime date = stringToDate(datStr, serverTimeFormat) ?? DateTime.now();
  DateTime localDate = Constant.converDateToSystemZoneDate(date);
  return intervalToTimeStamp(localDate.millisecondsSinceEpoch / 1000);
}

// Function to convert TimeInterval to GoogleProtobufTimestamp
GoogleProtobufTimestamp intervalToTimeStamp(double timeInterval) {
  int seconds = timeInterval.toInt();
  //int nanos = ((timeInterval - seconds) * 1_000_000_000).toInt();
  return GoogleProtobufTimestamp(seconds: seconds, nanos: 0);
}

// Function to delay execution
void delayExecution(double seconds, Function completion) {
  Future.delayed(Duration(seconds: seconds.toInt()), () {
    completion();
  });
}

// Example models for ReportRequest and GoogleProtobufTimestamp
class ReportRequest {
  // Define the structure for ReportRequest if needed
}

class ChatModel {
  // Define the structure for ChatModel if needed
}

class GoogleProtobufTimestamp {
  int seconds;
  int nanos;

  GoogleProtobufTimestamp({required this.seconds, required this.nanos});
}


class Constant {
  static Constant? _instance;

  Constant._();

  static Constant get instance => _instance ??= Constant._();

  var chatLib = ChatLib();
  //var isConnected = false;
  var chatId = '0';

  // Mock of the utility method to convert a Date to the system zone
  static DateTime converDateToSystemZoneDate(DateTime date) {
    // Assuming system timezone conversion logic here
    return date.toLocal();
  }
}