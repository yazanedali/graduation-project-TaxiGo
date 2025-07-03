import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String username = 'amamry2021.2002@gmail.com';  // ضع بريدك هنا
  final String appPassword = '';  // ضع كلمة مرور التطبيق هنا

  // توليد رمز OTP عشوائي
  String generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6 أرقام عشوائية
  }

  // إرسال البريد الإلكتروني
  Future<void> sendOTPEmail(String recipientEmail) async {
    final smtpServer = gmail(username, appPassword); // استخدام Gmail SMTP

    String otpCode = generateOTP();

    final message = Message()
      ..from = Address(username, 'TaxiGo')  // اسم التطبيق المرسل
      ..recipients.add(recipientEmail)  // البريد المستلم
      ..subject = 'Password Reset OTP'
      ..text = 'Your OTP code for password reset is: $otpCode \nThis code is valid for 10 minutes.';

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ OTP sent successfully: ${sendReport.toString()}');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }
}
