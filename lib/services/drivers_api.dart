import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/models/driver.dart'; // استيراد النموذج
import 'package:taxi_app/models/taxi_office.dart'; // استيراد النموذج

class DriversApi {
  // استبدل هذا بالـ URL الفعلي للـ API الخاص بك
  static final String _baseUrl = '${dotenv.env['BASE_URL']}/api';

  static Future<List<Driver>> getAllDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> driversJson = json.decode(response.body);
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all drivers: $e');
      throw Exception('Failed to load drivers. Please try again later.');
    }
  }

  static Future<List<Driver>> getAvailableDrivers() async {
    // يمكنك إضافة بارامترات مثل الموقع الحالي للمستخدم لجلب أقرب السائقين
    final url = Uri.parse('$_baseUrl/drivers/available'); // مثال لنقطة النهاية

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15)); // إضافة timeout

      if (response.statusCode == 200) {
        final List<dynamic> driversJson = json.decode(response.body);
        // تحويل قائمة الـ JSON إلى قائمة من كائنات Driver
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        // التعامل مع رموز الحالة الأخرى (مثل 404, 500)
        throw Exception(
            'Failed to load drivers: Status code ${response.statusCode}');
      }
    } catch (e) {
      // التعامل مع أخطاء الشبكة أو الـ Timeout أو أخطاء التحليل
      print('Error fetching drivers: $e');
      throw Exception('Failed to load drivers. Check your connection.');
    }
  }

  static Future<Driver> getDriverById(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Driver.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في جلب الرحلة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<void> updateDriverAvailability(
      int driverId, bool isAvailable) async {
    try {
      print('Updating availability for driver $driverId: $isAvailable');
      final response = await http.put(
        Uri.parse('$_baseUrl/drivers/$driverId/availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isAvailable': isAvailable}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update driver availability');
      }
    } catch (e) {
      print('Error updating driver availability: $e');
      throw Exception('Failed to update driver availability');
    }
  }

  static Future<void> updateDriverProfileImage(
      int driverId, String imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/drivers/$driverId/profile-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'profileImageUrl': imageUrl}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update driver profile image');
      }
    } catch (e) {
      print('Error updating driver profile image: $e');
      throw Exception('Failed to update driver profile image');
    }
  }

   // ✅ الدالة الجديدة لجلب مدير السائق
  static Future<OfficeManager?> getDriverManagerForDriver(int driverId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/drivers/get-manager'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'driverUserId': driverId, // إرسال المعرف في الـ body
      }),
    );

    if (response.statusCode == 200) {
      return OfficeManager.fromJson(json.decode(response.body));
    } else {
      // يمكنك معالجة الأخطاء هنا بشكل أفضل
      print('Failed to load driver manager: ${response.body}');
      return null;
    }
  }

}


class OfficeManager {
  final int id;
  final String fullName;
  final String? profileImageUrl;
  final int officeId; // ✅ أضف هذا الحقل

  OfficeManager({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    required this.officeId, // ✅ أضفه للمُنشئ

  });

  factory OfficeManager.fromJson(Map<String, dynamic> json) {
    return OfficeManager(
      id: json['id'],
      fullName: json['fullName'],
      profileImageUrl: json['profileImageUrl'],
      officeId: json['officeId'], // ✅ اقرأه من الـ JSON

    );
  }
}
