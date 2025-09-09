import 'dart:convert';
import 'dart:io';

import '../Constant.dart';

class Custom {
  String username;
  int platform;
  int userlevel;
  int usertype;

  Custom({required this.username, required this.platform, required this.userlevel, required this.usertype});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'platform': platform,
      'userlevel': userlevel,
      'usertype': usertype
    };
  }
}

String getCustomParam(String userName, int userLevel) {
  // Initialize custom parameters
  Custom custom = Custom(
    username: userName,
    platform: getPlatformCode(),
    userlevel: userLevel,
    usertype: usertype,
  );

  String jsonString = jsonEncode(custom.toJson());
  String encoded = Uri.encodeComponent(jsonString);
  return encoded;
}

int getPlatformCode() {
  if (Platform.isWindows){
    return 6;
  }else if(Platform.isMacOS){
    return 7;
  }else if(Platform.isIOS){
    return 1;
  }else if(Platform.isAndroid){
    return 2;
  }else{
    return 0;
  }
}
