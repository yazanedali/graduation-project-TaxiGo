// CustomAppBar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/providers/theme_provider.dart';
import 'package:taxi_app/providers/language_provider.dart';
import 'package:taxi_app/screens/ProfileScreen.dart';
import 'package:taxi_app/screens/signin_screen.dart';
import 'package:taxi_app/screens/signup_screen.dart';

// ملاحظة: لو AppLocalizations.of(context) غير متاح بشكل مباشر
// في هذا الملف، ستحتاج إلى تمرير الكلمات المترجمة
// من الـwidget الأب، أو التأكد من استيراد AppLocalizations الخاص بك.
// للاختصار هنا، سأعتمد على isArabic ? 'نص عربي' : 'English Text'
// كما هو الحال في الكود الأصلي، مع تحسينات بصرية.

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // أضفت هذه المتغيرات لمحاكاة حالة تسجيل الدخول
  // في تطبيق حقيقي، ستحصل على هذه المعلومات من AuthProvider أو حالة التطبيق
  final bool isLoggedIn;
  final String? userName; // اسم المستخدم لعرض رسالة ترحيبية على الويب

  const CustomAppBar({
    Key? key,
    this.isLoggedIn = false, // القيمة الافتراضية: غير مسجل دخول
    this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    bool isArabic = languageProvider.locale.languageCode == 'ar';

    // دالة مساعدة لترجمة النصوص بناءً على اللغة الحالية
    String _getTranslatedString(String en, String ar) {
      return isArabic ? ar : en;
    }

    // تحديد ما إذا كانت الشاشة كبيرة (مثل الويب) أو صغيرة (مثل الموبايل)
    // هذا الشرط يجعل الـ AppBar يستجيب تلقائيًا
    final bool isWeb = MediaQuery.of(context).size.width > 950;

    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      elevation: 6.0, // إضافة ارتفاع وظل خفيف لإعطاء شكل أفضل
      shadowColor: theme.colorScheme.shadow.withOpacity(0.4), // لون الظل

      // قسم العنوان والشعار
      title: Row(
        mainAxisSize: MainAxisSize.min, // لجعل الـ Row يأخذ أقل مساحة ممكنة
        children: [
          Icon(Icons.local_taxi,
              color: theme.colorScheme.onPrimary,
              size: 32), // أيقونة تاكسي بشكل بارز
          const SizedBox(width: 10), // مسافة بين الأيقونة والنص
          Text(
            'TaxiGo',
            style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: 18 // تباعد بين الأحرف لخط أجمل
                ),
          ),
        ],
      ),

      // قسم الإجراءات (الأزرار على اليمين)
      actions: [
        if (isWeb) ...[
          // أزرار خاصة بالويب (شاشة كبيرة) - تستخدم TextButton مع تسميات واضحة
          if (isLoggedIn) ...[
            if (userName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    _getTranslatedString(
                        'Welcome, $userName!', 'أهلاً بك، $userName!'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()));
              },
              icon: Icon(Icons.account_circle,
                  color: theme.colorScheme.onPrimary),
              label: Text(_getTranslatedString('Profile', 'الملف الشخصي'),
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.onPrimary, // لون النص والأيقونة
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 10), // مسافة بين الأزرار
          ] else ...[
            TextButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SignInScreen()));
              },
              icon: Icon(Icons.login, color: theme.colorScheme.onPrimary),
              label: Text(_getTranslatedString('Sign In', 'تسجيل الدخول'),
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 10), // مسافة بين الأزرار
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()));
              },
              icon: Icon(Icons.person_add, color: theme.colorScheme.onPrimary),
              label: Text(_getTranslatedString('Sign Up', 'إنشاء حساب'),
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 10), // مسافة بين الأزرار
          ],

          // زر تبديل الثيم
          IconButton(
            tooltip: _getTranslatedString('Toggle Theme', 'تبديل الثيم'),
            icon: Icon(isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
                color: theme.colorScheme.onPrimary, size: 28),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // زر تبديل اللغة
          IconButton(
            tooltip: _getTranslatedString('Toggle Language', 'تبديل اللغة'),
            icon: Icon(Icons.language,
                color: theme.colorScheme.onPrimary, size: 28),
            onPressed: () {
              Locale newLocale =
                  isArabic ? const Locale('en') : const Locale('ar');
              languageProvider.setLocale(newLocale);
            },
          ),
          const SizedBox(width: 16), // هامش نهائي على اليمين
        ] else ...[
          // أزرار خاصة بالموبايل (شاشة صغيرة) - تستخدم IconButtons للحفاظ على المساحة
          if (isLoggedIn)
            IconButton(
              tooltip: _getTranslatedString('Profile', 'الملف الشخصي'),
              icon: Icon(Icons.account_circle,
                  size: 30, color: theme.colorScheme.onPrimary),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()));
              },
            )
          else
            PopupMenuButton<String>(
              tooltip: _getTranslatedString('Account', 'الحساب'),
              icon: Icon(Icons.account_circle,
                  color: theme.colorScheme.onPrimary, size: 30),
              onSelected: (value) {
                if (value == 'signin') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignInScreen()));
                } else if (value == 'signup') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()));
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'signin',
                  child: Text(_getTranslatedString('Sign In', 'تسجيل الدخول')),
                ),
                PopupMenuItem(
                  value: 'signup',
                  child: Text(_getTranslatedString('Sign Up', 'إنشاء حساب')),
                ),
              ],
            ),

          // زر تبديل الثيم
          IconButton(
            tooltip: _getTranslatedString('Toggle Theme', 'تبديل الثيم'),
            icon: Icon(isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
                color: theme.colorScheme.onPrimary, size: 28),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // زر تبديل اللغة
          IconButton(
            tooltip: _getTranslatedString('Toggle Language', 'تبديل اللغة'),
            icon: Icon(Icons.language,
                color: theme.colorScheme.onPrimary, size: 28),
            onPressed: () {
              Locale newLocale =
                  isArabic ? const Locale('en') : const Locale('ar');
              languageProvider.setLocale(newLocale);
            },
          ),
          const SizedBox(width: 8), // هامش نهائي على اليمين
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
