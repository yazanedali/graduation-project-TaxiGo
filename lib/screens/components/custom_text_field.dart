// في ملف components/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final double width;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? hintTextColor;
  final Color? textColor;
  final ValueChanged<String>?
      onSubmitted; // ✅ خاصية جديدة: لاستقبال نص عند الضغط على Enter

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.width = double.infinity,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixPressed,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.hintTextColor,
    this.textColor,
    this.onSubmitted, // ✅ إضافة للـ constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color actualTextColor =
        textColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color actualHintTextColor = hintTextColor ??
        theme.inputDecorationTheme.hintStyle?.color ??
        Colors.grey;
    // تم حذف actualPrefixIconColor واستبداله بلون أيقونات الثيم ليكون أكثر توافقاً.
    // أو يمكن استخدام actualHintTextColor لأيقونات البادئة واللاحقة لتتماشى مع الـ hint text.
    // دعنا نستخدم actualHintTextColor لتماشي مع مظهر الـ hint.

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        onSubmitted: onSubmitted, // ✅ تمرير الخاصية إلى TextField الداخلي
        style: TextStyle(color: actualTextColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: actualHintTextColor),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: theme.inputDecorationTheme.border?.borderSide.color ??
                    actualHintTextColor.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: theme
                        .inputDecorationTheme.enabledBorder?.borderSide.color ??
                    actualHintTextColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: theme
                        .inputDecorationTheme.focusedBorder?.borderSide.color ??
                    theme.colorScheme.primary),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: actualHintTextColor) // استخدم لون التلميح للأيقونة
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon,
                      color:
                          actualHintTextColor), // استخدم لون التلميح للأيقونة
                  onPressed: onSuffixPressed,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
        ),
      ),
    );
  }
}
