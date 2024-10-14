import 'dart:convert';

class Custom {
  String username;
  int platform;
  String userlevel;

  Custom({required this.username, required this.platform, required this.userlevel});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'platform': platform,
      'userlevel': userlevel,
    };
  }
}

String getCustomParam(String userName, int userLevel, int platform) {
  // Initialize custom parameters
  Custom custom = Custom(
    username: userName,
    platform: platform,
    userlevel: userLevel.toString(),
  );

  String jsonString = jsonEncode(custom.toJson());
  String encoded = Uri.encodeComponent(jsonString);
  return encoded;
}
