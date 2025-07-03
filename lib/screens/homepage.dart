import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi_app/screens/about.dart';
import 'package:taxi_app/screens/maps_screen.dart';
import 'package:taxi_app/screens/public_offices_map.dart';
import 'package:taxi_app/screens/rodes_telgrame.dart'; // تأكد من المسار الصحيح لهذا الملف
import 'package:taxi_app/widgets/CustomAppBar.dart'; // تأكد من المسار الصحيح لهذا الملف
import 'package:taxi_app/language/localization.dart'; // تأكد من المسار الصحيح لهذا الملف
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb; // <--- تم إضافة هذا الاستيراد

class MapSearchDialog extends StatefulWidget {
  final LatLng initialCenter;
  const MapSearchDialog({super.key, required this.initialCenter});
  @override
  _MapSearchDialogState createState() => _MapSearchDialogState();
}

class _MapSearchDialogState extends State<MapSearchDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  List<dynamic> _searchResults = [];

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
    try {
      final response =
          await http.get(url, headers: {'Accept-Language': 'ar,en'});
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {/* Handle error */}
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate('select_location')),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)
                      .translate('search_for_place'),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchLocation(_searchController.text)),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
            if (_searchResults.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(result['display_name']),
                      onTap: () {
                        final lat = double.parse(result['lat']);
                        final lon = double.parse(result['lon']);
                        final newLocation = LatLng(lat, lon);
                        setState(() {
                          _selectedLocation = newLocation;
                          _mapController.move(newLocation, 15.0);
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation!,
                  initialZoom: 14.0,
                  onTap: (tapPosition, latlng) {
                    setState(() {
                      _selectedLocation = latlng;
                    });
                  },
                ),
                children: [
                  TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c']),
                  if (_selectedLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                          width: 80.0,
                          height: 80.0,
                          point: _selectedLocation!,
                          child: const Icon(Icons.location_pin,
                              color: Colors.red, size: 40))
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            child: Text(AppLocalizations.of(context).translate('cancel')),
            onPressed: () => Navigator.of(context).pop()),
        FilledButton(
          child: Text(AppLocalizations.of(context).translate('select')),
          onPressed: _selectedLocation == null
              ? null
              : () => Navigator.of(context).pop(_selectedLocation),
        ),
      ],
    );
  }
}

// --- الصفحة الرئيسية ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LatLng _initialCenter = const LatLng(31.5017, 34.4668);
  final TextEditingController _pickUpController = TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final MapController _webMapController = MapController();

  LatLng? _pickUpLocation;
  LatLng? _dropOffLocation;
  double? _estimatedPrice;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _priceBreakdown = [];

  // متغير لتخزين نقاط المسار
  List<LatLng> _routePoints = [];

  static const double BASE_FARE = 3.0;
  static const double PER_KM_RATE = 1.75;
  static const double NIGHT_SURGE_MULTIPLIER = 1.25;
  static const double WEEKEND_SURGE_MULTIPLIER = 1.15;

  final String _telegramBotWebUrl = 'https://t.me/TaxiGobookbot'; // <--- رابط الويب للبوت
  final String _telegramBotAppUrl = 'tg://resolve?domain=TaxiGobookbot'; // <--- رابط التطبيق للبوت

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final location = LatLng(position.latitude, position.longitude);
    setState(() {
      _pickUpLocation = location;
      _pickUpController.text =
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
      _resetPriceAndRoute();
      _webMapController.move(location, 15.0);
    });
  }

  void _calculateAndShowPrice() {
    if (_pickUpLocation == null ||
        _dropOffLocation == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)
              .translate('all_fields_required_error'))));
      return;
    }
    final localizations = AppLocalizations.of(context);
    List<String> breakdown = [];
    final bookingDateTime = DateTime(_selectedDate!.year, _selectedDate!.month,
        _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    final distanceInMeters = Geolocator.distanceBetween(
        _pickUpLocation!.latitude,
        _pickUpLocation!.longitude,
        _dropOffLocation!.latitude,
        _dropOffLocation!.longitude);
    final double km = distanceInMeters / 1000;
    double price = BASE_FARE + (km * PER_KM_RATE);
    breakdown.add(
        "${localizations.translate('base_fare_distance')}: ${price.toStringAsFixed(2)}");
    if (bookingDateTime.hour < 5) {
      double nightAddition = price * (NIGHT_SURGE_MULTIPLIER - 1);
      price += nightAddition;
      breakdown.add(
          "${localizations.translate('night_surge')} (+25%): ${nightAddition.toStringAsFixed(2)}");
    }
    if (bookingDateTime.weekday == DateTime.friday ||
        bookingDateTime.weekday == DateTime.saturday) {
      double weekendAddition = price * (WEEKEND_SURGE_MULTIPLIER - 1);
      price += weekendAddition;
      breakdown.add(
          "${localizations.translate('weekend_surge')} (+15%): ${weekendAddition.toStringAsFixed(2)}");
    }
    setState(() {
      _estimatedPrice = price;
      _priceBreakdown = breakdown;
    });
  }

  void _resetPriceAndRoute() {
    setState(() {
      _estimatedPrice = null;
      _priceBreakdown.clear();
      _routePoints.clear();
    });
  }

  Future<void> _getRoute() async {
    if (_pickUpLocation == null || _dropOffLocation == null) return;

    final pickCoords =
        "${_pickUpLocation!.longitude},${_pickUpLocation!.latitude}";
    final dropCoords =
        "${_dropOffLocation!.longitude},${_dropOffLocation!.latitude}";
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$pickCoords;$dropCoords?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final points = coords
            .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
            .toList();
        setState(() => _routePoints = points);
      }
    } catch (e) {
      // يمكنك إضافة رسالة خطأ هنا إذا فشلت العملية
    }
  }

  Future<void> _showMapSelector(
      BuildContext context, Function(LatLng) onLocationSelected) async {
    final LatLng? result = await showDialog<LatLng>(
      context: context,
      builder: (BuildContext context) =>
          MapSearchDialog(initialCenter: _pickUpLocation ?? _initialCenter),
    );
    if (result != null) onLocationSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final translations = {
      'map': localizations.translate('map'),
      'history': localizations.translate('history'),
      'Roads': localizations.translate('Roads'),
      'admin': localizations.translate('admin'),
      'menu': localizations.translate('menu'),
      'driver': localizations.translate('driver'),
      'user': localizations.translate('user'),
      'manegar': localizations.translate('manegar'),
      'about': localizations.translate('about'),
      'taxi_offices': localizations.translate('taxi_offices'),
      'pick_up_location': localizations.translate('pick_up_location'),
      'drop_off_location': localizations.translate('drop_off_location'),
      'date': localizations.translate('date'),
      'time': localizations.translate('time'),
      'estimate_price': localizations.translate('estimate_price'),
      // <--- الترجمات الجديدة
      'book_via_telegram_button': localizations.translate('book_via_telegram_button'),
      'book_via_telegram_tooltip': localizations.translate('book_via_telegram_tooltip'),
      'cannot_open_telegram_error': localizations.translate('cannot_open_telegram_error'),
      // الترجمات
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 950;
        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(),
          drawer: isWeb ? null : _buildDrawer(theme, translations),
          body: Container(
            decoration: isWeb
                ? BoxDecoration(
                    gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ))
                : null,
            child: isWeb
                ? _buildWebLayout(theme, translations)
                : _buildMobileLayout(theme, translations),
          ),
        );
      },
    );
  }

  // --- واجهة الموبايل (بدون أي تعديل) ---
  Widget _buildMobileLayout(ThemeData theme, Map<String, String> t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildBookingForm(theme, t)),
          ),
          const SizedBox(height: 24),
          _buildMapThumbnail(context),
          const SizedBox(height: 24),
          if (_estimatedPrice != null) _buildPriceDetailsCard(theme, t),
        ],
      ),
    );
  }

  // --- واجهة الويب المعاد تصميمها ---
  Widget _buildWebLayout(ThemeData theme, Map<String, String> t) {
    return Row(
      children: [
        _buildSidebar(theme, t),
        Expanded(
          flex: 4,
          child: _buildBookingPanel(theme, t),
        ),
        Expanded(
          flex: 3,
          child: _buildMapViewContainer(),
        ),
      ],
    );
  }

  Widget _buildBookingPanel(ThemeData theme, Map<String, String> t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('TaxiGo'),
            style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 32),
          Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBookingForm(theme, t),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _estimatedPrice != null
                ? _buildPriceDetailsCard(theme, t)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapViewContainer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          mapController: _webMapController,
          options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              minZoom: 5,
              maxZoom: 18),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.app',
            ),
            // START: إضافة طبقة المسار
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6.0,
                    color: Colors.blueAccent,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            // END: إضافة طبقة المسار
            MarkerLayer(
              markers: [
                if (_pickUpLocation != null)
                  Marker(
                      point: _pickUpLocation!,
                      width: 80,
                      height: 80,
                      child: const Tooltip(
                          message: 'Pick-up',
                          child: Icon(Icons.location_on,
                              color: Colors.green, size: 40))),
                if (_dropOffLocation != null)
                  Marker(
                      point: _dropOffLocation!,
                      width: 80,
                      height: 80,
                      child: const Tooltip(
                          message: 'Drop-off',
                          child: Icon(Icons.location_pin,
                              color: Colors.red, size: 40))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm(ThemeData theme, Map<String, String> t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLocationField(
          _pickUpController,
          t['pick_up_location']!,
          (location) {
            setState(() {
              _pickUpLocation = location;
              _pickUpController.text =
                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
              _resetPriceAndRoute();
              _webMapController.move(location, 15.0);
              // استدعاء دالة المسار
              _getRoute();
            });
          },
          onGetCurrentLocation: _getCurrentLocation,
        ),
        const SizedBox(height: 12),
        _buildLocationField(
          _dropOffController,
          t['drop_off_location']!,
          (location) {
            setState(() {
              _dropOffLocation = location;
              _dropOffController.text =
                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
              _resetPriceAndRoute();
              if (_pickUpLocation != null) {
                _webMapController.fitCamera(CameraFit.bounds(
                    bounds: LatLngBounds(_pickUpLocation!, location),
                    padding: const EdgeInsets.all(50)));
              } else {
                _webMapController.move(location, 15.0);
              }
              // استدعاء دالة المسار
              _getRoute();
            });
          },
        ),
        const SizedBox(height: 12),
        _buildDateTimeFields(theme, t['date']!, t['time']!),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _calculateAndShowPrice,
          child: Text(t['estimate_price']!),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: t['book_via_telegram_tooltip']!,
          child: OutlinedButton.icon(
            icon: Image.asset('assets/telegram_icon.png', height: 24, width: 24),
            label: Text(t['book_via_telegram_button']!),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              // <--- التعديل الرئيسي هنا: اختيار الرابط بناءً على المنصة
              final urlToLaunch = kIsWeb ? _telegramBotWebUrl : _telegramBotAppUrl;
              if (await canLaunchUrl(Uri.parse(urlToLaunch))) {
                await launchUrl(Uri.parse(urlToLaunch));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t['cannot_open_telegram_error']!)),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(TextEditingController controller, String label,
      Function(LatLng) onLocationSelected,
      {VoidCallback? onGetCurrentLocation}) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: onGetCurrentLocation != null
            ? IconButton(
                icon: Icon(Icons.my_location,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: onGetCurrentLocation)
            : const Icon(Icons.location_on_outlined),
        suffixIcon: IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _showMapSelector(context, onLocationSelected)),
      ),
      onTap: () => _showMapSelector(context, onLocationSelected),
    );
  }

  Widget _buildDateTimeFields(
      ThemeData theme, String dateText, String timeText) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
                labelText: dateText,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.date_range)),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101));
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  _dateController.text =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                  _resetPriceAndRoute();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _timeController,
            readOnly: true,
            decoration: InputDecoration(
                labelText: timeText,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.access_time)),
            onTap: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now());
              if (pickedTime != null) {
                setState(() {
                  _selectedTime = pickedTime;
                  _timeController.text = pickedTime.format(context);
                  _resetPriceAndRoute();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetailsCard(ThemeData theme, Map<String, String> t) {
    String currency = AppLocalizations.of(context).translate('currency');
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${t['estimate_price']!}: ${_estimatedPrice!.toStringAsFixed(2)} $currency',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            if (_priceBreakdown.isNotEmpty) ...[
              const Divider(height: 20),
              Text(AppLocalizations.of(context).translate('price_details'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._priceBreakdown.map((detail) => Text('• $detail $currency',
                  style: theme.textTheme.bodyMedium)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMapThumbnail(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 75,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: ClipOval(
            child: FlutterMap(
              options: MapOptions(
                  initialCenter: _pickUpLocation ?? _initialCenter,
                  initialZoom: 13.0,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none)),
              children: [
                TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c']),
                if (_pickUpLocation != null)
                  MarkerLayer(markers: [
                    Marker(
                        point: _pickUpLocation!,
                        child: Icon(Icons.location_on,
                            color: Theme.of(context).colorScheme.primary))
                  ])
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.explore_outlined),
          label:
              Text(AppLocalizations.of(context).translate('explore_offices')),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PublicTaxiOfficesMap())),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              textStyle: Theme.of(context).textTheme.labelLarge),
        )
      ],
    );
  }

  Widget _buildSidebar(ThemeData theme, Map<String, String> t) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(right: BorderSide(color: theme.dividerColor))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(t['menu']!,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ListTile(
                    leading: const Icon(Icons.map),
                    title: Text(t['map']!),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const MapScreen()))),
                ListTile(
                    leading: const Icon(Icons.traffic),
                    title: Text(t['Roads']!),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (c) => RoadStatusScreen()))),
                ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(t['about']!),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const AboutPage()))),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.local_taxi),
                    title: Text(t['taxi_offices']!),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const PublicTaxiOfficesMap()))),
                ListTile(
                    leading: Image.asset('assets/telegram_icon.png', height: 24, width: 24),
                    title: Text(t['book_via_telegram_button']!),
                    onTap: () async {
                      // <--- التعديل الرئيسي هنا: اختيار الرابط بناءً على المنصة
                      final urlToLaunch = kIsWeb ? _telegramBotWebUrl : _telegramBotAppUrl;
                      if (await canLaunchUrl(Uri.parse(urlToLaunch))) {
                        await launchUrl(Uri.parse(urlToLaunch));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t['cannot_open_telegram_error']!)),
                        );
                      }
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(ThemeData theme, Map<String, String> t) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Text(t['menu']!,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
          ),
          ListTile(
              leading: const Icon(Icons.map),
              title: Text(t['map']!),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const MapScreen()))),

          ListTile(
              leading: const Icon(Icons.traffic),
              title: Text(t['Roads']!),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => RoadStatusScreen()))),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t['about']!),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const AboutPage()))),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.local_taxi),
              title: Text(t['taxi_offices']!),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => const PublicTaxiOfficesMap()))),
          ListTile(
              leading: Image.asset('assets/telegram_icon.png', height: 24, width: 24),
              title: Text(t['book_via_telegram_button']!),
              onTap: () async {
                // <--- التعديل الرئيسي هنا: اختيار الرابط بناءً على المنصة
                final urlToLaunch = kIsWeb ? _telegramBotWebUrl : _telegramBotAppUrl;
                if (await canLaunchUrl(Uri.parse(urlToLaunch))) {
                  await launchUrl(Uri.parse(urlToLaunch));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t['cannot_open_telegram_error']!)),
                  );
                }
              }),
        ],
      ),
    );
  }
}