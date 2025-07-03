import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxi_app/models/message.dart';
import 'package:taxi_app/config/api_config.dart';

class ChatApi {
  static Future<List<Message>> getMessages({
    required String sender,
    required String receiver,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/messages?sender=$sender&receiver=$receiver'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  static Future<Message> sendMessage({
    required String sender,
    required String receiver,
    required String senderType,
    required String receiverType,
    required String message,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'sender': sender,
        'receiver': receiver,
        'senderType': senderType,
        'receiverType': receiverType,
        'message': message,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Message.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
} 