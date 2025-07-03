import 'package:http/http.dart' as http;

class TelegramBot {
  final String token =
      '7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ'; // API Token من BotFather
  final String chatId =
      '-1002436928564'; // معرف المستخدم أو المجموعة التي سيتم التفاعل معها

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
    if (message.contains("طريق Dair Jreer")) {
      sendMessage("طريق Dair Jreer مسكرة، سيتم تلوينها باللون الأحمر");
      // يمكن إرسال التحديث لتغيير اللون في الخريطة
    } else if (message.contains("ازدحام")) {
      sendMessage("الطريق مزدحم، سيتم تلوينها باللون الأصفر");
      // يمكن إرسال التحديث لتغيير اللون في الخريطة
    } else {
      sendMessage("المسار طبيعي، سيتم تلوينها باللون الأخضر");
      // يمكن إرسال التحديث لتغيير اللون في الخريطة
    }
  }
}

class BotService {
  final TelegramBot _telegramBot = TelegramBot();

  // هذه الدالة تستقبل الرسالة المرسلة من Telegram bot وتقوم بتحليلها
  void analyzeMessage(String message) {
    // معالجة النصوص وتحليل ما إذا كان هناك مشاكل في الطريق مثل ازدحام أو إغلاق طريق
    if (message.contains("طريق Dair Jreer")) {
      _telegramBot.processMessage("طريق Dair Jreer");
    } else if (message.contains("ازدحام")) {
      _telegramBot.processMessage("ازدحام");
    } else if (message.contains("طريق مفتوح") ||
        message.contains("طريق طبيعي")) {
      _telegramBot.processMessage("طريق طبيعي");
    } else {
      // في حالة لم يتضمن الرسالة أي حالة معروفة
      _telegramBot.processMessage("لا توجد مشاكل في الطريق");
    }
  }

  // دالة لتحديث واجهة المستخدم بناءً على التحليل
  void updateRouteColor(String status) {
    // تغيير لون المسار بناءً على حالة الطريق التي تم تحديدها
    if (status == "طريق Dair Jreer") {
      _telegramBot
          .sendMessage("طريق Dair Jreer مسكرة، سيتم تلوينها باللون الأحمر");
    } else if (status == "ازدحام") {
      _telegramBot.sendMessage("الطريق مزدحم، سيتم تلوينها باللون الأصفر");
    } else if (status == "طريق طبيعي") {
      _telegramBot.sendMessage("الطريق طبيعي، سيتم تلوينها باللون الأخضر");
    }
  }
}
