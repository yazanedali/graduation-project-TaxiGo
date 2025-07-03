import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/trip.dart';
import 'package:taxi_app/services/trips_api.dart';

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  late Future<List<Trip>> _completedTripsFuture;
  late Future<List<Trip>> _inProgressTripsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() => _isLoading = true);

    _completedTripsFuture =
        TripsApi.getAllTripsWithStatus(status: 'completed').catchError((error) {
      debugPrint('Error loading completed trips: $error');
      return <Trip>[];
    });

    _inProgressTripsFuture =
        TripsApi.getAllTripsWithStatus(status: 'in_progress')
            .catchError((error) {
      debugPrint('Error loading in-progress trips: $error');
      return <Trip>[];
    });

    Future.wait([_completedTripsFuture, _inProgressTripsFuture])
        .then((_) => setState(() => _isLoading = false))
        .catchError((error) {
      debugPrint('Error in Future.wait: $error');
      setState(() => _isLoading = false);
    });
  }

  void _showTripDetails(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(isDesktop ? 100 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 700 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${local.translate('trip_details')} #${trip.tripId}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: _getStatusIcon(trip.status),
                  label: local.translate('status'),
                  value: _getStatusText(trip.status, local),
                  color: _getStatusColor(trip.status),
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.mapPin,
                  label: local.translate('pickup_location'),
                  value: trip.startLocation.address,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: LucideIcons.mapPin,
                  label: local.translate('dropoff_location'),
                  value: trip.endLocation.address,
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.calendar,
                  label: local.translate('date'),
                  value: _formatDate(trip.startTime ?? DateTime.now()),
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: LucideIcons.clock,
                  label: local.translate('time'),
                  value: _formatTime(trip.startTime ?? DateTime.now()),
                  theme: theme,
                ),
                if (trip.endTime != null && trip.status == 'completed') ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: LucideIcons.clock,
                    label: local.translate('end_time'),
                    value: _formatTime(trip.endTime!),
                    theme: theme,
                  ),
                ],
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.dollarSign,
                  label: local.translate('fare'),
                  value: "\$${trip.actualFare.toStringAsFixed(2)}",
                  theme: theme,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(local.translate('close')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? theme.colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary))
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 0 : 16,
                vertical: 32,
              ),
              child: RefreshIndicator(
                onRefresh: () async => _loadTrips(),
                color: theme.colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) _buildDesktopHeader(local, theme),
                      if (!isDesktop)
                        _buildMobileSections(context, local, theme),
                      if (isDesktop) _buildDesktopTable(local, theme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopHeader(AppLocalizations local, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 16, bottom: 24),
      child: Text(
        local.translate('All Trips'),
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMobileSections(
      BuildContext context, AppLocalizations local, ThemeData theme) {
    return Column(
      children: [
        _buildTripSection(
          context,
          title: local.translate('in_progress_trips'),
          icon: LucideIcons.clock,
          future: _inProgressTripsFuture,
          emptyMessage: local.translate('no_in_progress_trips'),
        ),
        const SizedBox(height: 24),
        _buildTripSection(
          context,
          title: local.translate('completed_trips'),
          icon: LucideIcons.checkCircle,
          future: _completedTripsFuture,
          emptyMessage: local.translate('no_completed_trips'),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(AppLocalizations local, ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            _buildTableHeader(local, theme),
            const SizedBox(height: 12),
            FutureBuilder(
              future: Future.wait([
                _inProgressTripsFuture,
                _completedTripsFuture,
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorWidget(theme, local);

                final allTrips = [
                  ...snapshot.data?[0] ?? [],
                  ...snapshot.data?[1] ?? [],
                ];

                if (allTrips.isEmpty)
                  return _buildEmptyState(
                      theme, local.translate('no_trips_found'));

                return Table(
                  columnWidths: const {
                    0: FixedColumnWidth(120),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(160),
                    3: FixedColumnWidth(120),
                    4: FixedColumnWidth(140),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  children: [
                    for (final trip in allTrips)
                      TableRow(
                        decoration: BoxDecoration(
                          color: _getStatusColor(trip.status).withOpacity(0.03),
                        ),
                        children: [
                          InkWell(
                            onTap: () => _showTripDetails(context, trip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "#${trip.tripId}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showTripDetails(context, trip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.startLocation.address.split(',').first,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(LucideIcons.arrowDown,
                                      size: 16,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    trip.endLocation.address.split(',').first,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showTripDetails(context, trip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(
                                        trip.startTime ?? DateTime.now()),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    _formatTime(
                                        trip.startTime ?? DateTime.now()),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showTripDetails(context, trip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "\$${trip.actualFare.toStringAsFixed(2)}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showTripDetails(context, trip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: _buildStatusBadge(
                                    trip.status, local, theme),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      String status, AppLocalizations local, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: _getStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(status, local),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations local, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FixedColumnWidth(200),
          2: FixedColumnWidth(160),
          3: FixedColumnWidth(120),
          4: FixedColumnWidth(140),
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell(local.translate('trip_id'), theme),
              _buildHeaderCell(local.translate('route'), theme),
              _buildHeaderCell(local.translate('date'), theme),
              _buildHeaderCell(local.translate('fare'), theme),
              _buildHeaderCell(local.translate('status'), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTripSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Future<List<Trip>> future,
    required String emptyMessage,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Trip>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return _buildErrorWidget(theme, AppLocalizations.of(context));

            final trips = snapshot.data ?? [];

            if (trips.isEmpty) return _buildEmptyState(theme, emptyMessage);

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _buildMobileTripCard(trips[index], theme),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileTripCard(Trip trip, ThemeData theme) {
    final local = AppLocalizations.of(context);

    return InkWell(
      onTap: () => _showTripDetails(context, trip),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${local.translate('trip')} #${trip.tripId}",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(trip.status, local, theme),
                ],
              ),
              const SizedBox(height: 16),
              _buildMobileTripDetail(
                icon: LucideIcons.mapPin,
                label: local.translate('from'),
                value: trip.startLocation.address,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildMobileTripDetail(
                icon: LucideIcons.mapPin,
                label: local.translate('to'),
                value: trip.endLocation.address,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildMobileTripDetail(
                icon: LucideIcons.clock,
                label: trip.status == 'completed'
                    ? local.translate('completed_on')
                    : local.translate('started_on'),
                value: _formatDateTime(trip.startTime ?? DateTime.now()),
                theme: theme,
              ),
              if (trip.status == 'completed') ...[
                const SizedBox(height: 12),
                _buildMobileTripDetail(
                  icon: LucideIcons.dollarSign,
                  label: local.translate('fare'),
                  value: "\$${trip.actualFare.toStringAsFixed(2)}",
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTripDetail({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, AppLocalizations local) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            local.translate('error_loading_trips'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadTrips,
            icon: Icon(Icons.refresh, size: 18),
            label: Text(local.translate('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.list,
              size: 40,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return LucideIcons.checkCircle;
      case 'in_progress':
        return LucideIcons.clock;
      default:
        return LucideIcons.hourglass;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations local) {
    switch (status) {
      case 'completed':
        return local.translate('completed');
      case 'in_progress':
        return local.translate('in_progress');
      default:
        return local.translate('pending');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
