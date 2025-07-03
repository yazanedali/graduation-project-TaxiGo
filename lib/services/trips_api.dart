import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/models/trip.dart';

class TripsApi {
  static final String _baseUrl = '${dotenv.env['BASE_URL']}/api';

  static Future<Trip> createTrip({
    required int userId,
    required Map<String, dynamic> startLocation,
    required Map<String, dynamic> endLocation,
    required double distance,
    DateTime? startTime,
    required String paymentMethod,
    bool isScheduled = false, // هل الرحلة مجدولة؟
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'startLocation': startLocation,
          'endLocation': endLocation,
          'distance': distance,
          'startTime': startTime?.toIso8601String(),
          'paymentMethod': paymentMethod,
          'isScheduled': isScheduled, // إرسال حالة الجدولة
        }),
      );

      if (response.statusCode == 201) {
        return Trip.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في إنشاء الرحلة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<void> completeTrip(String tripId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/$tripId/complete'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('فشل في إنهاء الرحلة');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<Trip> getTripById(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trips/$tripId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Trip.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل في جلب الرحلة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<List<Trip>> getDriverActiveTrips(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/trips/driver/$driverId?status=accepted,in_progress'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Trip.fromJson(json)).toList();
        } else {
          throw Exception('تنسيق الاستجابة غير صالح');
        }
      } else {
        throw Exception('فشل في جلب الرحلات النشطة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<List<Trip>> getUserTrips(int userId, {String? status}) async {
    try {
      String url = '$_baseUrl/trips/user/$userId';
      if (status != null) url += '?status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Trip.fromJson(json)).toList();
        } else {
          throw Exception('تنسيق الاستجابة غير صالح');
        }
      } else {
        throw Exception('فشل في جلب رحلات المستخدم: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<List<Trip>> getNearbyPendingTrips(double lat, double lng,
      {double maxDistance = 5}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/trips/nearby?latitude=$lat&longitude=$lng&maxDistance=$maxDistance'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data['trips'] is List) {
          return (data['trips'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        } else {
          throw Exception('تنسيق الاستجابة غير صالح');
        }
      } else {
        throw Exception('فشل في جلب الرحلات القريبة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<void> updateTripFare(String tripId, double newFare) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/trips/$tripId/fare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'actualFare': newFare}),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل في تحديث سعر الرحلة');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  static Future<List<Trip>> getDriverTrips(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trips/driver/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // تحقق من هيكل الاستجابة
        if (responseData is List) {
          return responseData.map((json) => Trip.fromJson(json)).toList();
        } else if (responseData['trips'] is List) {
          return (responseData['trips'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Trip>> getRecentTrips(int driverId,
      {int limit = 2}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trips/driver/$driverId/recent'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // تحقق من هيكل الاستجابة
        if (responseData is List) {
          return responseData.map((json) => Trip.fromJson(json)).toList();
        } else if (responseData['trips'] is List) {
          return (responseData['trips'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> updateTripStatus(int tripId, String status) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/trips/$tripId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update trip status');
    }
  }

  static Future<List<Trip>> getDriverTripsWithStatus(int driverId,
      {String? status}) async {
    try {
      // بناء الرابط مع باراميتر الحالة إذا كان موجود
      String url = '$_baseUrl/trips/driver/$driverId';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is List) {
          return responseData.map((json) => Trip.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load driver trips with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Trip>> getClientTripsWithStatus(int userId,
      {String? status}) async {
    try {
      final url = '$_baseUrl/trips/user/$userId/status?status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => Trip.fromJson(e)).toList();
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Trip>> getPendingTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trips/pending'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is List) {
          return responseData.map((json) => Trip.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load pending trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Trip>> getTripsByStatus(
      int driverId, String status) async {
    try {
      // المحاولة الأولى: استخدام الباك-إند مع فلتر الحالة
      final response = await http.get(
        Uri.parse('$_baseUrl/trips/driver/$driverId?status=$status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Trip.fromJson(json)).toList();
        }
      }

      // الخيار الاحتياطي: الفلترة محلياً
      final allTrips = await getDriverTrips(driverId);
      return allTrips.where((trip) => trip.status == status).toList();
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  static Future<void> acceptTrip(
    String tripId,
    int driverId,
    double latitude,
    double longitude,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/trips/$tripId/accept'),
      body: jsonEncode({
        'driverId': driverId,
        'driverLocation': {
          'lat': latitude,
          'lng': longitude,
        },
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في قبول الرحلة');
    }
  }

  static Future<void> rejectTrip(String tripId, int driverId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/trips/$tripId/reject'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('فشل في رفض الرحلة');
    }
  }

  // بدء الرحلة
  static Future<void> startTrip(int tripId) async {
    final response =
        await http.post(Uri.parse('$_baseUrl/trips/$tripId/start'));
    if (response.statusCode != 200) {
      throw Exception('فشل في بدء الرحلة');
    }
  }

  /// جلب الرحلات القريبة من إحداثيات معينة
  static Future<Map<String, dynamic>> getNearbyTrips(
      double lng, double lat) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl/trips/nearby?longitude=$lng&latitude=$lat&maxDistance=5'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      final tripsJson = data['trips'] as List;
      final trips = tripsJson.map((json) => Trip.fromJson(json)).toList();

      return {
        'message': message,
        'trips': trips,
      };
    } else {
      throw Exception('فشل في تحميل الرحلات القريبة');
    }
  }

  static Future<List<dynamic>> getPendingUserTrips(int userId) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/trips/PendingUserTrips?userId=$userId&status=pending'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending trips');
    }
  }

  static Future<void> cancelTrip(int tripId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/trips/$tripId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel trip');
    }
  }

  static Future<void> updateTrip({
    required int tripId,
    required String startAddress,
    required String endAddress,
    double? startLongitude,
    double? startLatitude,
    double? endLongitude,
    double? endLatitude,
  }) async {
    final body = {
      'startLocation': {
        'address': startAddress,
      },
      'endLocation': {
        'address': endAddress,
      }
    };

    final response = await http.put(
      Uri.parse('$_baseUrl/trips/$tripId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update trip: ${response.body}');
    }
  }

  static Future<List<Trip>> getAllTripsWithStatus({String? status}) async {
    try {
      String url = '$_baseUrl/trips';
      if (status != null && status.isNotEmpty) {
        url += '/?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // تحقق من الهيكل الذي يعيده الباك إند (مفتاح 'data')
        if (responseData['data'] is List) {
          return (responseData['data'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        } else {
          throw Exception(
              'تنسيق الاستجابة غير صالح: لا يوجد مفتاح "data" أو ليس مصفوفة');
        }
      } else {
        throw Exception('فشل في جلب الرحلات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }
}
