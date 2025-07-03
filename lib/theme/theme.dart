import 'package:flutter/material.dart';

// **ThemeData Light**
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Color(0xFFFFC107), // الأصفر الأساسي (التاكسي)
    onPrimary: Colors.black, // لون النص والأيقونات فوق الأصفر
    secondary:
        Color(0xFF03A9F4), // لون ثانوي للروابط أو عناصر التفاعل (أزرق فاتح)
    onSecondary: Colors.white, // لون النص فوق اللون الثانوي
    error: Colors.red, // لون الأخطاء (أحمر)
    onError: Colors.white, // لون النص فوق لون الأخطاء
    background: Colors.white, // لون خلفية الشاشة
    onBackground: Colors.black87, // لون النص على خلفية الشاشة
    surface: Colors.white, // لون الأسطح مثل الكاردز والدالوجات
    onSurface: Colors.black87, // لون النص على الأسطح
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFFFFC107), // أصفر التكاسي الأساسي لشريط التطبيق
    iconTheme: IconThemeData(color: Colors.black), // أيقونات شريط التطبيق
    titleTextStyle: TextStyle(
        color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    elevation: 4, // ظل افتراضي لشريط التطبيق
  ),
  scaffoldBackgroundColor: Colors.white, // لون خلفية Scaffold
  textTheme: TextTheme(
    // Added for "Sign In" title
    headlineMedium: TextStyle(
        color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
    titleLarge: TextStyle(
        color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  iconTheme: IconThemeData(color: Colors.black87), // لون أيقونات عام
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFFFC107), // خلفية الأزرار المرتفعة
      foregroundColor: Colors.black, // لون النص على الأزرار المرتفعة
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F5), // لون خلفية حقل الإدخال
    hintStyle: TextStyle(color: Colors.grey), // لون تلميح النص داخل الحقل
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFFFC107)),
    ),
    errorBorder: OutlineInputBorder(
      // border for error state
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      // border for focused error state
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
  ),
  cardColor: Colors.white, // ✅ Added: لون الكارد
  hintColor: Colors
      .grey, // ✅ Added: لون تلميح النص (قد لا يكون ضروريًا إذا كان hintStyle في InputDecorationTheme مستخدمًا)
);

// **ThemeData Dark**
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Color(0xFFFFC107), // الأصفر الأساسي
    onPrimary: Colors.black, // لون النص فوق الأصفر
    secondary: Color(
        0xFF4FC3F7), // لون ثانوي للروابط أو عناصر التفاعل (أزرق فاتح جداً)
    onSecondary: Colors.black, // لون النص فوق اللون الثانوي
    error: Colors.redAccent, // لون الأخطاء (أحمر فاتح لـ dark mode)
    onError: Colors.black, // لون النص فوق لون الأخطاء
    background: Color(0xFF121212), // لون خلفية الشاشة الداكنة جداً
    onBackground: Colors.white, // لون النص على خلفية الشاشة الداكنة
    surface: Color(0xFF212121), // لون الأسطح مثل الكاردز والدالوجات
    onSurface: Colors.white, // لون النص على الأسطح الداكنة
  ),
  appBarTheme: AppBarTheme(
    backgroundColor:
        Color(0xFFFFD54F), // أصفر فاتح لشريط التطبيق في الوضع الداكن
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
        color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    elevation: 4,
  ),
  scaffoldBackgroundColor: Color(0xFF121212), // لون خلفية Scaffold الداكن جداً
  textTheme: TextTheme(
    // Added for "Sign In" title
    headlineMedium: TextStyle(
        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    titleLarge: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  iconTheme: IconThemeData(color: Colors.white70),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFFFD54F), // خلفية الأزرار المرتفعة
      foregroundColor: Colors.black, // لون النص على الأزرار المرتفعة
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF424242), // لون خلفية حقل الإدخال الداكن
    hintStyle: TextStyle(color: Colors.grey[400]), // لون تلميح النص
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFFFD54F)),
    ),
    errorBorder: OutlineInputBorder(
      // border for error state
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      // border for focused error state
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.redAccent, width: 2),
    ),
  ),
  cardColor: Color(0xFF2B2B2B), // ✅ Added: لون الكارد الداكن
  hintColor: Colors.grey[400], // ✅ Added: لون تلميح النص
);
