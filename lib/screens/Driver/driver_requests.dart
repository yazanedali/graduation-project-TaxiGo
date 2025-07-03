import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/trip.dart'; // تأكد أن هذا المسار صحيح
import 'package:taxi_app/screens/trip_map_page.dart';
import 'package:taxi_app/services/trips_api.dart';
import 'package:geolocator/geolocator.dart';

class DriverRequestsPage extends StatefulWidget {
  final int driverId;
  const DriverRequestsPage({super.key, required this.driverId});

  @override
  State<DriverRequestsPage> createState() => _DriverRequestsPageState();
}

class _DriverRequestsPageState extends State<DriverRequestsPage> {
  late Future<List<Trip>> _tripsFuture;
  bool _isLoading = true;
  String _currentTab = 'pending'; // 'pending' or 'accepted'
  Position? _currentPosition; // current position of the driver

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // طلب صلاحيات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)
                    .translate('location_service_disabled'))),
          );
        }
        throw Exception('خدمة الموقع غير مفعلة');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .translate('location_permission_denied'))),
            );
          }
          throw Exception('تم رفض صلاحيات الموقع');
        }
      }

      // الحصول على الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _loadTrips(); // تحميل الرحلات بعد الحصول على الموقع
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('failed_to_get_location'))),
        );
      }
      // إذا فشل الحصول على الموقع، نحميل الرحلات بدون تصفية
      _loadTrips();
    }
  }

  void _loadTrips() {
    setState(() {
      _isLoading = true;

      if (_currentTab == 'pending') {
        if (_currentPosition != null) {
          final future = TripsApi.getNearbyTrips(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          );

          _tripsFuture = future.then((data) {
            final String message = data['message'];
            final List<Trip> trips = data['trips'];

            if (message.isNotEmpty && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              });
            }

            setState(() => _isLoading = false);
            return trips;
          }).catchError((e) {
            // Handle errors from getNearbyTrips
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)
                        .translate('error_loading_nearby_trips'))),
              );
            }
            setState(() => _isLoading = false);
            return <Trip>[]; // Return empty list on error
          });
        } else {
          _tripsFuture = TripsApi.getPendingTrips().then((trips) {
            setState(() => _isLoading = false);
            return trips;
          }).catchError((e) {
            // Handle errors from getPendingTrips
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)
                        .translate('error_loading_pending_trips'))),
              );
            }
            setState(() => _isLoading = false);
            return <Trip>[];
          });
        }
      } else {
        _tripsFuture = TripsApi.getDriverTripsWithStatus(
          widget.driverId,
          status: 'accepted',
        ).then((trips) {
          setState(() => _isLoading = false);
          return trips;
        }).catchError((e) {
          // Handle errors from getDriverTripsWithStatus
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .translate('error_loading_accepted_trips'))),
            );
          }
          setState(() => _isLoading = false);
          return <Trip>[];
        });
      }
    });
  }

  Future<void> _handleAcceptTrip(int tripId) async {
    try {
      setState(() => _isLoading = true);
      await TripsApi.acceptTrip(
        tripId.toString(),
        widget.driverId,
        _currentPosition?.latitude ?? 0.0,
        _currentPosition?.longitude ?? 0.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('trip_accepted_success'))),
        );
      }
      _loadTrips(); // إعادة تحميل الرحلات
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('failed_to_accept_trip'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRejectTrip(int tripId) async {
    try {
      setState(() => _isLoading = true);
      await TripsApi.rejectTrip(tripId.toString(), widget.driverId);
      _loadTrips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('trip_rejected_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('failed_to_reject_trip'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ تم تعديل هذه الدالة لاستدعاء TripMapPage
  Future<void> _handleStartTrip(Trip trip) async {
    // Pass the whole trip object
    try {
      setState(() => _isLoading = true);
      await TripsApi.startTrip(
          trip.tripId); // Ensure tripId is String for API call

      // Navigate to TripMapPage
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripMapPage(
            tripId: trip.tripId,
            startLocation: trip.startLocation,
            endLocation: trip.endLocation,
            driverId: widget.driverId,
            token: '', // TODO: Replace with actual token if available
          ),
        ),
      );

      // If the map page returns true (meaning trip completed successfully)
      if (result == true) {
        _loadTrips(); // Reload trips to update the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('failed_to_start_trip'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 10, 
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  local.translate('pending_requests'),
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
              Tab(
                child: Text(
                  local.translate('accepted_trips'),
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
            onTap: (index) {
              setState(() => _currentTab = index == 0 ? 'pending' : 'accepted');
              _loadTrips();
            },
          ),
        ),
        body: TabBarView(
          children: [
            _buildTripsList(theme, local),
            _buildTripsList(theme, local),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(ThemeData theme, AppLocalizations local) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadTrips();
        await Future.delayed(
            const Duration(milliseconds: 500)); // Short delay for UX
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Trip>>(
              future: _tripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      local.translate('error_loading_trips'),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentTab == 'pending'
                              ? LucideIcons.clock
                              : LucideIcons.car,
                          size: 40,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentTab == 'pending'
                              ? local.translate('no_pending_requests')
                              : local.translate('no_accepted_trips'),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${local.translate('trip')} #${trip.tripId}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTripDetailRow(
                              icon: LucideIcons.mapPin,
                              label: local.translate('from'),
                              value: trip.startLocation.address,
                              theme: theme, // Pass theme
                            ),
                            _buildTripDetailRow(
                              icon: LucideIcons.mapPin,
                              label: local.translate('to'),
                              value: trip.endLocation.address,
                              theme: theme, // Pass theme
                            ),
                            _buildTripDetailRow(
                              icon: LucideIcons.map,
                              label: local.translate('distance'),
                              value:
                                  "${trip.distance} ${local.translate('km')}",
                              theme: theme, // Pass theme
                            ),
                            _buildTripDetailRow(
                              icon: LucideIcons.clock,
                              label: _currentTab == 'pending'
                                  ? local.translate('requested_at')
                                  : local.translate('accepted_at'),
                              value: _formatDateTime(_currentTab == 'pending'
                                  ? trip.requestedAt
                                  : trip.acceptedAt),
                              theme: theme, // Pass theme
                            ),
                            if (trip.timeoutDuration != null &&
                                _currentTab != 'pending')
                              _buildTripDetailRow(
                                icon: LucideIcons.clock,
                                label: local.translate('estimated_start_time'),
                                value: _formatTime(trip.timeoutDuration!),
                                theme: theme, // Pass theme
                              ),
                            _buildTripDetailRow(
                              icon: LucideIcons
                                  .wallet, // Updated icon for payment method
                              label: local.translate('payment_method'),
                              value: trip.paymentMethod,
                              theme: theme, // Pass theme
                            ),
                            const SizedBox(height: 16),
                            _currentTab == 'pending'
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(LucideIcons.check),
                                        label: Text(local.translate('accept')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _handleAcceptTrip(trip.tripId),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(LucideIcons.x),
                                        label: Text(local.translate('reject')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _handleRejectTrip(trip.tripId),
                                      ),
                                    ],
                                  )
                                :
                                // Changed to a Row for clarity and future expansion if needed
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(LucideIcons
                                            .map), // Changed to map icon
                                        label: Text(local.translate(
                                            'view_trip_on_map')), // "عرض الرحلة على الخريطة"
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme
                                              .primary, // Use primary color
                                          foregroundColor:
                                              theme.colorScheme.onPrimary,
                                        ),
                                        onPressed: () => _handleStartTrip(
                                            trip), // ✅ Pass the whole trip object
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildTripDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme, // Add theme parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18, color: theme.iconTheme.color), // Use iconTheme color
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface, // Text color from theme
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface, // Text color from theme
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}
