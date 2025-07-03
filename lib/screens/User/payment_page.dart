import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
  
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment method title
            _buildSectionTitle(
              context,
              local.translate('payment_method'),
            ),

            const SizedBox(height: 10),

            // Smile to Pay description
            Text(
              local.translate('use_face_recognition'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Steps
            _buildSectionTitle(context, local.translate('steps')),
            Text(
              "1. ${local.translate('select_smile_to_pay')}",
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              "2. ${local.translate('open_camera_and_smile')}",
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              "3. ${local.translate('payment_completed_on_smile')}",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // Smile to Pay button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implement smile to pay
                },
                icon: Icon(
                  LucideIcons.smile,
                  color: theme.colorScheme.onPrimary,
                ),
                label: Text(
                  local.translate('use_smile_to_pay'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Alternative payment methods
            _buildSectionTitle(
              context,
              local.translate('alternative_payment_methods'),
            ),
            _buildPaymentOption(
              context,
              title: local.translate('cash_payment_method'),
              description: local.translate('cash_payment_description'),
              icon: LucideIcons.wallet,
            ),
            _buildPaymentOption(
              context,
              title: local.translate('card_payment'),
              description: local.translate('card_payment_description'),
              icon: LucideIcons.creditCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.secondary,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        onTap: () {
          // Implement selected payment method
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
