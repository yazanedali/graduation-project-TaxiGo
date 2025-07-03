import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  final List<Map<String, String>> _messages = [
    {"sender": "AI", "message": "مرحبًا! كيف كانت رحلتك؟"},
  ];

  List<Map<String, String>> get messages => _messages;

  void addMessage(String sender, String message) {
    _messages.add({"sender": sender, "message": message});
    notifyListeners();
  }

  String generateAIResponse(String userMessage) {
    String response = '';
    if (userMessage.contains('جيد') || userMessage.contains('ممتاز')) {
      response = "رائع! يبدو أن السائق كان جيدًا. شكرًا لتقييمك.";
    } else if (userMessage.contains('سيء') || userMessage.contains('غير مريح')) {
      response = "آسف لذلك! سنحاول تحسين الخدمة في المستقبل.";
    } else {
      response = "هل يمكنك توضيح أكثر؟";
    }

    return response;
  }
}
