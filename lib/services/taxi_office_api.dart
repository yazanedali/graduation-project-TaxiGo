import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/models/taxi_office.dart';
import 'package:taxi_app/models/driver.dart';

class TaxiOfficeApi {
  static final String _baseUrl = '${dotenv.env['BASE_URL']}/api';

  static Future<void> createDriver({
    required int
        officeId, // تم تغيير الاسم هنا ليتوافق مع الـ backend (req.params.id)
    required String token,
    required String fullName,
    required String email,
    required String phone,
    required String gender,
    required String carModel,
    required String carPlateNumber,
    String? carColor,
    int? carYear,
    required String licenseNumber,
    required String licenseExpiry, // يتوقع أن تكون ISO 8601 String
    String? profileImageUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/offices/$officeId/drivers');

    final Map<String, dynamic> body = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'carModel': carModel,
      'carPlateNumber': carPlateNumber,
      'carColor': carColor,
      'carYear': carYear,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        // تم إنشاء السائق بنجاح
        print('Driver created successfully: ${response.body}');
        // يمكنك تحليل الجسم إذا كنت بحاجة إلى أي بيانات من الاستجابة
        // final responseData = jsonDecode(response.body);
      } else {
        // التعامل مع الأخطاء بناءً على رمز الحالة
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'حدث خطأ غير معروف.';
        print(
            'Error creating driver (Status ${response.statusCode}): $message');
        throw Exception(message);
      }
    } catch (e) {
      print('Caught exception during driver creation: $e');
      // قم بإعادة رمي الخطأ ليتم التقاطه بواسطة واجهة المستخدم
      throw Exception('فشل في الاتصال بالخادم أو إنشاء السائق: $e');
    }
  }

  // الحصول على سائقين المكتب
  static Future<List<Driver>> getOfficeDrivers(
      int officeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offices/$officeId/drivers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> driversJson = data['data'];
          return driversJson.map((json) => Driver.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load drivers');
        }
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على إجمالي أرباح السائقين
  static Future<double> getTotalEarnings(int officeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offices/$officeId/earnings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['totalEarnings']?.toDouble() ?? 0.0;
        } else {
          throw Exception(data['message'] ?? 'Failed to load earnings');
        }
      } else {
        throw Exception('Failed to load earnings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على إحصائيات المكتب
  static Future<Map<String, int>> getOfficeStats(
      int officeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offices/$officeId/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'driversCount': data['data']['driversCount'] ?? 0,
            'tripsCount': data['data']['tripsCount'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load office stats');
        }
      } else {
        throw Exception('Failed to load office stats: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على إحصائيات اليوم
  static Future<Map<String, int>> getDailyStats(
      int officeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offices/$officeId/daily-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'dailyTripsCount': data['data']['dailyTripsCount'] ?? 0,
            'dailyEarnings': data['data']['dailyEarnings'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load daily stats');
        }
      } else {
        throw Exception('Failed to load daily stats: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على تفاصيل المكتب
  static Future<TaxiOffice> getOfficeDetails(int officeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/offices/$officeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TaxiOffice.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load office details');
        }
      } else {
        throw Exception(
            'Failed to load office details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
