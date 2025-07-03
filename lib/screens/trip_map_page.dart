import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/trip.dart'; // تأكد أن هذا المسار صحيح ويحتوي على Location model
import 'package:taxi_app/services/trips_api.dart';
import 'package:geolocator/geolocator.dart';

class TripMapPage extends StatefulWidget {
  final int tripId;
  final Location startLocation;
  final Location endLocation;
  final int driverId;
  final String token;

  const TripMapPage({
    Key? key,
    required this.tripId,
    required this.startLocation,
    required this.endLocation,
    required this.driverId,
    required this.token,
  }) : super(key: key);

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  final MapController _mapController = MapController();
  bool _isCompletingTrip = false;
  bool _isLoadingRoute = true;

  LatLng? _driverCurrentLocation;
  List<LatLng> _currentRoutePoints = [];

  late String _orsApiKey;
  late String _telegramBotToken;

  Timer? _roadStatusTimer;
  List<Map<String, dynamic>> _blockedRoads = [];

  StreamSubscription<Position>? _positionStreamSubscription;

  // ✅ متغير جديد لتحديد ما إذا كانت الخريطة جاهزة
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _orsApiKey = '5b3ce3597851110001cf62485bf8e58a124640b1bc61ce2b4825433e';
    _telegramBotToken = '7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orsApiKey.isEmpty) {
        _showErrorSnackBar(
            AppLocalizations.of(context).translate('ors_api_key_missing'));
      }
      if (_telegramBotToken.isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)
            .translate('telegram_bot_token_missing'));
      }
    });

    _initMapAndRoute();
    // if (_telegramBotToken.isNotEmpty) {
    //   _startRoadStatusChecker();
    // }
    _startLocationTracking();
  }

  @override
  void dispose() {
    _roadStatusTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Future<void> _initMapAndRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });
    try {
      await _getDriverCurrentLocationOnce();

      if (_telegramBotToken.isNotEmpty) {
        await _fetchRoadStatusFromTelegram();
      }

      // ✅ لا تستدعي _getActualRoute هنا مباشرة
      // سيتم استدعاؤها بعد أن تكون الخريطة جاهزة في onMapReady
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context).translate(
          'error_loading_map_data',
        ));
      }
      if (kDebugMode) {
        print('Error initializing map and route: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Future<void> _getDriverCurrentLocationOnce() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(AppLocalizations.of(context)
            .translate('location_service_disabled'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppLocalizations.of(context)
              .translate('location_permission_denied'));
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _driverCurrentLocation =
              LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting initial driver location: $e');
      }
      rethrow;
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar(
          AppLocalizations.of(context).translate('location_service_disabled'));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar(AppLocalizations.of(context)
            .translate('location_permission_denied'));
        return;
      }
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (mounted) {
        setState(() {
          _driverCurrentLocation =
              LatLng(position.latitude, position.longitude);
          // ✅ إذا كانت الخريطة جاهزة، حرك الكاميرا لتتبع السائق
          if (_isMapReady) {
            _mapController.move(
                _driverCurrentLocation!, _mapController.camera.zoom);
          }
        });
        _sendLocationToServer(position.latitude, position.longitude);
      }
    });
  }

  Future<void> _sendLocationToServer(double latitude, double longitude) async {
    final String driverLocationApiUrl =
        '${dotenv.env['BASE_URL']}/api/drivers/${widget.driverId}/location';

    if (kDebugMode) {
      print(driverLocationApiUrl); // طباعة الـ URL للتأكد
      print(latitude);
      print(longitude);
    }
    try {
      final response = await http.post(
        Uri.parse(driverLocationApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'tripId': widget.tripId,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print(
              'Location sent successfully for driver ${widget.driverId}: $latitude, $longitude');
        }
      } else {
        if (kDebugMode) {
          print(
              'Failed to send location for driver ${widget.driverId}: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error sending location to server for driver ${widget.driverId}: $e');
      }
    }
  }

  // void _startRoadStatusChecker() {
  //   if (_telegramBotToken.isEmpty) return;

  //   _fetchRoadStatusFromTelegram();
  //   _roadStatusTimer =
  //       Timer.periodic(const Duration(minutes: 1), (timer) async {
  //     await _fetchRoadStatusFromTelegram();
  //     if (_driverCurrentLocation != null &&
  //         _currentRoutePoints.isNotEmpty &&
  //         _orsApiKey.isNotEmpty) {
  //       await _getActualRoute();
  //     }
  //   });
  // }

  Future<void> _fetchRoadStatusFromTelegram() async {
    if (_telegramBotToken.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('https://api.telegram.org/bot$_telegramBotToken/getUpdates'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          await _parseRoadStatusMessages(data['result'] as List<dynamic>);
        } else {
          if (kDebugMode) {
            print(
                'Failed to fetch Telegram updates: ${response.statusCode}, ${data['description'] ?? ''}');
          }
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch Telegram updates: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching road status from Telegram: $e');
      }
    }
  }

  Future<void> _parseRoadStatusMessages(List<dynamic> messages) async {
    List<Map<String, dynamic>> tempBlockedRoads = [];

    for (var msg in messages.reversed) {
      try {
        final messageText = msg['message']?['text']?.toString();
        if (messageText == null) continue;

        if (messageText.contains('مسكر') ||
            messageText.contains('مغلق') ||
            messageText.contains('❌') ||
            messageText.contains('اغلاق') ||
            messageText.contains('blocking')) {
          final roadInfo = _extractRoadInfo(messageText);
          if (roadInfo != null) {
            tempBlockedRoads.add(roadInfo);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing message: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _blockedRoads = tempBlockedRoads;
      });
    }
  }

  Map<String, dynamic>? _extractRoadInfo(String text) {
    final roadKeywords = [
      'شارع',
      'طريق',
      'مدخل',
      'مفرق',
      'دوار',
      'تقاطع',
      'street',
      'road',
      'entrance',
      'intersection'
    ];

    String? roadName;
    for (var keyword in roadKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        int keywordIndex = text.toLowerCase().indexOf(keyword);
        String potentialRoadNamePart = text.substring(keywordIndex);
        int endIndex = potentialRoadNamePart.indexOf(RegExp(r'[\s-،.]'));
        if (endIndex != -1) {
          roadName = potentialRoadNamePart.substring(0, endIndex).trim();
        } else {
          roadName = potentialRoadNamePart.trim();
        }
        break;
      }
    }

    if (roadName != null) {
      String? city;
      if (text.contains('نابلس'))
        city = 'نابلس';
      else if (text.contains('رام الله'))
        city = 'رام الله';
      else if (text.contains('الخليل'))
        city = 'الخليل';
      else if (text.contains('بيت لحم'))
        city = 'بيت لحم';
      else if (text.contains('سلفيت'))
        city = 'سلفيت';
      else if (text.contains('طولكرم')) city = 'طولكرم';

      if (city != null) {
        final roadCoordinates = _getRoadCoordinates(roadName, city);
        if (roadCoordinates['startPoint'] != null &&
            roadCoordinates['endPoint'] != null) {
          return {
            'name': roadName,
            'city': city,
            'status': 'مغلق',
            'startPoint': roadCoordinates['startPoint'],
            'endPoint': roadCoordinates['endPoint'],
            'radius': 0.1,
            'roadType': roadCoordinates['roadType']
          };
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _getRoadCoordinates(String roadName, String city) {
    final knownRoads = {
      'نابلس': {
        'شارع بيت وزن': {
          'startPoint': LatLng(32.215, 35.25),
          'endPoint': LatLng(32.225, 35.26),
          'roadType': 'شارع'
        },
        'شارع رفيديا': {
          'startPoint': LatLng(32.22, 35.24),
          'endPoint': LatLng(32.23, 35.25),
          'roadType': 'شارع'
        },
      },
      'سلفيت': {
        'دوار ارائيل': {
          'startPoint': LatLng(32.079, 35.15),
          'endPoint': LatLng(32.081, 35.16),
          'roadType': 'دوار'
        },
        'شارع ديرستيا': {
          'startPoint': LatLng(32.08, 35.155),
          'endPoint': LatLng(32.09, 35.165),
          'roadType': 'شارع'
        },
      },
      'طولكرم': {
        'شارع طولكرم - قلقيلية': {
          'startPoint': LatLng(32.32, 35.03),
          'endPoint': LatLng(32.35, 35.05),
          'roadType': 'شارع'
        },
      },
    };

    if (knownRoads.containsKey(city)) {
      for (var entry in knownRoads[city]!.entries) {
        if (roadName.toLowerCase().contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(roadName.toLowerCase())) {
          return entry.value;
        }
      }
    }
    return _getDefaultCityCoordinates(city);
  }

  Map<String, dynamic> _getDefaultCityCoordinates(String city) {
    switch (city) {
      case 'نابلس':
        return {
          'startPoint': LatLng(32.2218, 35.2544),
          'endPoint': LatLng(32.2318, 35.2644),
          'roadType': 'شارع'
        };
      case 'سلفيت':
        return {
          'startPoint': LatLng(32.0833, 35.1667),
          'endPoint': LatLng(32.0933, 35.1767),
          'roadType': 'شارع'
        };
      case 'رام الله':
        return {
          'startPoint': LatLng(31.90, 35.20),
          'endPoint': LatLng(31.91, 35.21),
          'roadType': 'شارع'
        };
      case 'الخليل':
        return {
          'startPoint': LatLng(31.53, 35.10),
          'endPoint': LatLng(31.54, 35.11),
          'roadType': 'شارع'
        };
      case 'بيت لحم':
        return {
          'startPoint': LatLng(31.70, 35.20),
          'endPoint': LatLng(31.71, 35.21),
          'roadType': 'شارع'
        };
      case 'طولكرم':
        return {
          'startPoint': LatLng(32.31, 35.03),
          'endPoint': LatLng(32.32, 35.04),
          'roadType': 'شارع'
        };
      default:
        return {
          'startPoint': LatLng(32.2218, 35.2544),
          'endPoint': LatLng(32.2318, 35.2644),
          'roadType': 'شارع'
        }; // Nablus fallback
    }
  }

  Future<void> _getActualRoute() async {
    // 1. التحقق من صحة الإحداثيات الأولية
    if (_driverCurrentLocation == null ||
        widget.endLocation.latitude == 0.0 ||
        widget.endLocation.longitude == 0.0) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        _showErrorSnackBar(AppLocalizations.of(context)
            .translate('invalid_destination_coordinates'));
      }
      if (kDebugMode) {
        print(
            'Route calculation skipped: Driver current location or end location is invalid.');
      }
      return;
    }

    // 2. معالجة حالة عدم وجود مفتاح ORS API
    if (_orsApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _currentRoutePoints = [
            _driverCurrentLocation!,
            LatLng(widget.endLocation.latitude, widget.endLocation.longitude)
          ];
          _isLoadingRoute = false;
          // تحريك الكاميرا لتناسب المسار المباشر الجديد
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([
                _driverCurrentLocation!,
                LatLng(
                    widget.endLocation.latitude, widget.endLocation.longitude)
              ]),
              padding: const EdgeInsets.all(50.0),
            ),
          );
        });
      }
      if (kDebugMode) {
        print(
            'Route calculation skipped: ORS API key is missing. Using direct path.');
      }
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _currentRoutePoints = []; // مسح المسار السابق قبل حساب الجديد
    });

    try {
      final start = _driverCurrentLocation!;
      final end =
          LatLng(widget.endLocation.latitude, widget.endLocation.longitude);

      final orsUrl =
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_orsApiKey'
          '&start=${start.longitude},${start.latitude}'
          '&end=${end.longitude},${end.latitude}'
          '&overview=simplified'; // تغيير من full إلى simplified لتقليل البيانات

      if (kDebugMode) {
        print('OpenRouteService URL: $orsUrl');
      }

      final response = await http
          .get(Uri.parse(orsUrl))
          .timeout(const Duration(seconds: 15)); // زيادة مهلة الوقت قليلاً

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 3. التحقق من وجود 'features' وبيانات المسار
        if (data['features'] != null && data['features'].isNotEmpty) {
          // الوصول إلى الإحداثيات الخام كـ List<dynamic>
          final List<dynamic> rawCoords =
              data['features'][0]['geometry']['coordinates'];

          // تحويل كل مجموعة إحداثيات إلى LatLng مع التأكد من النوع double
          final List<LatLng> routePoints = rawCoords.map((coord) {
            // التحقق من أن 'coord' هو قائمة وأن لديه عنصرين على الأقل
            if (coord is List && coord.length >= 2) {
              // التحويل الصريح إلى double
              final double longitude = (coord[0] as num).toDouble();
              final double latitude = (coord[1] as num).toDouble();
              return LatLng(latitude, longitude);
            } else {
              // في حالة وجود بيانات إحداثيات غير متوقعة أو غير مكتملة
              if (kDebugMode) {
                print('Warning: Skipping invalid coordinate format: $coord');
              }
              // يمكن هنا إرجاع نقطة افتراضية أو تخطي النقطة
              return LatLng(0, 0); // نقطة غير صالحة ليتم إزالتها لاحقاً
            }
          }).toList();

          // إزالة أي نقاط 'LatLng(0,0)' التي قد تكون نتجت عن إحداثيات خاطئة
          routePoints.removeWhere((p) => p.latitude == 0 && p.longitude == 0);

          if (mounted) {
            setState(() {
              _currentRoutePoints = routePoints;
              _isLoadingRoute = false;
              // تحريك الكاميرا لتناسب المسار الجديد، فقط إذا كان هناك مسار صالح
              if (_currentRoutePoints.isNotEmpty) {
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(
                        [_driverCurrentLocation!, end, ..._currentRoutePoints]),
                    padding: const EdgeInsets.all(50.0),
                  ),
                );
              }
            });
          }
        } else {
          // لم يتم العثور على ميزات (مسارات) في الرد
          throw Exception(AppLocalizations.of(context)
              .translate('no_routes_found_ors_response'));
        }
      } else {
        // خطأ من خادم OpenRouteService (مثلاً 401, 403, 429, 500)
        String errorMessage = AppLocalizations.of(context)
            .translate('failed_to_get_route_from_ors');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage +=
                ": ${errorData['error']?['message'] ?? errorData['message'] ?? response.body}";
          } catch (_) {
            errorMessage += ": ${response.body}"; // إذا لم يمكن تحليل الـ JSON
          }
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      // 4. معالجة خطأ انتهاء المهلة
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)
            .translate('route_calculation_timeout'));
      }
      if (kDebugMode) {
        print('OpenRouteService request timed out.');
      }
      _fallbackToDirectRoute();
    } catch (e) {
      // 5. معالجة أي أخطاء أخرى غير متوقعة
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)
            .translate('error_calculating_route_using_direct_path'));
      }
      if (kDebugMode) {
        print('An unexpected error occurred while fetching route: $e');
      }
      _fallbackToDirectRoute();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _fallbackToDirectRoute() {
    if (mounted) {
      setState(() {
        if (_driverCurrentLocation != null &&
            widget.endLocation.latitude != 0.0 &&
            widget.endLocation.longitude != 0.0) {
          _currentRoutePoints = [
            _driverCurrentLocation!,
            LatLng(widget.endLocation.latitude, widget.endLocation.longitude)
          ];
          // تحريك الكاميرا لتناسب المسار المباشر الجديد
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([
                _driverCurrentLocation!,
                LatLng(
                    widget.endLocation.latitude, widget.endLocation.longitude)
              ]),
              padding: const EdgeInsets.all(50.0),
            ),
          );
        } else {
          _currentRoutePoints =
              []; // لا يوجد مسار حتى مباشر إذا كانت النقاط غير صالحة
        }
      });
    }
  }

  bool _isRouteBlocked(List<LatLng> routePoints) {
    for (var blockedRoad in _blockedRoads) {
      final blockedStart = blockedRoad['startPoint'] as LatLng;
      final blockedEnd = blockedRoad['endPoint'] as LatLng;
      final radius = (blockedRoad['radius'] as double) * 1000;

      for (int i = 0; i < routePoints.length - 1; i++) {
        final segmentStart = routePoints[i];
        final segmentEnd = routePoints[i + 1];

        double distToBlockedStart = Geolocator.distanceBetween(
            segmentStart.latitude,
            segmentStart.longitude,
            blockedStart.latitude,
            blockedStart.longitude);
        double distToBlockedEnd = Geolocator.distanceBetween(
            segmentStart.latitude,
            segmentStart.longitude,
            blockedEnd.latitude,
            blockedEnd.longitude);

        LatLng segmentMidpoint = LatLng(
            (segmentStart.latitude + segmentEnd.latitude) / 2,
            (segmentStart.longitude + segmentEnd.longitude) / 2);
        double distToBlockedStartMid = Geolocator.distanceBetween(
            segmentMidpoint.latitude,
            segmentMidpoint.longitude,
            blockedStart.latitude,
            blockedStart.longitude);
        double distToBlockedEndMid = Geolocator.distanceBetween(
            segmentMidpoint.latitude,
            segmentMidpoint.longitude,
            blockedEnd.latitude,
            blockedEnd.longitude);

        if (distToBlockedStart < radius ||
            distToBlockedEnd < radius ||
            distToBlockedStartMid < radius ||
            distToBlockedEndMid < radius) {
          if (kDebugMode) {
            print(
                'Route segment close to blocked road: ${blockedRoad['name']}');
          }
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _completeTrip() async {
    setState(() {
      _isCompletingTrip = true;
    });
    try {
      await TripsApi.completeTrip(widget.tripId.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('trip_completed_success')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context).translate(
          'error_completing_trip',
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingTrip = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    LatLng initialCenter = _driverCurrentLocation ??
        LatLng(widget.startLocation.latitude, widget.startLocation.longitude);
    double initialZoom = _driverCurrentLocation != null ? 15.0 : 13.0;

    // ✅ هنا التعديل الرئيسي لمنع الخروج
    return PopScope(
      // استخدم PopScope
      canPop: false, // اجعلها false لمنع الخروج بشكل افتراضي
      onPopInvoked: (bool didPop) {
        // هذه الدالة تُستدعى عندما يحاول المستخدم الخروج
        // إذا كان `didPop` صحيحاً، فهذا يعني أن الخروج قد حدث (نادراً مع canPop: false)
        // إذا كان `didPop` خاطئاً، فهذا يعني أننا منعنا الخروج.
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(local.translate('cannot_exit_trip')), // تحتاج ترجمة
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(local.translate('current_trip')),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          automaticallyImplyLeading: false, // ✅ إزالة زر الرجوع من الـ AppBar
          actions: [
            if (_telegramBotToken.isNotEmpty)
              IconButton(
                icon: const Icon(LucideIcons.info),
                tooltip: local.translate('road_status'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(local.translate('blocked_roads_info')),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_blockedRoads.isEmpty)
                              Text(local.translate('no_blocked_roads'))
                            else
                              ..._blockedRoads.map((road) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                        '• ${road["name"]} - ${road["city"]} (${road["status"]})'),
                                  )),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(local.translate('ok')),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: _isLoadingRoute || _driverCurrentLocation == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(local.translate('calculating_route_and_location')),
                  ],
                ),
              )
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: initialZoom,
                      onMapReady: () {
                        if (mounted && !_isMapReady) {
                          setState(() => _isMapReady = true);
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_orsApiKey.isNotEmpty) {
                              _getActualRoute();
                            }
                          });
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
                      PolylineLayer(
                        polylines: [
                          if (_currentRoutePoints.isNotEmpty)
                            Polyline(
                              points: _currentRoutePoints,
                              color: Colors.blue.withOpacity(0.7),
                              strokeWidth: 4,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _driverCurrentLocation ?? initialCenter,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.directions_car,
                                color: Colors.blue, size: 30),
                          ),
                          Marker(
                            point: LatLng(widget.endLocation.latitude,
                                widget.endLocation.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 30),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      icon: _isCompletingTrip
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.checkCheck),
                      label: Text(
                        _isCompletingTrip
                            ? local.translate('completing_trip')
                            : local.translate('end_trip'),
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isCompletingTrip ? null : _completeTrip,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
