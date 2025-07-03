import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final String _baseUrl = '${dotenv.env['BASE_URL']}/api/notifications';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'Bearer YOUR_TOKEN', // استبدل YOUR_TOKEN بالتوكين الحقيقي إذا كنت تستخدم مصادقة
  };

  static Future<List<dynamic>> getUnreadNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/unread?userId=$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load unread notifications');
    }
  }

  static Future<bool> markAsRead(int notificationId, int userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$notificationId/read'),
      headers: _headers,
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] == true;
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<int> getUnreadCount(int userId, String userType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/unread-count?userId=$userId&userType=$userType'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['count'];
    } else {
      throw Exception('Failed to fetch unread count');
    }
  }

  static Future<List<dynamic>> getAllNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?userId=$userId'),
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<bool> deleteNotification(int notificationId, int userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$notificationId'),
      headers: _headers,
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] == true;
    } else {
      throw Exception('Failed to delete notification');
    }
  }
}
