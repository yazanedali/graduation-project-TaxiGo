import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:taxi_app/language/localization.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  LocationData? currentLocation;
  LatLng? destination;
  List<Marker> markers = [];
  List<List<LatLng>> routes = [];
  final String orsApiKey =
      '5b3ce3597851110001cf62485bf8e58a124640b1bc61ce2b4825433e';
  final String botToken = '7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ';
  Timer? _roadStatusTimer;

  // قائمة الطرق المغلقة من التلجرام
  List<Map<String, dynamic>> blockedRoads = [];

  // مناطق الطرق المغلقة (نقاط البداية والنهاية لكل طريق)
  List<Map<String, dynamic>> blockedRoadAreas = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startRoadStatusChecker();
  }

  @override
  void dispose() {
    _roadStatusTimer?.cancel();
    super.dispose();
  }

  // بدء فحص حالة الطرق من التلجرام
  void _startRoadStatusChecker() {
    _roadStatusTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await _fetchRoadStatusFromTelegram();
    });
    _fetchRoadStatusFromTelegram();
  }

  // الحصول على الموقع الحالي
  Future<void> _getCurrentLocation() async {
    var location = Location();
    try {
      var userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(userLocation.latitude!, userLocation.longitude!),
            child:
                const Icon(Icons.my_location, color: Colors.blue, size: 40.0),
          ),
        );
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // جلب حالة الطرق من التلجرام
  Future<void> _fetchRoadStatusFromTelegram() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.telegram.org/bot$botToken/getUpdates'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          await _parseRoadStatusMessages(data['result'] as List<dynamic>);
        }
      }
    } catch (e) {
      print('Error fetching road status: $e');
    }
  }

  // تحليل رسائل التلجرام
  Future<void> _parseRoadStatusMessages(List<dynamic> messages) async {
    List<Map<String, dynamic>> tempBlockedRoads = [];

    for (var msg in messages) {
      try {
        if (msg['message']?['text'] == null) continue;

        final text = msg['message']['text'].toString();
        if (text.contains('مسكر') ||
            text.contains('مغلق') ||
            text.contains('❌')) {
          // استخراج معلومات الطريق
          final roadInfo = _extractRoadInfo(text);
          if (roadInfo != null) {
            tempBlockedRoads.add(roadInfo);
          }
        }
      } catch (e) {
        print('Error parsing message: $e');
      }
    }

    setState(() {
      blockedRoads = tempBlockedRoads;
      // تحديث مناطق الطرق المغلقة
      _updateBlockedRoadAreas();
    });
  }

  // استخراج معلومات الطريق من النص
  Map<String, dynamic>? _extractRoadInfo(String text) {
    try {
      // قائمة الكلمات المفتاحية للطرق
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

      // البحث عن اسم الطريق
      String? roadName;
      for (var keyword in roadKeywords) {
        if (text.toLowerCase().contains(keyword)) {
          final parts = text.split(RegExp(r'[:|-]'));
          if (parts.isNotEmpty) {
            roadName = parts[0].trim();
            break;
          }
        }
      }

      if (roadName != null) {
        // تحديد المدينة
        String? city;
        if (text.contains('نابلس'))
          city = 'نابلس';
        else if (text.contains('رام الله'))
          city = 'رام الله';
        else if (text.contains('الخليل'))
          city = 'الخليل';
        else if (text.contains('بيت لحم'))
          city = 'بيت لحم';
        else if (text.contains('سلفيت')) city = 'سلفيت';

        if (city != null) {
          return {
            'name': roadName,
            'city': city,
            'status': 'مغلق',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      }
    } catch (e) {
      print('Error extracting road info: $e');
    }
    return null;
  }

  // تحديث مناطق الطرق المغلقة
  void _updateBlockedRoadAreas() {
    blockedRoadAreas = blockedRoads.map((road) {
      // تحديد نقاط الطريق المغلق بناءً على المدينة والطريق
      Map<String, dynamic> roadPoints =
          _getRoadCoordinates(road['name'], road['city']);

      return {
        'road': road,
        'startPoint': roadPoints['startPoint'],
        'endPoint': roadPoints['endPoint'],
        'radius': 0.1, // تقليل نصف القطر ليكون أكثر دقة
        'name': road['name'],
        'city': road['city'],
        'roadType': roadPoints['roadType'], // نوع الطريق (شارع، دوار، الخ)
      };
    }).toList();
  }

  // الحصول على إحداثيات الطرق المعروفة
  Map<String, dynamic> _getRoadCoordinates(String roadName, String city) {
    // قائمة الطرق المعروفة مع إحداثياتها
    final knownRoads = {
      'نابلس': {
        'شارع بيت وزن': {
          'startPoint': LatLng(32.2218, 35.2544),
          'endPoint': LatLng(32.2318, 35.2644),
          'roadType': 'شارع'
        },
        'شارع رفيديا': {
          'startPoint': LatLng(32.2250, 35.2600),
          'endPoint': LatLng(32.2350, 35.2700),
          'roadType': 'شارع'
        },
      },
      'سلفيت': {
        'دوار ارائيل': {
          'startPoint': LatLng(32.0833, 35.1667),
          'endPoint': LatLng(32.0933, 35.1767),
          'roadType': 'دوار'
        },
        'شارع ديرستيا': {
          'startPoint': LatLng(32.0800, 35.1600),
          'endPoint': LatLng(32.0900, 35.1700),
          'roadType': 'شارع'
        },
      },
      'طولكرم': {
        'Kafr Sur - Hajja': {
          'startPoint': LatLng(32.2730, 35.0700), // إحداثيات تقريبية
          'endPoint': LatLng(32.2500, 35.1000), // إحداثيات تقريبية
          'roadType': 'شارع'
        },
      },
    };

    // البحث عن الطريق في القائمة (مطابقة جزئية وغير حساسة لحالة الأحرف)
    if (knownRoads.containsKey(city)) {
      for (var entry in knownRoads[city]!.entries) {
        // مطابقة جزئية وغير حساسة لحالة الأحرف
        if (roadName.toLowerCase().contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(roadName.toLowerCase())) {
          return entry.value;
        }
      }
    }

    // إذا لم يتم العثور على الطريق، نستخدم إحداثيات افتراضية للمدينة
    return _getDefaultCityCoordinates(city);
  }

  // الحصول على إحداثيات افتراضية للمدينة
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
      // يمكن إضافة المزيد من المدن هنا
      default:
        return {
          'startPoint': LatLng(32.2218, 35.2544),
          'endPoint': LatLng(32.2318, 35.2644),
          'roadType': 'شارع'
        };
    }
  }

  // البحث عن المكان
  Future<void> _searchLocation(String placeName) async {
    if (placeName.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$placeName&format=json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          setState(() {
            destination = LatLng(lat, lon);
            markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: destination!,
                child: const Icon(Icons.location_on,
                    color: Colors.red, size: 40.0),
              ),
            );
            mapController.move(destination!, 15.0);
          });
          await _getAlternativeRoute();
        }
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  // التحقق مما إذا كان المسار يمر عبر طرق مغلقة
  bool _isRouteBlocked(List<LatLng> routePoints) {
    for (var blockedArea in blockedRoadAreas) {
      // التحقق من أن المسار يمر عبر المدينة التي فيها الطريق المغلق
      bool isInBlockedCity = false;
      for (var point in routePoints) {
        if (_isPointInCity(point, blockedArea['city'] as String)) {
          isInBlockedCity = true;
          break;
        }
      }

      if (isInBlockedCity) {
        // التحقق من المسافة بين المسار والطريق المغلق
        for (var point in routePoints) {
          final distance = _calculateDistance(
            point,
            blockedArea['startPoint'] as LatLng,
            blockedArea['endPoint'] as LatLng,
          );

          // إذا كانت النقطة قريبة من الطريق المغلق
          if (distance < (blockedArea['radius'] as double)) {
            print(
                'تم تجنب الطريق: ${blockedArea['name']} (${blockedArea['roadType']}) في ${blockedArea['city']}');
            return true;
          }
        }
      }
    }
    return false;
  }

  // التحقق مما إذا كانت النقطة تقع في مدينة معينة
  bool _isPointInCity(LatLng point, String city) {
    // حدود تقريبية للمدن
    switch (city) {
      case 'نابلس':
        return point.latitude >= 32.21 &&
            point.latitude <= 32.24 &&
            point.longitude >= 35.25 &&
            point.longitude <= 35.27;
      case 'رام الله':
        return point.latitude >= 31.89 &&
            point.latitude <= 31.92 &&
            point.longitude >= 35.19 &&
            point.longitude <= 35.22;
      case 'الخليل':
        return point.latitude >= 31.52 &&
            point.latitude <= 31.55 &&
            point.longitude >= 35.09 &&
            point.longitude <= 35.12;
      case 'بيت لحم':
        return point.latitude >= 31.69 &&
            point.latitude <= 31.72 &&
            point.longitude >= 35.19 &&
            point.longitude <= 35.22;
      case 'سلفيت':
        return point.latitude >= 32.07 &&
            point.latitude <= 32.10 &&
            point.longitude >= 35.15 &&
            point.longitude <= 35.18;
      default:
        return false;
    }
  }

  // حساب المسافة بين نقطة وخط (الطريق)
  double _calculateDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final Distance distance = Distance();

    // حساب المسافة من النقطة إلى أقرب نقطة على الخط
    final double d1 = distance.as(LengthUnit.Kilometer, point, lineStart);
    final double d2 = distance.as(LengthUnit.Kilometer, point, lineEnd);
    final double lineLength =
        distance.as(LengthUnit.Kilometer, lineStart, lineEnd);

    // حساب المسافة العمودية من النقطة إلى الخط
    final double s = (d1 + d2 + lineLength) / 2;
    final double area = sqrt(s * (s - d1) * (s - d2) * (s - lineLength));
    final double height = (2 * area) / lineLength;

    return height;
  }

  // الحصول على مسار بديل يتجنب الطرق المغلقة
  Future<void> _getAlternativeRoute() async {
    if (currentLocation == null || destination == null) return;

    try {
      final start =
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

      // محاولة الحصول على مسار مع تجنب الطرق المغلقة
      final response = await http.get(
        Uri.parse(
            'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey'
            '&start=${start.longitude},${start.latitude}'
            '&end=${destination!.longitude},${destination!.latitude}'
            '&overview=full&alternatives=true&preference=recommended'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          final List<dynamic> routesData = data['features'];
          List<List<LatLng>> validRoutes = [];

          for (var routeData in routesData) {
            final List<dynamic> coords = routeData['geometry']['coordinates'];
            final List<LatLng> routePoints =
                coords.map((coord) => LatLng(coord[1], coord[0])).toList();

            // التحقق من أن المسار لا يمر عبر طرق مغلقة
            if (!_isRouteBlocked(routePoints)) {
              validRoutes.add(routePoints);
            }
          }

          if (validRoutes.isNotEmpty) {
            setState(() {
              routes = validRoutes;
            });
          } else {
            // إذا لم يتم العثور على مسار، نحاول الحصول على مسار أطول يتجنب الطرق المغلقة
            final alternativeResponse = await http.get(
              Uri.parse(
                  'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey'
                  '&start=${start.longitude},${start.latitude}'
                  '&end=${destination!.longitude},${destination!.latitude}'
                  '&overview=full&alternatives=true&preference=fastest'),
            );

            if (alternativeResponse.statusCode == 200) {
              final altData = json.decode(alternativeResponse.body);
              if (altData['features'].isNotEmpty) {
                final List<dynamic> altRoutesData = altData['features'];
                for (var routeData in altRoutesData) {
                  final List<dynamic> coords =
                      routeData['geometry']['coordinates'];
                  final List<LatLng> routePoints = coords
                      .map((coord) => LatLng(coord[1], coord[0]))
                      .toList();
                  if (!_isRouteBlocked(routePoints)) {
                    validRoutes.add(routePoints);
                  }
                }
                if (validRoutes.isNotEmpty) {
                  setState(() {
                    routes = validRoutes;
                  });
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context); // للترجمة

    // للتحكم في استجابة الـ AppBar على الويب/الموبايل (ليس ضروريًا هنا لكن جيد للمستقبل)
    // final bool isWeb = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      appBar: AppBar(
        // جماليات الـ AppBar
        backgroundColor: theme.colorScheme.primary, // لون متناسق مع الثيم
        elevation: 8.0, // ظل بارز
        shadowColor: theme.colorScheme.shadow.withOpacity(0.5), // لون الظل

        title: Text(
          localizations.translate('map_title'), // ترجمة العنوان
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // زر معلومات الطرق المغلقة
          IconButton(
            tooltip: localizations.translate('info_icon_tooltip'), // تلميح للزر
            icon: Icon(
              Icons.info_outline,
              color: theme.colorScheme.onPrimary, // لون متناسق
              size: 28, // حجم أكبر قليلاً للأيقونة
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  // تصميم الـ AlertDialog ليكون أجمل وواضح
                  backgroundColor:
                      theme.colorScheme.surface, // لون خلفية متناسق
                  surfaceTintColor:
                      Colors.transparent, // منع إضافة tint في Material 3
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // حواف دائرية أنيقة
                  ),
                  title: Text(
                    localizations
                        .translate('closed_roads_title'), // ترجمة عنوان الحوار
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // توسيط العنوان
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (blockedRoads.isEmpty)
                          Text(
                            localizations
                                .translate('no_blocked_roads'), // ترجمة
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          // عرض الطرق المغلقة بشكل أفضل
                          ...blockedRoads.map((road) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.block,
                                        color: theme.colorScheme.error,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${road["name"]} - ${road["city"]}',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  actionsAlignment:
                      MainAxisAlignment.center, // توسيط زر الإجراءات
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localizations.translate('ok_button'), // ترجمة زر حسناً
                        style: TextStyle(
                          color: theme.colorScheme.primary, // لون زر الإجراءات
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8), // مسافة على اليمين
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // زيادة الهامش قليلاً
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: localizations
                          .translate('search_hint'), // ترجمة الـ hint
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant
                          .withOpacity(0.3), // لون خلفية للحقل
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15.0), // حواف دائرية
                        borderSide: BorderSide.none, // إزالة الحدود الافتراضية
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2.0), // حدود عند التركيز
                      ),
                      suffixIcon: Icon(Icons.search,
                          color: theme
                              .colorScheme.primary), // أيقونة بحث بلون الثيم
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15), // مسافة داخلية
                    ),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurface),
                    onSubmitted: (query) =>
                        _searchLocation(query), // البحث عند الضغط على Enter
                  ),
                ),
                // تم دمج زر البحث مع الـ suffixIcon في TextField ليكون الشكل أوضح وأسهل
                // إذا كنت تفضل الزر الخارجي، يمكنك إعادته، لكن الـ suffixIcon أفضل للمستخدم.
                /* IconButton(
                  icon: Icon(Icons.search, color: theme.colorScheme.primary, size: 30),
                  onPressed: () => _searchLocation(searchController.text),
                ), */
              ],
            ),
          ),
          Expanded(
            child: currentLocation == null
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary, // لون متناسق
                    ),
                  )
                : FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(markers: markers),
                      PolylineLayer<LatLng>(polylines: [
                        for (var route in routes)
                          Polyline<LatLng>(
                            points: route,
                            strokeWidth: 4.0,
                            color: Colors.blue
                                .withOpacity(0.7), // لون بولي لاين أوضح
                          ),
                      ]),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: localizations.translate('my_location_tooltip'), // تلميح للزر
        backgroundColor:
            theme.colorScheme.secondary, // لون مختلف قليلاً ليكون بارزاً
        onPressed: () {
          if (currentLocation != null) {
            mapController.move(
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              15.0,
            );
          }
        },
        child: Icon(Icons.my_location,
            color: theme.colorScheme.onSecondary), // لون أيقونة متناسق
      ),
    );
  }
}
