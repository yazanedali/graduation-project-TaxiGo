import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/services/trips_api.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/screens/components/custom_button.dart';
import 'package:taxi_app/screens/components/custom_text_field.dart';
import 'package:intl/intl.dart';

class ScheduledTripsPage extends StatefulWidget {
  final int userId;

  const ScheduledTripsPage({super.key, required this.userId});

  @override
  _ScheduledTripsPageState createState() => _ScheduledTripsPageState();
}

class _ScheduledTripsPageState extends State<ScheduledTripsPage> {
  String? selectedPaymentMethod = "cash";
  Position? currentPosition;
  String? startAddress;
  LatLng? selectedLocation;
  double? distance;
  double? estimatedFare;
  final TextEditingController startLocationController = TextEditingController();
  final TextEditingController endLocationController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();
  final MapController mapController = MapController();
  bool showMap = false;
  List<Marker> markers = [];
  final double fixedFareRate = 4.4;
  List<dynamic> scheduledTrips = [];
  bool isLoading = false;
  bool isCreatingTrip = false;
  bool _isMapReady = false;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadScheduledTrips();
  }

  @override
  void dispose() {
    startLocationController.dispose();
    endLocationController.dispose();
    searchController.dispose();
    dateTimeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _loadScheduledTrips() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final trips = await TripsApi.getPendingUserTrips(widget.userId);
      if (!mounted) return;
      setState(() {
        scheduledTrips =
            trips.where((trip) => trip['isScheduled'] == true).toList();
      });
    } catch (e) {
      _showSnackBar(
          AppLocalizations.of(context).translate('failed_to_load_trips'),
          isError: true);
      print('Failed to load scheduled trips: $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!);
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
            AppLocalizations.of(context).translate('location_service_disabled'),
            isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
              AppLocalizations.of(context)
                  .translate('location_permission_denied'),
              isError: true);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      try {
        final response = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
          ),
          headers: {'User-Agent': 'TaxiApp/1.0'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          startAddress = data['display_name'] ??
              AppLocalizations.of(context).translate('unknown_location');
        } else {
          startAddress =
              AppLocalizations.of(context).translate('unknown_location');
        }
      } catch (e) {
        startAddress =
            AppLocalizations.of(context).translate('unknown_location');
      }

      setState(() {
        currentPosition = position;
        startLocationController.text = startAddress!;
        markers = [
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(position.latitude, position.longitude),
            child: Icon(Icons.my_location,
                color: Theme.of(context).colorScheme.primary),
          ),
        ];
      });
    } catch (e) {
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_get_location')}: $e',
          isError: true);
    }
  }

  void _toggleMap() {
    setState(() {
      showMap = !showMap;
    });
    if (showMap && currentPosition != null && _isMapReady) {
      mapController.move(
          LatLng(currentPosition!.latitude, currentPosition!.longitude), 15.0);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    _showSnackBar(
        AppLocalizations.of(context).translate('searching_for_location'));

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1',
        ),
        headers: {'User-Agent': 'TaxiApp/1.0'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          _updateSelectedLocation(
              LatLng(lat, lon), firstResult['display_name']);
        } else {
          _showSnackBar(
              AppLocalizations.of(context).translate('location_not_found'),
              isError: true);
        }
      } else {
        _showSnackBar(
            '${AppLocalizations.of(context).translate('search_failed')}: ${response.statusCode}',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('search_failed')}: $e',
          isError: true);
    }
  }

  void _updateSelectedLocation(LatLng point, String address) {
    if (!mounted) return;
    setState(() {
      selectedLocation = point;
      endLocationController.text = address;
      markers = [
        if (currentPosition != null)
          Marker(
            width: 40.0,
            height: 40.0,
            point:
                LatLng(currentPosition!.latitude, currentPosition!.longitude),
            child: Icon(Icons.my_location,
                color: Theme.of(context).colorScheme.primary),
          ),
        Marker(
          width: 40.0,
          height: 40.0,
          point: point,
          child: Icon(Icons.location_pin,
              color: Theme.of(context).colorScheme.error),
        )
      ];
    });

    if (_isMapReady) {
      mapController.move(point, 15.0);
    }

    if (currentPosition != null && selectedLocation != null) {
      distance = Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            selectedLocation!.latitude,
            selectedLocation!.longitude,
          ) /
          1000;
      estimatedFare = distance! * fixedFareRate;
    } else {
      distance = null;
      estimatedFare = null;
    }
  }

  Future<void> _createScheduledTrip() async {
    if (!mounted) return;
    if (currentPosition == null ||
        selectedLocation == null ||
        endLocationController.text.isEmpty ||
        selectedDateTime == null) {
      _showSnackBar(
          AppLocalizations.of(context).translate('specify_all_fields'),
          isError: true);
      return;
    }

    setState(() => isCreatingTrip = true);

    try {
      await TripsApi.createTrip(
        userId: widget.userId,
        startLocation: {
          'longitude': currentPosition!.longitude,
          'latitude': currentPosition!.latitude,
          'address': startLocationController.text,
        },
        endLocation: {
          'longitude': selectedLocation!.longitude,
          'latitude': selectedLocation!.latitude,
          'address': endLocationController.text,
        },
        distance: distance!,
        paymentMethod: selectedPaymentMethod!,
        startTime: selectedDateTime!,
        isScheduled: true,
      );

      if (!mounted) return;

      _showSnackBar(
          AppLocalizations.of(context).translate('scheduled_trip_created'));
      setState(() {
        showMap = false;
        endLocationController.clear();
        searchController.clear();
        dateTimeController.clear();
        selectedLocation = null;
        distance = null;
        estimatedFare = null;
        selectedDateTime = null;
        _loadScheduledTrips();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_create_trip')}: $e',
          isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isCreatingTrip = false);
    }
  }

  Future<void> _cancelTrip(int tripId) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await TripsApi.cancelTrip(tripId);
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context)
          .translate('trip_cancelled_successfully'));
      _loadScheduledTrips();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_cancel_trip')}: $e',
          isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _showDeleteConfirmation(int tripId) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(local.translate('confirm_cancellation'),
            style: theme.textTheme.titleLarge),
        content: Text(local.translate('are_you_sure_cancel_ride'),
            style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(local.translate('cancel'),
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTrip(tripId);
            },
            child: Text(
              local.translate('confirm'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color hintTextColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 30 : 16.0, vertical: 16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              (kToolbarHeight +
                  MediaQuery.of(context).padding.top +
                  (isLargeScreen ? 0 : kBottomNavigationBarHeight)),
          maxWidth: isLargeScreen ? 800 : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⏰ ${local.translate('new_scheduled_ride')}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            _buildLocationInput(
              context,
              "📍 ${local.translate('current_location')}",
              local.translate('enter_your_location'),
              startLocationController,
              null,
              isReadOnly: true,
            ),
            const SizedBox(height: 15),
            _buildDestinationInput(context, hintTextColor, textColor),
            const SizedBox(height: 15),
            _buildDateTimePicker(context),
            const SizedBox(height: 20),
            _buildEstimateFareAndPayment(context),
            const SizedBox(height: 20),
            _buildRequestRideButton(context),
            const SizedBox(height: 30),
            Text(
              "📅 ${local.translate('scheduled_rides')}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            _buildScheduledTripsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
    VoidCallback? onTap, {
    bool isReadOnly = false,
  }) {
    final theme = Theme.of(context);
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color hintTextColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        CustomTextField(
          hintText: hint,
          controller: controller,
          readOnly: isReadOnly,
          hintTextColor: hintTextColor,
          textColor: textColor,
          prefixIcon: Icons.location_on,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildDestinationInput(
      BuildContext context, Color hintTextColor, Color textColor) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🎯 ${local.translate('destination')}",
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CustomTextField(
          hintText: local.translate('search_location'),
          controller: searchController,
          hintTextColor: hintTextColor,
          textColor: textColor,
          prefixIcon: Icons.search,
          suffixIcon: Icons.map,
          onSuffixPressed: _toggleMap,
          onSubmitted: (value) => _searchLocation(value),
        ),
        if (showMap) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentPosition != null
                      ? LatLng(
                          currentPosition!.latitude, currentPosition!.longitude)
                      : const LatLng(31.9454, 35.9284),
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    _updateSelectedLocation(point, 'Selected Location');
                  },
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        _isMapReady = true;
                      });
                      if (currentPosition != null) {
                        mapController.move(
                          LatLng(currentPosition!.latitude,
                              currentPosition!.longitude),
                          15.0,
                        );
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.taxi_app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color hintTextColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "⏰ ${local.translate('date_and_time')}",
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CustomTextField(
          hintText: local.translate('select_date_time'),
          controller: dateTimeController,
          hintTextColor: hintTextColor,
          textColor: textColor,
          prefixIcon: Icons.calendar_today,
          readOnly: true,
          onTap: () => _selectDateTime(context),
        ),
      ],
    );
  }

  Widget _buildEstimateFareAndPayment(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Card(
      elevation: 4,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (distance != null && selectedLocation != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${local.translate('distance')}: ${distance!.toStringAsFixed(1)} ${local.translate('km')}",
                  ),
                ],
              ),
              Divider(color: theme.dividerColor.withOpacity(0.5)),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("💰 ${local.translate('fare_estimate')}:"),
                Text(
                  estimatedFare != null
                      ? "${estimatedFare!.toStringAsFixed(2)} ${local.translate('currency')}"
                      : "0.00 ${local.translate('currency')}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(color: theme.dividerColor.withOpacity(0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("💳 ${local.translate('payment_method')}:"),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPaymentMethod,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyLarge,
                    icon: Icon(Icons.arrow_drop_down,
                        color: theme.iconTheme.color),
                    items: ["cash", "card", "wallet"].map((String method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(local.translate(method)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedPaymentMethod = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestRideButton(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return CustomButton(
      text: isCreatingTrip
          ? local.translate('scheduling_ride')
          : "⏰ ${local.translate('schedule_ride')}",
      width: double.infinity,
      onPressed: isCreatingTrip ||
              currentPosition == null ||
              selectedLocation == null ||
              selectedDateTime == null
          ? null
          : _createScheduledTrip,
      buttonColor: theme.colorScheme.secondary,
      textColor: theme.colorScheme.onSecondary,
    );
  }

  Widget _buildScheduledTripsList(ThemeData theme) {
    if (isLoading) {
      return Center(
          child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)));
    }

    if (scheduledTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).translate('no_scheduled_rides'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scheduledTrips.length,
      itemBuilder: (context, index) {
        final trip = scheduledTrips[index];
        final scheduledTime = DateTime.parse(trip['scheduledStartTime']);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d, y').format(scheduledTime),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      DateFormat('h:mm a').format(scheduledTime),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).translate('from')}: ${trip['startLocation']['address']}',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context).translate('to')}: ${trip['endLocation']['address']}',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).translate('distance')}: ${trip['distance'].toStringAsFixed(1)} ${AppLocalizations.of(context).translate('km')}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${AppLocalizations.of(context).translate('estimated_fare')}: ${trip['estimatedFare'].toStringAsFixed(2)} ${AppLocalizations.of(context).translate('currency')}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      onPressed: () => _showDeleteConfirmation(trip['tripId']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
