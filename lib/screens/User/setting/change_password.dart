import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxi_app/language/localization.dart';

class ChangePasswordPage extends StatefulWidget {
  final int userId;

  const ChangePasswordPage(this.userId, {super.key});
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late int userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // ✅ التهيئة
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ دالة التحقق من قوة كلمة المرور (مكررة هنا للوضوح)
  String? _validatePassword(String password) {
    final local = AppLocalizations.of(context);

    if (password.length < 8) {
      return local.translate('password_too_short');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return local.translate('password_missing_uppercase');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return local.translate('password_missing_lowercase');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return local.translate('password_missing_digit');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return local.translate('password_missing_special_char');
    }
    return null; // كلمة المرور قوية
  }

  void _changePassword() async {
    final local = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      // إذا فشلت أي من عمليات التحقق في validator (بما في ذلك _validatePassword)
      return;
    }

    // هذا التحقق من تطابق كلمات المرور أصبح redundant إذا تم التحقق في validator
    // ولكن إبقاؤه لا يضر للتأكيد أو إذا تم إزالته من validator لاحقاً
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.translate('passwords_do_not_match'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? baseUrl = dotenv.env['BASE_URL'];
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تهيئة عنوان الـ API.')),
        );
        return;
      }
      print('Base URL: $baseUrl');

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmNewPassword': _confirmPasswordController.text,
          'id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        // مسح الحقول بعد التغيير بنجاح
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorData['message'] ??
                  local.translate('something_went_wrong'))),
        );
      }
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.translate('something_went_wrong'))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('change_password_title')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
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
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: local.translate('current_password'),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureCurrentPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local
                                .translate('current_password_empty_validation');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // ✅ تم تعديل هذا TextFormField لتطبيق التحقق من قوة كلمة المرور
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: local.translate('new_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureNewPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local.translate(
                                'required_field'); // يجب أن تكون "required_field" في ملف الترجمة
                          }
                          // ✅ استدعاء دالة التحقق الجديدة هنا
                          return _validatePassword(value);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: local.translate('confirm_password'),
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return local
                                .translate('confirm_password_empty_validation');
                          }
                          // التحقق من تطابق كلمات المرور
                          if (value != _newPasswordController.text) {
                            return local.translate('passwords_do_not_match');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        // ✅ يفضل استخدام ألوان الثيم
                                        color: Colors
                                            .white, // Theme.of(context).colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(local.translate('change_button')),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(local.translate('cancel_button')),
                            ),
                          ),
                        ],
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
