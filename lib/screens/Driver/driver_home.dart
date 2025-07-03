import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/driver.dart';
import 'package:taxi_app/models/trip.dart';
import 'package:taxi_app/services/drivers_api.dart';
import 'package:taxi_app/services/trips_api.dart';

class DriverHomePage extends StatefulWidget {
  final int driverId;

  const DriverHomePage({super.key, required this.driverId});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  late Future<Driver> _driverInfoFuture;
  late Future<List<Trip>> _recentTripsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _driverInfoFuture = DriversApi.getDriverById(widget.driverId);
      _recentTripsFuture = TripsApi.getRecentTrips(widget.driverId)
          .then((trips) => trips.where((t) => t.status == 'completed').toList())
          .catchError((_) => <Trip>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Distinguish web vs mobile
    final isWeb = kIsWeb;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
        ),
      ),
    );
  }

  // Web layout: profile and trips side by side
  Widget _buildWebLayout(BuildContext context) {
    return FutureBuilder<Driver>(
      future: _driverInfoFuture,
      builder: (c, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading driver info'));
        }
        final driver = snapshot.data!;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildDriverProfile(context, driver)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildRecentTripsSection(context)),
          ],
        );
      },
    );
  }

  // Mobile layout: vertical list
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Driver>(
          future: _driverInfoFuture,
          builder: (c, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading driver info'));
            }
            return _buildDriverProfile(context, snapshot.data!);
          },
        ),
        const SizedBox(height: 20),
        _buildRecentTripsSection(context),
      ],
    );
  }

  Widget _buildDriverProfile(BuildContext context, Driver driver) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isDesktop ? 40 : 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: driver.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(driver.profileImageUrl!)
                      : null,
                  child: driver.profileImageUrl?.isNotEmpty != true
                      ? Icon(
                          LucideIcons.user,
                          size: isDesktop ? 50 : 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        driver.taxiOfficeId,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildDriverDetail(
                  context,
                  icon: LucideIcons.car,
                  title: local.translate('car_model'),
                  value: driver.carModel,
                ),
                _buildDriverDetail(
                  context,
                  icon: LucideIcons.hash,
                  title: local.translate('plate_number'),
                  value: driver.carPlateNumber,
                ),
                _buildDriverDetail(
                  context,
                  icon: LucideIcons.star,
                  title: local.translate('rating'),
                  value: driver.rating.toStringAsFixed(1),
                ),
                // _buildDriverDetail(
                //   context,
                //   icon: LucideIcons.hash,
                //   title: local.translate('number_of_ratings'),
                //   value: driver.numberOfRatings.toString(),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDetail(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(title, style: theme.textTheme.bodySmall),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTripsSection(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return FutureBuilder<List<Trip>>(
      future: _recentTripsFuture,
      builder: (c, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(local.translate('error_loading_trips'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error));
        }
        final trips = snapshot.data ?? [];
        if (trips.isEmpty) {
          return Text(local.translate('no_recent_trips'));
        }

        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(local.translate('recent_trips'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...trips.take(5).map((trip) {
                  return ListTile(
                    leading: Icon(LucideIcons.car,
                        color: theme.colorScheme.secondary),
                    title: Text('${local.translate('trip')} #${trip.tripId}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${local.translate('from')}: ${trip.startLocation.address}'),
                        Text(
                            '${local.translate('to')}: ${trip.endLocation.address}'),
                      ],
                    ),
                    trailing: Text('\$${trip.actualFare.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
