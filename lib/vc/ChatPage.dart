import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'dart:math';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final _user = types.User(id: 'user1'); // Local user ID

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    // Load any initial messages if needed, or keep it empty for a new chat
    setState(() {
      _messages.addAll([
        types.TextMessage(
          author: _user,
          id: _generateRandomId(),
          text: 'Hello! How can I help you today?',
        ),
      ]);
    });
  }

  String _generateRandomId() {
    return Random().nextInt(1000000).toString();
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      id: _generateRandomId(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        disableImageGallery: false,
        user: _user,
        theme: const DefaultChatTheme(
          inputBackgroundColor: Colors.lightBlue,
          primaryColor: Colors.blueAccent,
        ),
      ),
    );
  }
}
