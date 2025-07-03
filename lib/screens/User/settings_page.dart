import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/providers/theme_provider.dart';
import 'package:taxi_app/providers/language_provider.dart';
import 'package:taxi_app/screens/User/setting/profile.dart';
import 'package:taxi_app/screens/User/setting/change_password.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/screens/homepage.dart';

class AuthService {
  static Future<bool> logoutUser(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/api/users/logout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: '{"Id": "$userId"}',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}

class SettingsPage extends StatelessWidget {
  final int userId;
  final String token;

  const SettingsPage({super.key, required this.userId, required this.token});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final isWeb = MediaQuery.of(context).size.width > 800;
    final local = AppLocalizations.of(context);

    return Scaffold(
     
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                local.translate('settings_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsSection(context, 'account_personal_info', [
                _buildSettingsItem(
                  context,
                  'edit_profile',
                  LucideIcons.user,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditClientProfilePage(
                          clientId: userId,
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  'change_password',
                  LucideIcons.lock,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordPage(userId),
                      ),
                    );
                  },
                ),
              ]),
              _buildSettingsSection(context, 'app_settings', [
                _buildSettingsItem(
                  context,
                  'dark_mode',
                  isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                  () {
                    themeProvider.toggleTheme();
                  },
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                    activeColor: theme.colorScheme.secondary,
                  ),
                ),
                _buildSettingsItem(
                  context,
                  'change_language',
                  LucideIcons.globe,
                  () {
                    languageProvider.setLocale(
                      languageProvider.locale.languageCode == 'ar'
                          ? const Locale('en')
                          : const Locale('ar'),
                    );
                  },
                  trailing: Switch(
                    value: languageProvider.locale.languageCode == 'ar',
                    onChanged: (value) {
                      languageProvider.setLocale(
                        value ? const Locale('ar') : const Locale('en'),
                      );
                    },
                    activeColor: theme.colorScheme.secondary,
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(local.translate('logout')),
                      content: Text(local.translate('logout_confirmation')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(local.translate('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(local.translate('confirm')),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    bool success = await AuthService.logoutUser(userId);
                    if (success) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => HomePage()),
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(local.translate('logout_failed')),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  LucideIcons.logOut,
                  color: theme.colorScheme.onError,
                ),
                label: Text(
                  local.translate('logout'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onError,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String titleKey,
    List<Widget> items,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).translate(titleKey),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items,
          ),
        ),
        const Divider(thickness: 1, height: 30),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String titleKey,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.secondary,
      ),
      title: Text(
        AppLocalizations.of(context).translate(titleKey),
        style: theme.textTheme.bodyLarge,
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
