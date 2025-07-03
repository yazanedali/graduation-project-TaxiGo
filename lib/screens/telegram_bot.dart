import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramBot {
  final String token = '7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ';  // API Token من BotFather
  final String chatId = '-1002436928564';  // معرف المستخدم أو المجموعة التي سيتم التفاعل معها

  // إرسال الرسالة إلى المستخدم
  Future<void> sendMessage(String message) async {
    final url = 'https://api.telegram.org/bot$token/sendMessage';
    final response = await http.post(Uri.parse(url), body: {
      'chat_id': chatId,
      'text': message,
    });

    if (response.statusCode == 200) {
      print('Message sent');
    } else {
      print('Failed to send message');
    }
  }

  // تحليل النص
  void processMessage(String message) {
    // قم بتحليل الرسالة هنا باستخدام منطقك الخاص
    if (message.contains("طريق مسكرة")) {
      sendMessage("الطريق مسكرة، سيتم تلوينها باللون الأحمر");
      // قم بإرسال التحديث إلى الخريطة لتغيير اللون
    } else if (message.contains("ازدحام")) {
      sendMessage("الطريق مزدحم، سيتم تلوينها باللون الأصفر");
      // قم بإرسال التحديث إلى الخريطة لتغيير اللون
    } else {
      sendMessage("المسار طبيعي، سيتم تلوينها باللون الأخضر");
    }
  }
}
