import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/providers/theme_provider.dart';
import 'package:taxi_app/providers/language_provider.dart';
import 'package:http/http.dart' as http; // Added for http requests
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for environment variables
import 'package:shared_preferences/shared_preferences.dart'; // Added for shared preferences
import 'package:taxi_app/screens/Driver/edit_driver_profile_page.dart';
import 'package:taxi_app/screens/homepage.dart'; // Added for navigation to HomePage
import 'package:taxi_app/screens/Driver/change_password_page.dart';

class AuthService {
  static Future<bool> logoutUser(int userId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/users/logout'), // Or /api/drivers/logout if different
        headers: {
          'Content-Type': 'application/json',
        },
        body: '{"Id": "$userId"}', // Sending driverId as "Id"
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
// --- End of AuthService ---

class DriverSettingsPage extends StatefulWidget {
  const DriverSettingsPage({
    super.key,
    required Null Function(bool value)
        onAvailabilityChanged, // This seems unused in the context of logout, but kept it.
    required this.driverId, // Changed to 'this.driverId' to make it accessible
  });

  final int driverId; // Added to store driverId

  @override
  _DriverSettingsPageState createState() => _DriverSettingsPageState();
}

class _DriverSettingsPageState extends State<DriverSettingsPage> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final local = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                local.translate('driver_settings_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Account Settings Section
              _buildSettingsSection(context, 'account_settings', [
                _buildSettingsItem(
                  context,
                  'edit_profile',
                  LucideIcons.user,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EditDriverProfilePage(driverId: widget.driverId),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  'notifications',
                  LucideIcons.bell,
                  () {
                    setState(() {
                      notificationsEnabled = !notificationsEnabled;
                    });
                  },
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                    },
                    activeColor: theme.colorScheme.secondary,
                  ),
                ),
              ]),

              // Display Settings Section
              _buildSettingsSection(context, 'display_settings', [
                _buildSettingsItem(
                  context,
                  'night_mode',
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
                          value ? const Locale('ar') : const Locale('en'));
                    },
                    activeColor: theme.colorScheme.secondary,
                  ),
                ),
              ]),

              // Security Section
              _buildSettingsSection(context, 'security_settings', [
                _buildSettingsItem(
                  context,
                  'change_password',
                  LucideIcons.key,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordPage(widget.driverId),
                      ),
                    );
                  },
                ),
              ]),

              // Logout Section - Modified
              _buildSettingsSection(context, 'other_settings', [
                _buildSettingsItem(
                  context,
                  'logout',
                  LucideIcons.logOut,
                  () async {
                    // Made onTap async
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
                      // Use widget.driverId for the logout call
                      bool success =
                          await AuthService.logoutUser(widget.driverId);
                      if (success) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear(); // Clear all shared preferences

                        // Check if the widget is still mounted before navigating
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const HomePage()), // Navigate to HomePage
                            (route) => false, // Remove all previous routes
                          );
                        }
                      } else {
                        // Check if the widget is still mounted before showing SnackBar
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(local.translate('logout_failed')),
                            ),
                          );
                        }
                      }
                    }
                  },
                  // Trailing icon already set, which is good
                  trailing: Icon(
                    LucideIcons.logOut,
                    color: theme
                        .colorScheme.error, // Keep error color for logout icon
                  ),
                ),
              ]),
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
    final local = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          local.translate(titleKey),
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
    final local = AppLocalizations.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.secondary,
      ),
      title: Text(
        local.translate(titleKey),
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
