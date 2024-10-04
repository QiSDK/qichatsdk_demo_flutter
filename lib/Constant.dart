import 'package:qichatsdk_flutter/src/ChatLib.dart';


class Constant {
  static Constant? _instance;

  Constant._();

  static Constant get instance => _instance ??= Constant._();

  var chatLib = ChatLib();
  var isConnected = false;
}