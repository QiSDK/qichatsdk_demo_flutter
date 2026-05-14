import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class TipMessage extends StatelessWidget {
  final types.Message message;

  const TipMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.metadata != null && message.metadata!['isSystemMessage'] == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                message.metadata!['tipText'] ?? '',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
