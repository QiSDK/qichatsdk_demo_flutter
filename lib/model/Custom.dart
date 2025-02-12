import 'dart:convert';
import 'dart:io';

class Custom {
  String username;
  int platform;
  int userlevel;

  Custom({required this.username, required this.platform, required this.userlevel});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'platform': platform,
      'userlevel': userlevel,
    };
  }
}

String getCustomParam(String userName, int userLevel) {
  // Initialize custom parameters
  Custom custom = Custom(
    username: userName,
    platform: getPlatformCode(),
    userlevel: userLevel,
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
