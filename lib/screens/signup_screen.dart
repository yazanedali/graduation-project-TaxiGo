import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxi_app/screens/components/custom_button.dart';
import 'package:taxi_app/screens/components/custom_text_field.dart';
import 'package:country_picker/country_picker.dart';
import 'package:taxi_app/screens/signin_screen.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart'; // تأكد أن هذا المسار صحيح
import 'package:taxi_app/language/localization.dart';
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart'; // لم تعد مستخدمة في هذا الملف، يمكن إزالتها
import 'driver_signup_screen.dart'; // إضافة صفحة تسجيل السائقين

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String selectedCountryCode = '+1'; // رمز الدولة الافتراضي
  String selectedCountryFlag = '🇺🇸'; // علم الدولة الافتراضي
  String? selectedGender = 'Male';
  bool isPrivacyAccepted = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false; // حالة التحميل للزر

  String? _validatePassword(String password) {
    final localizations = AppLocalizations.of(context);

    if (password.length < 8) {
      return localizations
          .translate('password_too_short'); // يجب أن تحتوي على 8 أحرف على الأقل
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return localizations.translate(
          'password_missing_uppercase'); // يجب أن تحتوي على حرف كبير واحد على الأقل
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return localizations.translate(
          'password_missing_lowercase'); // يجب أن تحتوي على حرف صغير واحد على الأقل
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return localizations.translate(
          'password_missing_digit'); // يجب أن تحتوي على رقم واحد على الأقل
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return localizations.translate(
          'password_missing_special_char'); // يجب أن تحتوي على رمز خاص واحد على الأقل
    }
    return null; // كلمة المرور قوية
  }

  // دالة لعرض رسائل SnackBar
  void showSnackBarMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary, // استخدم primary للنجاح
      ),
    );
  }

  Future<void> signUp() async {
    if (!mounted) return; // تحقق من mounted قبل setState
    setState(() => isLoading = true); // بدء التحميل

    // تحقق من شروط التسجيل قبل إرسال الطلب
    if (fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showSnackBarMessage(
          AppLocalizations.of(context).translate('fill_all_fields'),
          isError: true);
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    // ✅ جديد: التحقق من قوة كلمة المرور
    final passwordError = _validatePassword(passwordController.text);
    if (passwordError != null) {
      showSnackBarMessage(passwordError, isError: true);
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showSnackBarMessage(
          AppLocalizations.of(context).translate('passwords_not_match'),
          isError: true);
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    if (!isPrivacyAccepted) {
      showSnackBarMessage(
          AppLocalizations.of(context).translate('accept_privacy_policy'),
          isError: true);
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final String baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      if (mounted) {
        showSnackBarMessage(
            AppLocalizations.of(context).translate('base_url_not_configured'),
            isError: true);
      }
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final String url = '$baseUrl/api/users/signup';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullNameController.text,
          'phone': selectedCountryCode +
              phoneController.text, // دمج رمز الدولة مع الرقم
          'email': emailController.text,
          'password': passwordController.text,
          'confirmPassword': confirmPasswordController.text,
          'role': 'User',
          'gender': selectedGender,
        }),
      );

      if (!mounted) return; // تحقق من mounted بعد الـ await

      if (response.statusCode == 201) {
        showSnackBarMessage(
            AppLocalizations.of(context).translate('account_created_success'));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      } else {
        final errorBody = json.decode(response.body);
        showSnackBarMessage(
          errorBody['message'] ??
              AppLocalizations.of(context).translate('error_creating_account'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBarMessage(
          "${AppLocalizations.of(context).translate('network_error')}: ${e.toString()}",
          isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false); // إنهاء التحميل
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // ✅ استخدام ألوان الثيم لضمان التوافق مع الوضع الفاتح/الداكن
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color hintTextColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;
    final Color cardColor = theme.cardColor;
    final Color primaryColor = theme.colorScheme.primary;
    final Color accentColor = theme.colorScheme.secondary; // لون ثانوي

    return Scaffold(
      // AppBar الخاص بـ SignUpScreen سيأتي من CustomAppBar
      appBar: const CustomAppBar(), // ✅ استخدم CustomAppBar هنا

      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // تحديد ما إذا كانت الشاشة كبيرة (غالباً للويب أو الأجهزة اللوحية)
          bool isLargeScreen = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? constraints.maxWidth * 0.15 : 20,
                vertical: isLargeScreen ? 30 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 600 : double.infinity,
                ),
                child: Container(
                  // الحاوية الرئيسية للفورم لإعطائه مظهر البطاقة
                  padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
                  decoration: BoxDecoration(
                    color: cardColor, // ✅ استخدام cardColor من الثيم
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        // ✅ استخدام لون الظل من الثيم (onSurface للتباين)
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // لجعل العمود يأخذ أقل مساحة ممكنة
                    children: [
                      Text(
                        localizations.translate('sign_up'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: primaryColor, // ✅ استخدام primaryColor للعنوان
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 30 : 20),
                      CustomTextField(
                        hintText: localizations.translate('full_name'),
                        controller: fullNameController,
                        width: double.infinity,
                        hintTextColor: hintTextColor, // ✅ تم إضافتها
                        textColor: textColor, // ✅ تم إضافتها
                        prefixIcon: Icons.person, // إضافة أيقونة
                      ),
                      const SizedBox(height: 15),
                      // حقل رقم الهاتف مع منتقي الدولة
                      Row(
                        children: [
                          // زر اختيار الدولة
                          InkWell(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                onSelect: (Country country) {
                                  setState(() {
                                    selectedCountryCode =
                                        "+${country.phoneCode}";
                                    selectedCountryFlag = country.flagEmoji;
                                  });
                                },
                                countryFilter: const [
                                  // ✅ استخدام const
                                  'US', 'EG', 'SA', 'JO', 'AE', 'QA', 'KW',
                                  'PS', 'IL'
                                ],
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10), // تعديل الـ padding
                              decoration: BoxDecoration(
                                // ✅ استخدام InputDecorationTheme.fillColor من الثيم
                                color: theme.inputDecorationTheme.fillColor,
                                borderRadius:
                                    BorderRadius.circular(10), // حواف دائرية
                                border: Border.all(
                                    // ✅ استخدام borderSide.color من InputDecorationTheme أو fallback
                                    color: theme.inputDecorationTheme.border
                                            ?.borderSide.color ??
                                        hintTextColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(selectedCountryFlag,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(selectedCountryCode,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                              // ✅ استخدام textTheme
                                              fontWeight: FontWeight.bold,
                                              color: textColor)),
                                  Icon(Icons.arrow_drop_down,
                                      size: 20,
                                      color: theme.iconTheme
                                          .color), // ✅ استخدام iconTheme
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // حقل إدخال رقم الهاتف
                          Expanded(
                            child: CustomTextField(
                              hintText: localizations.translate('phone_number'),
                              controller: phoneController,
                              width: double.infinity,
                              hintTextColor: hintTextColor, // ✅ تم إضافتها
                              textColor: textColor, // ✅ تم إضافتها
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone, // أيقونة الهاتف
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        hintText: localizations.translate('email'),
                        controller: emailController,
                        width: double.infinity,
                        hintTextColor: hintTextColor, // ✅ تم إضافتها
                        textColor: textColor, // ✅ تم إضافتها
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email, // أيقونة البريد الإلكتروني
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        hintText: localizations.translate('password'),
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        suffixIcon: isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        width: double.infinity,
                        hintTextColor: hintTextColor, // ✅ تم إضافتها
                        textColor: textColor, // ✅ تم إضافتها
                        prefixIcon: Icons.lock, // أيقونة القفل
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        hintText: localizations.translate('confirm_password'),
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        suffixIcon: isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixPressed: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                        width: double.infinity,
                        hintTextColor: hintTextColor, // ✅ تم إضافتها
                        textColor: textColor, // ✅ تم إضافتها
                        prefixIcon: Icons.lock, // أيقونة القفل
                      ),
                      const SizedBox(height: 15),
                      // منتقي الجنس مع تنسيق أفضل
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          // ✅ استخدام InputDecorationTheme.fillColor من الثيم
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(10),
                          // ✅ استخدام borderSide.color من InputDecorationTheme أو fallback
                          border: Border.all(
                              color: theme.inputDecorationTheme.border
                                      ?.borderSide.color ??
                                  hintTextColor.withOpacity(0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          // ✅ استخدام DropdownButtonHideUnderline
                          child: DropdownButton<String>(
                            value: selectedGender,
                            dropdownColor:
                                cardColor, // ✅ استخدام cardColor من الثيم
                            isExpanded: true,
                            underline: const SizedBox(), // ✅ إخفاء الخط
                            icon: Icon(Icons.arrow_drop_down,
                                color:
                                    textColor), // ✅ استخدام textColor للأيقونة
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontSize: 16), // ✅ استخدام textTheme
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGender = newValue;
                              });
                            },
                            items: <String>['Male', 'Female']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      value == 'Male'
                                          ? Icons.male_outlined
                                          : Icons.female_outlined,
                                      color:
                                          primaryColor, // ✅ استخدام primaryColor
                                    ),
                                    const SizedBox(width: 10),
                                    Text(localizations
                                        .translate(value.toLowerCase())),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // مربع اختيار سياسة الخصوصية
                      Row(
                        children: [
                          Checkbox(
                            value: isPrivacyAccepted,
                            onChanged: isLoading
                                ? null // ✅ تعطيل الـ checkbox أثناء التحميل
                                : (bool? value) {
                                    setState(() {
                                      isPrivacyAccepted = value!;
                                    });
                                  },
                            activeColor: primaryColor, // ✅ استخدام primaryColor
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isLoading)
                                  return; // ✅ تعطيل النقر أثناء التحميل
                                // يمكنك إضافة منطق لفتح سياسة الخصوصية هنا
                                showSnackBarMessage(localizations
                                    .translate('privacy_policy_clicked'));
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: localizations.translate('i_agree_to'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor, // ✅ استخدام textColor
                                  ),
                                  children: [
                                    TextSpan(
                                      text: localizations
                                          .translate('privacy_policy_link'),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        // ✅ استخدام textTheme
                                        color:
                                            primaryColor, // ✅ استخدام primaryColor
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: isLoading
                            ? localizations.translate('loading') // "Loading..."
                            : localizations.translate('sign_up'),
                        width: double.infinity,
                        onPressed: isLoading || !isPrivacyAccepted
                            ? null
                            : signUp, // تعطيل الزر أثناء التحميل أو إذا لم يتم قبول السياسة
                        buttonColor: primaryColor, // ✅ استخدام primaryColor
                      ),
                      const SizedBox(height: 20),
                      // رابط لتسجيل السائقين
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextButton(
                          onPressed: isLoading
                              ? null // ✅ تعطيل الزر أثناء التحميل
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DriverSignUpScreen()),
                                  );
                                },
                          child: Text.rich(
                            TextSpan(
                              text: localizations.translate('are_you_driver'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor, // ✅ استخدام textColor
                              ),
                              children: [
                                TextSpan(
                                  text: localizations
                                      .translate('sign_up_as_driver'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    // ✅ استخدام textTheme
                                    color: accentColor, // ✅ استخدام accentColor
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // رابط لتسجيل الدخول
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null // ✅ تعطيل الزر أثناء التحميل
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignInScreen()),
                                  );
                                },
                          child: Text.rich(
                            TextSpan(
                              text:
                                  "${localizations.translate('already_have_account')} ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor, // ✅ استخدام textColor
                              ),
                              children: [
                                TextSpan(
                                  text: localizations.translate('sign_in'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    // ✅ استخدام textTheme
                                    color: accentColor, // ✅ استخدام accentColor
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: isLargeScreen
                              ? 20
                              : 0), // مسافة إضافية في الأسفل للشاشات الكبيرة
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
