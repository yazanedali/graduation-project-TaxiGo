import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              context,
              local.translate('contact_support'),
            ),
            const SizedBox(height: 16),
            _buildSupportOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSupportOptions(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSupportTile(
            context,
            icon: LucideIcons.headphones,
            title: local.translate('phone_support'),
            subtitle: local.translate('call_us_at') + ": 0123456789",
            onTap: () {},
          ),
          Divider(height: 1, color: theme.dividerColor),
          _buildSupportTile(
            context,
            icon: LucideIcons.mail,
            title: local.translate('email_support'),
            subtitle: "support@taxigo.com",
            onTap: () {},
          ),
          Divider(height: 1, color: theme.dividerColor),
          _buildSupportTile(
            context,
            icon: LucideIcons.messageCircle,
            title: local.translate('chat_support'),
            subtitle: local.translate('chat_with_us_directly'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.secondary,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}
