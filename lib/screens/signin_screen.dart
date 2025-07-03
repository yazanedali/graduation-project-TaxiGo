import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/screens/admin.dart';
import 'package:taxi_app/screens/driver_dashboard.dart'; // صفحة السائق
import 'package:taxi_app/screens/office_manage/office_manager_dashboard.dart'; // صفحة مدير المكتب
import 'package:taxi_app/screens/signup_screen.dart';
import 'package:taxi_app/screens/user.dart'; // صفحة المستخدم العادي
import 'package:taxi_app/widgets/CustomAppBar.dart'; // تأكد من وجود هذا المسار والـ widget
import 'components/custom_text_field.dart';
import 'components/custom_button.dart';
// import 'components/social_button.dart'; // ✅ تم إزالة هذا الاستيراد
import 'forgot_password_screen.dart';
import 'package:taxi_app/language/localization.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false; // ✅ حالة جديدة للتحكم في رؤية كلمة المرور

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn(BuildContext context) async {
    setState(() => isLoading = true);

    String? fcmToken;

    if (!kIsWeb) {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print("✅ FCM Token: $fcmToken");
      } else {
        print("❌ Notification permission not granted");
        fcmToken = "";
      }
    } else {
      // في الويب لا داعي لاستخدام fcmToken أو يمكن توليد قيمة افتراضية
      fcmToken = "web-token-placeholder";
    }

    final String apiUrl = '${dotenv.env['BASE_URL']}/api/users/signin';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'fcmToken': fcmToken
        }),
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['user'];
        final String? token = data['token'];

        if (user != null && user['role'] != null && token != null) {
          String role = user['role'];
          int userId = user['userId'];

          Widget nextScreen;
          if (role == "User") {
            nextScreen = UserDashboard(userId: userId, token: token);
          } else if (role == "Driver") {
            nextScreen = DriverDashboard(userId: userId, token: token);
          } else if (role == "Admin") {
            nextScreen = AdminDashboard(userId: userId, token: token);
          } else if (role == "Manager") {
            nextScreen = OfficeManagerDashboard(userId: userId, token: token);
          } else {
            showError(AppLocalizations.of(context)
                .translate("invalid_role_received"));
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => nextScreen),
          );
        } else {
          showError(AppLocalizations.of(context)
              .translate("invalid_data_or_token_missing"));
        }
      } else {
        String errorMessage = AppLocalizations.of(context)
            .translate("login_failed_check_credentials");
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody.containsKey('message')) {
            errorMessage = responseBody['message'];
          }
        } catch (_) {
          // If response body is not JSON, use default message
        }
        showError(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showError(AppLocalizations.of(context).translate("connection_error"));
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    String signInText = local.translate('sign_in');
    String emailHintText = local.translate('email_or_phone');
    String passwordHintText = local.translate('enter_password');
    String forgetPasswordText = local.translate('forget_password');
    String signUpText = local.translate('dont_have_account');
    String signUpLinkText = local.translate('sign_up');
    // String orSignInWithText = local.translate('or_sign_in_with'); // ✅ تم إزالة هذا النص أيضاً

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(), // تم الاحتفاظ بها كما طلبت
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? constraints.maxWidth * 0.15 : 20.0,
                vertical: isWeb ? 40.0 : 20.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ),
                child: Card(
                  elevation: isWeb ? 8 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 8),
                  ),
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signInText,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          hintText: emailHintText,
                          controller: emailController,
                          width: double.infinity,
                          hintTextColor: theme.hintColor,
                          textColor: theme.textTheme.bodyLarge?.color ??
                              theme.colorScheme.onSurface,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: passwordHintText,
                          obscureText:
                              !_isPasswordVisible, // ✅ التحكم في رؤية النص
                          suffixIcon:
                              _isPasswordVisible // ✅ تغيير الأيقونة بناءً على الحالة
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                          onSuffixPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          controller: passwordController,
                          width: double.infinity,
                          hintTextColor: theme.hintColor,
                          textColor: theme.textTheme.bodyLarge?.color ??
                              theme.colorScheme.onSurface,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen())),
                            child: Text(
                              forgetPasswordText,
                              style:
                                  TextStyle(color: theme.colorScheme.secondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: isLoading
                              ? "${local.translate('loading')}..."
                              : signInText,
                          width: double.infinity,
                          onPressed: isLoading ? null : () => signIn(context),
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        ),
                        // ✅ تم حذف قسم Social Buttons بالكامل
                        // const SizedBox(height: 30),
                        // Center(
                        //   child: Text(
                        //     orSignInWithText,
                        //     style: theme.textTheme.bodySmall?.copyWith(
                        //       color: theme.colorScheme.onSurface.withOpacity(0.7),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     SocialButton(assetPath: "assets/image-removebg-preview4.png"),
                        //     const SizedBox(width: 15),
                        //     SocialButton(assetPath: "assets/image-removebg-preview4.png"),
                        //     const SizedBox(width: 15),
                        //     SocialButton(assetPath: "assets/image-removebg-preview5.png"),
                        //   ],
                        // ),
                        const SizedBox(
                            height: 30), // ✅ تم تعديل المسافة بعد حذف الأزرار
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen())),
                            child: Text.rich(
                              TextSpan(
                                text: signUpText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                children: [
                                  TextSpan(
                                    text: signUpLinkText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
