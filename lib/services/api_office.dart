import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<Map<String, dynamic>> get({
    required String endpoint,
    required String token,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${dotenv.env['BASE_URL']}$endpoint')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw 'Failed to GET request: $e';
    }
  }

  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw 'Failed to POST request: $e';
    }
  }

  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw 'Failed to PUT request: $e';
    }
  }

  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['BASE_URL']}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw 'Failed to DELETE request: $e';
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw responseBody['message'] ??
          'Request failed with status ${response.statusCode}';
    }
  }

  static Future<Map<String, dynamic>> getPublic({
    required String endpoint,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${dotenv.env['BASE_URL']}$endpoint')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      return _handleResponse(response);
    } catch (e) {
      throw 'Failed to GET request: $e';
    }
  }
}
