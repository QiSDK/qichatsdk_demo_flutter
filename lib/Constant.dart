import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qichatsdk_flutter/src/ChatLib.dart';


import 'package:intl/intl.dart';

const String PARAM_USER_ID = "USER_ID";
const String PARAM_CERT = "CERT";
const String PARAM_MERCHANT_ID = "MERCHANT_ID";
const String PARAM_LINES = "LINES";
const String PARAM_ImageBaseURL = "IMAGEURL";

// These are the values to be configured in settings
String lines = "https://csapi.hfxg.xyz,https://xxx.qixin14.xxx";
//String cert = "COYBEAIYwNgoIPIBKIOzgtGXMg.-t5P7JEo-Dg7nlJpu6uZzNJE3QtRaJV9bE1yhZqduThDLHE6MGxCBFuwF38v5z5SJhoD40fmwAtPj4iIL9iPAQ";
String cert = "COgBEAUYASDzASitlJSF9zE.5uKWeVH-7G8FIgkaLIhvzCROkWr4D3pMU0-tqk58EAQcLftyD2KBMIdYetjTYQEyQwWLy7Lfkm8cs3aogaThAw";
int merchantId = 230;
int userId = 666665; // Example: 1125324
String baseUrlImage = "https://sssacc.wwc09.com"; // For constructing image URLs

String xToken = "";
String domain = "";  // Domain
String baseUrlApi = "https://$domain";  // For data requests and image uploads
int workerId = 2;
String userName ='王五';
int maxSessionMins = 5;

// Unsent messages list
Map<int, List<ChatModel>> unSentMessage = {999: []};

ReportRequest reportRequest = ReportRequest();

const String PARAM_XTOKEN = "HTTPTOKEN";

const String serverTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'";

// UI constants
const double iconWidth = 38.0;
const double imgHeight = 114.0;
const Color titleColour = Color(0xFF484848);
const Color timeColor = Color(0xFFC4C4C4);

const Color chatBackColor = Colors.grey;
const Color panelBack = Colors.lightBlueAccent;

const String serverDateFormat = "yyyy-MM-dd'T'HH:mm:ssZ";

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
  var isConnected = false;

  // Mock of the utility method to convert a Date to the system zone
  static DateTime converDateToSystemZoneDate(DateTime date) {
    // Assuming system timezone conversion logic here
    return date.toLocal();
  }




}