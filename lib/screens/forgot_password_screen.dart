import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    final localizations =
        AppLocalizations.of(context); // استخدام AppLocalizations هنا

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? baseUrl = dotenv.env['BASE_URL'];
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('api_error_config'))),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  localizations.translate('reset_link_sent_success'))),
        );
        _emailController.clear();
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorData['message'] ??
                  localizations.translate('something_went_wrong'))),
        );
      }
    } catch (e) {
      print('Error sending reset link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.translate('something_went_wrong'))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // الوصول إلى الثيم
    final localizations = AppLocalizations.of(context); // الوصول إلى الترجمة

    return Scaffold(
      // ScaffoldBackgroundColor يتم تطبيقه تلقائياً من الثيم
      appBar:
          const CustomAppBar(), // الـ CustomAppBar يستمد الثيم من الـ ThemeData تلقائياً
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(
                maxWidth: 500), // لتحديد عرض أقصى للشاشات الكبيرة
            child: Card(
              color: theme.cardColor, // تطبيق لون الكارد من الثيم
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizations.translate('forgot_password_title'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme
                              .onSurface, // لون النص على الكارد (surface)
                          // الـ fontSize والـ fontWeight موجودين أصلاً في headlineMedium
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        localizations.translate('forgot_password_instruction'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme
                              .onSurfaceVariant, // لون ثانوي للنص الإرشادي
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          // Input Decoration Theme يتم تطبيقه تلقائياً
                          labelText: localizations.translate('email_address'),
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email,
                              color: theme
                                  .iconTheme.color), // لون الأيقونة من الثيم
                          // تم إزالة border, focusedBorder, fillColor, filled, hintStyle
                          // لأنها تُطبق من inputDecorationTheme في Theme.of(context)
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme
                              .colorScheme.onSurface, // لون النص داخل الحقل
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('email_empty_validation');
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return localizations
                                .translate('email_invalid_validation');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          // ElevatedButtonThemeData يتم تطبيقه تلقائياً هنا
                          // لذلك لا داعي لتحديد backgroundColor, foregroundColor, shape
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme
                                      .onPrimary, // لون مؤشر التحميل متناسق مع لون النص على الزر
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                localizations
                                    .translate('send_reset_link_button'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme
                                      .onPrimary, // لون النص على الزر (primary)
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
