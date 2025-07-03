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

class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({super.key, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedPaymentMethod = "cash";
  bool hasActiveRide = false;
  Position? currentPosition;
  String? startAddress; // لعنوان الموقع الحالي
  LatLng? selectedLocation; // لموقع الوجهة المحدد من الخريطة/البحث
  double? distance;
  double? estimatedFare;
  final TextEditingController startLocationController = TextEditingController();
  final TextEditingController endLocationController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final MapController mapController = MapController();
  bool showMap = false; // التحكم في ظهور الخريطة
  List<Marker> markers = [];
  final double fixedFareRate = 4.4; // سعر الكيلومتر الواحد
  List<dynamic> pendingTrips = [];
  bool isLoading = false; // حالة تحميل الرحلات المعلقة
  bool isCreatingTrip = false; // حالة إنشاء الرحلة
  bool _isMapReady = false; // ✅ جديد: لتتبع جاهزية FlutterMap

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // هذا سيجلب الموقع لكن لن يحرك الخريطة بعد
    _loadPendingTrips();
  }

  @override
  void dispose() {
    startLocationController.dispose();
    endLocationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // دالة مساعدة لعرض SnackBar
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

  Future<void> _loadPendingTrips() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final trips = await TripsApi.getPendingUserTrips(widget.userId);
      if (!mounted) return;
      setState(() => pendingTrips = trips);
    } catch (e) {
      _showSnackBar(
          AppLocalizations.of(context).translate('failed_to_load_trips'),
          isError: true);
      print('Failed to load pending trips: $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
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
      _loadPendingTrips();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_cancel_trip')}: $e',
          isError: true);
      print('Failed to cancel trip: $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateTrip(int tripId, String newStart, String newEnd) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await TripsApi.updateTrip(
        tripId: tripId,
        startAddress: newStart,
        endAddress: newEnd,
      );
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).translate('ride_updated'));
      _loadPendingTrips();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('update_failed')}: $e',
          isError: true);
      print('Failed to update trip: $e');
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

  void _showEditDialog(Map<String, dynamic> trip) {
    final TextEditingController startController =
        TextEditingController(text: trip['startLocation']['address']);
    final TextEditingController endController =
        TextEditingController(text: trip['endLocation']['address']);
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // ألوان الثيم لـ CustomTextField في AlertDialog
    final Color dialogTextColor =
        theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color dialogHintTextColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(local.translate('edit_ride'),
            style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              hintText: local.translate('start_location'),
              controller: startController,
              textColor: dialogTextColor,
              hintTextColor: dialogHintTextColor,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              hintText: local.translate('end_location'),
              controller: endController,
              textColor: dialogTextColor,
              hintTextColor: dialogHintTextColor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(local.translate('cancel'),
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              _updateTrip(
                trip['tripId'],
                startController.text,
                endController.text,
              );
              Navigator.pop(context);
            },
            child: Text(local.translate('save'),
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
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

      // Reverse geocode to get a readable address for the current location
      try {
        final response = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
          ),
          headers: {
            'User-Agent': 'TaxiApp/1.0 (contact@example.com)'
          }, // ✅ إضافة User-Agent
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          startAddress = data['display_name'] ??
              AppLocalizations.of(context).translate('unknown_location');
        } else {
          startAddress =
              AppLocalizations.of(context).translate('unknown_location');
          print(
              'Nominatim reverse geocoding failed: ${response.statusCode}, ${response.body}');
        }
      } catch (e) {
        print('Error during reverse geocoding for current location: $e');
        startAddress =
            AppLocalizations.of(context).translate('unknown_location');
      }

      setState(() {
        currentPosition = position;
        startLocationController.text =
            startAddress!; // تعيين العنوان الذي تم الحصول عليه
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
      // ✅ تمت إزالة mapController.move() من هنا
    } catch (e) {
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_get_location')}: $e',
          isError: true);
      print('Failed to get current location: $e');
    }
  }

  void _toggleMap() {
    setState(() {
      showMap = !showMap;
    });
    // ✅ تحريك الخريطة فقط إذا كانت ستظهر، والموقع الحالي متاح، والخريطة جاهزة
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
        headers: {
          'User-Agent': 'TaxiApp/1.0 (contact@example.com)'
        }, // ✅ إضافة User-Agent
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
        print(
            'Nominatim search failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('search_failed')}: $e',
          isError: true);
      print('Search location failed: $e');
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

    // ✅ تحريك الخريطة فقط إذا كانت جاهزة
    if (_isMapReady) {
      mapController.move(point, 15.0);
    }

    if (currentPosition != null && selectedLocation != null) {
      distance = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      );
      estimatedFare = distance! * fixedFareRate;
    } else {
      // ✅ إعادة تعيين المسافة والأجرة إذا لم تتوفر كل الإحداثيات
      distance = null;
      estimatedFare = null;
    }
  }

  void _selectLocationFromMap(TapPosition tapPosition, LatLng point) async {
    _showSnackBar(AppLocalizations.of(context).translate('getting_address'));
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}',
        ),
        headers: {
          'User-Agent': 'TaxiApp/1.0 (contact@example.com)'
        }, // ✅ إضافة User-Agent
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ??
            AppLocalizations.of(context).translate('unknown_location');
        _updateSelectedLocation(point, address);
      } else {
        _showSnackBar(
            '${AppLocalizations.of(context).translate('failed_to_get_address')}: ${response.statusCode}',
            isError: true);
        print(
            'Nominatim reverse geocoding failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_get_address')}: $e',
          isError: true);
      print('Select location from map failed: $e');
    }
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // بالكيلومتر
  }

  Future<void> _createTrip() async {
    if (!mounted) return;
    if (currentPosition == null ||
        selectedLocation == null ||
        endLocationController.text.isEmpty) {
      _showSnackBar(
          AppLocalizations.of(context).translate('specify_start_end_location'),
          isError: true);
      return;
    }
    if (distance == null || estimatedFare == null) {
      _showSnackBar(
          AppLocalizations.of(context)
              .translate('distance_fare_not_calculated'),
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
      );

      if (!mounted) return;

      _showSnackBar(
          AppLocalizations.of(context).translate('trip_created_successfully'));
      // إعادة تعيين الحقول بعد إنشاء الرحلة بنجاح
      setState(() {
        showMap = false;
        endLocationController.clear();
        searchController.clear();
        selectedLocation = null;
        distance = null;
        estimatedFare = null;
        // لا تمسح startLocationController
        _loadPendingTrips(); // أعد تحميل الرحلات المعلقة
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          '${AppLocalizations.of(context).translate('failed_to_create_trip')}: $e',
          isError: true);
      print('Failed to create trip: $e');
    } finally {
      if (!mounted) return;
      setState(() => isCreatingTrip = false);
    }
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
              "🚖 ${local.translate('new_ride_request')}",
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
            const SizedBox(height: 20),
            _buildEstimateFareAndPayment(context),
            const SizedBox(height: 20),
            _buildRequestRideButton(context),
            const SizedBox(height: 30),
            Text(
              "🕒  ${local.translate('pending_requests')}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            _buildPendingTripsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTripsList(ThemeData theme) {
    if (isLoading) {
      return Center(
          child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)));
    }

    if (pendingTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).translate('no_pending_rides'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingTrips.length,
      itemBuilder: (context, index) {
        final trip = pendingTrips[index];
        return Card(
          color: theme.cardColor,
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context).translate('from')}: ${trip['startLocation']['address']}',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context).translate('to')}: ${trip['endLocation']['address']}',
                  style: theme.textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      icon:
                          Icon(Icons.edit, color: theme.colorScheme.secondary),
                      tooltip: AppLocalizations.of(context).translate('edit'),
                      onPressed: () => _showEditDialog(trip),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      tooltip: AppLocalizations.of(context).translate('delete'),
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
                  onTap: (tapPosition, point) =>
                      _selectLocationFromMap(tapPosition, point),
                  // ✅ هذا هو المكان الذي يتم فيه إعداد الخريطة
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        _isMapReady = true; // الخريطة جاهزة الآن
                      });
                      // قم بتحريك الخريطة إلى الموقع الحالي فقط إذا كان متاحاً
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
                  Text(local.translate('distance'),
                      style: theme.textTheme.bodyLarge),
                  Text(
                      "${distance!.toStringAsFixed(1)} ${local.translate('km')}",
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Divider(color: theme.dividerColor.withOpacity(0.5)),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "💰 ${local.translate('fare_estimate')}:",
                  style: theme.textTheme.bodyLarge,
                ),
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
                Text(
                  "💳 ${local.translate('payment_method')}:",
                  style: theme.textTheme.bodyLarge,
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPaymentMethod,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.textTheme.bodyLarge?.color),
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
          ? local.translate('requesting_ride')
          : "🚖 ${local.translate('request_ride')}",
      width: double.infinity,
      onPressed:
          isCreatingTrip || currentPosition == null || selectedLocation == null
              ? null
              : _createTrip,
      buttonColor: theme.colorScheme.secondary,
      textColor: theme.colorScheme.onSecondary,
    );
  }
}
