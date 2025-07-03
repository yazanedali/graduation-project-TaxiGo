import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              local.translate("current_offers"),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Example of available offers
            _buildOfferCard(
              context,
              title: local.translate("first_ride_offer"),
              validity: local.translate("friday_only"),
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16),
            _buildOfferCard(
              context,
              title: local.translate("same_area_offer"),
              validity: local.translate("until_monday"),
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),

            // Handle Web and Mobile Responsiveness
            if (isWeb) ...[
              // Web-specific adjustments
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOfferCard(
                        context,
                        title: local.translate("first_ride_offer"),
                        validity: local.translate("friday_only"),
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOfferCard(
                        context,
                        title: local.translate("same_area_offer"),
                        validity: local.translate("until_monday"),
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(
    BuildContext context, {
    required String title,
    required String validity,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${local.translate("offer_validity")}: $validity",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                local.translate("special_discount"),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  LucideIcons.arrowRight,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Navigate to offer details or take further actions
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
