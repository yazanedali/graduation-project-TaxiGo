import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/providers/theme_provider.dart';
import 'package:taxi_app/providers/language_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/screens/User/setting/change_password.dart';
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

class OfficeManagerSettingsPage extends StatefulWidget {
  final int userId;
  final String token;

  const OfficeManagerSettingsPage(
      {super.key, required this.userId, required this.token});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<OfficeManagerSettingsPage> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var themeProvider = Provider.of<ThemeProvider>(context);
    var languageProvider = Provider.of<LanguageProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.system;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
    
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(
              AppLocalizations.of(context).translate('app_settings'), theme),
          
          _buildSettingsItem(
            icon: LucideIcons.bell,
            title: AppLocalizations.of(context).translate('notifications'),
            subtitle:
                AppLocalizations.of(context).translate('control_notifications'),
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              activeColor: theme.colorScheme.secondary,
            ),
            theme: theme,
          ),
          _buildSettingsItem(
            icon: LucideIcons.moon,
            title: AppLocalizations.of(context).translate('night_mode'),
            subtitle:
                AppLocalizations.of(context).translate('toggle_dark_mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: theme.colorScheme.secondary,
            ),
            theme: theme,
          ),
          _buildSettingsItem(
            icon: LucideIcons.globe,
            title: AppLocalizations.of(context).translate('change_language'),
            subtitle: AppLocalizations.of(context)
                .translate('switch_between_arabic_and_english'),
            trailing: Switch(
              value: languageProvider.locale.languageCode == 'ar',
              onChanged: (value) {
                languageProvider
                    .setLocale(value ? const Locale('ar') : const Locale('en'));
              },
              activeColor: theme.colorScheme.secondary,
            ),
            theme: theme,
          ),
          _buildSectionTitle(
              AppLocalizations.of(context).translate('Security_Privacy'),
              theme),
       
          _buildSettingsItem(
            icon: LucideIcons.key,
            title: AppLocalizations.of(context).translate('change_password'),
            subtitle:
                AppLocalizations.of(context).translate('reset_your_password'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordPage(widget.userId),
                ),
              );
            },
            theme: theme,
          ),
          _buildSectionTitle(
              AppLocalizations.of(context).translate('Updates_Support'), theme),
          _buildSettingsItem(
            icon: LucideIcons.refreshCcw,
            title: AppLocalizations.of(context).translate('check_for_updates'),
            subtitle: AppLocalizations.of(context)
                .translate('update_to_the_latest_version'),
            onTap: () {},
            theme: theme,
          ),
         
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Confirm')),
                  ],
                ),
              );

              if (confirm == true) {
                bool success = await AuthService.logoutUser(widget.userId);
                print('Logout success: $success');
                if (success) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  // جرب تنتقل يدويًا
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => HomePage()), // غيرها حسب صفحتك
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed, please try again')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(AppLocalizations.of(context).translate('logout')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required ThemeData theme,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: theme.iconTheme.color),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color)),
        subtitle: Text(subtitle,
            style: TextStyle(color: theme.textTheme.bodySmall?.color)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
