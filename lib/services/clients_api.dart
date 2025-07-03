import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/models/client.dart'; // تأكد من وجود هذا النموذج

class ClientsApi {
     static final String _baseUrl = '${dotenv.env['BASE_URL']}/api';

  /// جلب جميع العملاء
  static Future<List<Client>> getAllClients() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clients'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> clientsJson = json.decode(response.body);
        return clientsJson.map((json) => Client.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load clients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all clients: $e');
      throw Exception('Failed to load clients. Please try again later.');
    }
  }

  /// جلب العملاء المتاحين (إذا كان هناك مفهوم "التوفر" عند العميل)
  static Future<List<Client>> getAvailableClients() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clients/available'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> clientsJson = json.decode(response.body);
        return clientsJson.map((json) => Client.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load available clients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching available clients: $e');
      throw Exception(
          'Failed to load available clients. Check your connection.');
    }
  }

  /// جلب عميل حسب ID
  static Future<Client> getClientById(int clientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clients/$clientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Client.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في جلب بيانات العميل: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  /// تحديث حالة التوفر للعميل (إذا كان يدعم ذلك)
  static Future<void> updateClientAvailability(
      int clientId, bool isAvailable) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/clients/$clientId/availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isAvailable': isAvailable}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update client availability');
      }
    } catch (e) {
      print('Error updating client availability: $e');
      throw Exception('Failed to update client availability');
    }
  }

  /// تحديث صورة العميل
  static Future<void> updateClientProfileImage(
      int clientId, String imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/clients/$clientId/profile-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'profileImageUrl': imageUrl}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update client profile image');
      }
    } catch (e) {
      print('Error updating client profile image: $e');
      throw Exception('Failed to update client profile image');
    }
  }
}
