import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  Future<bool> logout() async {
    final token = await storage.read(key: 'token'); // أو من SharedPreferences
    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/users/logout');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await storage.delete(key: 'token'); // حذف التوكن من الجهاز
      return true;
    } else {
      print('فشل تسجيل الخروج: ${response.body}');
      return false;
    }
  }
}
