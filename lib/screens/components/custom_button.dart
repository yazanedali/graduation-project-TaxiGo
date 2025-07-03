import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onPressed;
  final double width;
  final Color? buttonColor;
  final int height;
  final Color backgroundColor;
  final Color textColor;
  final int fontSize;
  final int
      borderRadius; // <--- 2. إضافة الخاصية إلى Constructor هنا (اجعلها اختيارية بـ ?) // <--- 1. إضافة الخاصية الجديدة هنا

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.width,
    this.buttonColor,
    this.height = 50, // <--- 4. تعيين قيمة افتراضية للارتفاع
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.fontSize = 16, // <--- 5. تعيين قيمة افتراضية لحجم الخط
    this.borderRadius = 10, // <--- 6. تعيين قيمة افتراضية لنصف قطر الزاوية
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخدم ثيم السياق للحصول على PrimaryColor كقيمة افتراضية إذا لم يتم تحديد buttonColor
    final theme = Theme.of(context);
    final defaultButtonColor = theme.primaryColor;

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed != null
            ? () {
                // استدعاء الدالة async
                onPressed!();
              }
            : null,
        style: ElevatedButton.styleFrom(
          // <--- 3. استخدام buttonColor الذي تم تمريره، أو defaultButtonColor كقيمة احتياطية
          backgroundColor: buttonColor ?? defaultButtonColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // لون النص ليتناسب مع الخلفية (أبيض بشكل عام للون الأساسي)
          foregroundColor:
              theme.colorScheme.onPrimary, // لون النص على اللون الأساسي
          elevation: 5, // إضافة ظل خفيف للزر
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 18, color: Colors.white), // تأكد من لون النص
        ),
      ),
    );
  }
}
