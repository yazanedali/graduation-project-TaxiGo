import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/trip.dart';
import 'package:taxi_app/services/trips_api.dart'; // استخدم TripsApi بدلاً من EarningsApi
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  final int driverId;

  const EarningsPage({super.key, required this.driverId});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture =
        TripsApi.getDriverTripsWithStatus(widget.driverId, status:'completed');
  }

  // دالة لحساب إجمالي الأرباح محلياً
  double _calculateTotalEarnings(List<Trip> trips) {
    return trips
        .where((trip) => trip.status == 'completed')
        .fold(0, (sum, trip) => sum + trip.estimatedFare);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
     
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Trip>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final trips = snapshot.data ?? [];

            if (trips.isEmpty) {
              return Center(
                child: Text(
                  local.translate('no_earnings_found'),
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            final totalEarnings = _calculateTotalEarnings(trips);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, local.translate('total_earnings')),
                _buildEarningsSummary(context, totalEarnings),
                const SizedBox(height: 20),
                _buildSectionTitle(
                    context, local.translate('earnings_details')),
                Expanded(
                  child: _buildEarningsDetails(context, trips),
                ),
              ],
            );
          },
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

  Widget _buildEarningsSummary(BuildContext context, double totalEarnings) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${local.translate('total_earnings')}:",
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              "\$${totalEarnings.toStringAsFixed(2)}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsDetails(BuildContext context, List<Trip> trips) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return ListView.separated(
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final tripId = trip.tripId.toString();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              LucideIcons.dollarSign,
              color: theme.colorScheme.secondary,
            ),
            title: Text(
              "${local.translate('trip')} #$tripId",
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${local.translate('date')}: ${trip.startTime != null ? DateFormat('yyyy-MM-dd').format(trip.startTime!) : local.translate('unknown')}",
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  "${local.translate('distance')}: ${trip.distance} ${local.translate('km')}",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Text(
              "\$${trip.estimatedFare.toStringAsFixed(2)}",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }
}
