import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class UserService {
   static final String baseUrl = '${dotenv.env['BASE_URL']}/api/users';

  Future<List<User>> fetchUsersByRole(String role) async {
    final response = await http.get(Uri.parse('$baseUrl/$role'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((userJson) => User.fromJson(userJson)).toList();
    } else {
      throw Exception('Failed to load users by role');
    }
  }
}
