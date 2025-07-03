import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;
    final local = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: theme.colorScheme.primary,
              title: Text(
                local.translate("support_center"),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 800 : 600,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24.0 : 16.0,
            vertical: 16.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        local.translate("support_center"),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          themeProvider.themeMode == ThemeMode.dark
                              ? LucideIcons.sun
                              : LucideIcons.moon,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                _buildEmergencyButton(context, local),
                const SizedBox(height: 20),
                _buildSupportOptions(context, local),
                const SizedBox(height: 20),
                _buildFAQSection(context, local),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context, AppLocalizations local) {
    final theme = Theme.of(context);

    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showEmergencyOptions(context),
        icon: Icon(
          LucideIcons.alertCircle,
          color: theme.colorScheme.onError,
        ),
        label: Text(
          local.translate("emergency_button"),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showEmergencyOptions(BuildContext context) {
    final local = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_police, color: Colors.blue),
                title: Text(local.translate("police")),
                onTap: () => _callNumber("911"),
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.red),
                title: Text(local.translate("ambulance")),
                onTap: () => _callNumber("911"),
              ),
              ListTile(
                leading: const Icon(Icons.fire_truck, color: Colors.orange),
                title: Text(local.translate("fire_department")),
                onTap: () => _callNumber("911"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportOptions(BuildContext context, AppLocalizations local) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          local.translate("how_can_we_help"),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSupportTile(
                context,
                icon: LucideIcons.phoneCall,
                color: Colors.green,
                title: local.translate("call_support"),
                onTap: () => _showPhoneOptions(context),
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              _buildSupportTile(
                context,
                icon: LucideIcons.mail,
                color: Colors.blue,
                title: local.translate("send_email"),
                onTap: () => _showEmailDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEmailDialog(BuildContext context) {
    final local = AppLocalizations.of(context);
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(local.translate("send_message_to_admin")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(local.translate("write_your_message")),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: local.translate("message_hint"),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(local.translate("cancel")),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.isNotEmpty) {
                  _sendEmailToAdmin(context, messageController.text);
                  Navigator.pop(context);
                }
              },
              child: Text(local.translate("send")),
            ),
          ],
        );
      },
    );
  }

  void _sendEmailToAdmin(BuildContext context, String message) async {
    final local = AppLocalizations.of(context);
    final adminEmail = "amamry2025.2002@gmail.com";
    final subject = local.translate("support_email_subject");
    final body =
        "${local.translate("message")}:\n$message\n\n\n--\n${local.translate("sent_from_taxigo_app")}";

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: adminEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        await Clipboard.setData(ClipboardData(
          text: "To: $adminEmail\nSubject: $subject\n\n$body",
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.translate("email_copied_to_clipboard")),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.translate("email_failed")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhoneOptions(BuildContext context) {
    final local = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text("0594348312"),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: "0594348312"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(local.translate("number_copied"))),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _callNumber("0594348312");
                },
              ),
              Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text("0595498035"),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: "0595498035"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(local.translate("number_copied"))),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _callNumber("0595498035");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _callNumber(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: isWeb ? 16 : 14,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, AppLocalizations local) {
    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          local.translate("frequently_asked_questions"),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isWeb ? 20 : 18,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: isWeb ? constraints.maxWidth * 0.9 : constraints.maxWidth,
              child: Column(
                children: [
                  _buildFAQItem(
                    context,
                    title: local.translate("cancel_trip"),
                    content: local.translate("cancel_trip_answer"),
                  ),
                  const SizedBox(height: 8),
                  _buildFAQItem(
                    context,
                    title: local.translate("forgot_item"),
                    content: local.translate("forgot_item_answer"),
                  ),
                  const SizedBox(height: 8),
                  _buildFAQItem(
                    context,
                    title: local.translate("schedule_trip"),
                    content: local.translate("schedule_trip_answer"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context,
      {required String title, required String content}) {
    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: isWeb ? 24.0 : 16.0,
          vertical: 8.0,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isWeb ? 16 : 14,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isWeb ? 24.0 : 16.0,
              0,
              isWeb ? 24.0 : 16.0,
              16.0,
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isWeb ? 14 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
