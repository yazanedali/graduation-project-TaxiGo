import 'package:flutter/material.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/driver.dart';
import 'package:intl/intl.dart';

class DriverDetailPageWeb extends StatelessWidget {
  final Driver driver;

  const DriverDetailPageWeb({super.key, required this.driver});

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        AppLocalizations.of(context).translate(titleKey),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String labelKey, String value) {
    final labelStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        );
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.normal,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text("${AppLocalizations.of(context).translate(labelKey)}:", style: labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.end, style: valueStyle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.fullName),
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
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: NetworkImage(
                            driver.profileImageUrl ??
                                'https://via.placeholder.com/150',
                          ),
                          backgroundColor: theme.colorScheme.background,
                          onBackgroundImageError: (exception, stackTrace) =>
                              debugPrint('Image load error: $exception'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          driver.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Personal Info
                    _buildSectionTitle(context, 'driver_detail_personal_info_title'),
                    _buildDetailRow(context, 'driver_detail_phone_label', driver.phone),
                    _buildDetailRow(context, 'driver_detail_email_label', driver.email),
                    _buildDetailRow(
                      context,
                      'driver_detail_rating_label',
                      "${driver.rating.toStringAsFixed(1)} ★ (${driver.numberOfRatings} ${AppLocalizations.of(context).translate('driver_detail_ratings_suffix')})",
                    ),
                    _buildDetailRow(
                      context,
                      'driver_detail_earnings_label',
                      "${driver.earnings.toStringAsFixed(2)}",
                    ),
                    _buildDetailRow(
                      context,
                      'driver_detail_availability_status_label',
                      driver.isAvailable
                          ? AppLocalizations.of(context).translate('driver_detail_status_available')
                          : AppLocalizations.of(context).translate('driver_detail_status_unavailable'),
                    ),
                    _buildDetailRow(
                      context,
                      'driver_detail_joined_date_label',
                      DateFormat('dd/MM/yyyy').format(driver.joinedAt),
                    ),

                    // Car Info
                    _buildSectionTitle(context, 'driver_detail_car_info_title'),
                    _buildDetailRow(context, 'driver_detail_car_model_label', driver.carModel),
                    _buildDetailRow(context, 'driver_detail_car_color_label', driver.carColor),
                    _buildDetailRow(context, 'driver_detail_car_plate_label', driver.carPlateNumber),
                    _buildDetailRow(
                      context,
                      'driver_detail_car_year_label',
                      driver.carYear?.toString() ??
                          AppLocalizations.of(context).translate('driver_detail_car_year_not_specified'),
                    ),

                    // License Info
                    _buildSectionTitle(context, 'driver_detail_license_info_title'),
                    _buildDetailRow(context, 'driver_detail_license_number_label', driver.licenseNumber),
                    _buildDetailRow(
                      context,
                      'driver_detail_license_expiry_label',
                      DateFormat('dd/MM/yyyy').format(driver.licenseExpiry),
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppLocalizations.of(context).translate('driver_detail_call_driver_snackbar_prefix')} ${driver.fullName} ${AppLocalizations.of(context).translate('driver_detail_call_driver_snackbar_suffix')} ${driver.phone}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(AppLocalizations.of(context).translate('driver_detail_call_driver_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
