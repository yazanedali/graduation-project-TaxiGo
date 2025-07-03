import 'package:flutter/material.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/client.dart';

class ClientDetailPageWeb extends StatelessWidget {
  final Client client;

  const ClientDetailPageWeb({super.key, required this.client});

  Widget _buildDetailRow(BuildContext context, String labelKey, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "${AppLocalizations.of(context).translate(labelKey)}:",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)
            .translate('client_detail_page_title_prefix')),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final contentWidth = isWide ? 700.0 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: contentWidth,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: NetworkImage(
                        client.profileImageUrl ??
                            'https://via.placeholder.com/150',
                      ),
                      backgroundColor: theme.colorScheme.background,
                      onBackgroundImageError: (error, stackTrace) =>
                          debugPrint('Image error: $error'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      client.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(context, 'client_detail_phone_label', client.phone),
                    _buildDetailRow(context, 'client_detail_email_label', client.email),
                    _buildDetailRow(context, 'client_detail_total_spending_label',
                        "${client.totalSpending.toStringAsFixed(2)}"),
                    _buildDetailRow(context, 'client_detail_trips_number_label',
                        "${client.tripsNumber}"),
                    _buildDetailRow(
                      context,
                      'client_detail_availability_status_label',
                      client.isAvailable
                          ? AppLocalizations.of(context).translate('client_detail_status_available')
                          : AppLocalizations.of(context).translate('client_detail_status_unavailable'),
                    ),
                    _buildDetailRow(
                      context,
                      'client_detail_type_label',
                      AppLocalizations.of(context).translate('client_detail_type_client'),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppLocalizations.of(context).translate('client_detail_call_client_snackbar_prefix')} ${client.fullName} ${AppLocalizations.of(context).translate('client_detail_call_client_snackbar_suffix')} ${client.phone}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(
                        AppLocalizations.of(context).translate(
                            'client_detail_call_client_button'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
