import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/taxi_office.dart';
import 'package:taxi_app/services/api_office.dart';
import 'package:taxi_app/widgets/office_marker.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicTaxiOfficesMap extends StatefulWidget {
  const PublicTaxiOfficesMap({Key? key}) : super(key: key);

  @override
  _PublicTaxiOfficesMapState createState() => _PublicTaxiOfficesMapState();
}

class _PublicTaxiOfficesMapState extends State<PublicTaxiOfficesMap> {
  final MapController _mapController = MapController();
  List<TaxiOffice> _offices = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOffices();
  }

  Future<void> _fetchOffices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _offices = []; // مسح البيانات القديمة عند التحديث
    });

    try {
      final response = await ApiService.getPublic(
        endpoint: '/api/admin/offices',
      );

      // print('Raw API Response: $response'); // للتصحيح فقط

      if (response['data'] is List) {
        setState(() {
          _offices = (response['data'] as List)
              .map((officeJson) {
                // print('Office before parsing: $officeJson'); // للتصحيح
                return TaxiOffice.fromJson(officeJson);
              })
              .where((office) =>
                  office.location.latitude != 0.0 && // التأكد من إحداثيات صحيحة
                  office.location.longitude != 0.0)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Invalid response format from API.";
        });
      }
    } catch (e) {
      print('Error fetching offices: $e'); // طباعة الخطأ الكامل
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString(); // رسالة الخطأ
      });
    }
  }

  void _showOfficeDetails(TaxiOffice office) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // مهم للمحتوى الطويل
      backgroundColor: theme.colorScheme.surface, // لون خلفية متناسق مع الثيم
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.0)), // حواف دائرية أنيقة
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // زيادة الهامش لراحة العين
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان تفاصيل المكتب
              Center(
                child: Text(
                  localizations.translate('office_details_title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 25, thickness: 1), // فاصل أنيق
              Text(
                office.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary, // اسم المكتب بلون بارز
                ),
              ),
              const SizedBox(height: 12),
              // معلومات المكتب
              _buildInfoItem(
                localizations.translate('address_label'),
                office.location.address,
                Icons.location_on,
              ),
              _buildInfoItem(
                localizations.translate('phone_label'),
                office.contact.phone,
                Icons.phone,
              ),
              if (office.workingHours != null &&
                  office.workingHours!.getFormattedHours().isNotEmpty)
                _buildInfoItem(
                  localizations.translate('working_hours_label'),
                  office.workingHours!.getFormattedHours(),
                  Icons.access_time,
                )
              else
                _buildInfoItem(
                  localizations.translate('working_hours_label'),
                  localizations.translate('office_info_not_available'), // ترجمة
                  Icons.access_time,
                ),
              const SizedBox(height: 20),
              // زر الاتصال
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri phoneUri =
                        Uri(scheme: 'tel', path: office.contact.phone);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations
                              .translate('could_not_launch_phone')),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: Text(localizations.translate('call_office_button')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary, // لون زر الاتصال
                    foregroundColor:
                        theme.colorScheme.onPrimary, // لون نص الأيقونة
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5, // ظل للزر
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء عنصر معلومات واحد (العنوان، الهاتف، ساعات العمل)
  Widget _buildInfoItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context); // للترجمة

    // إذا كانت القيمة فارغة أو null، اعرض "غير متوفر"
    final displayValue = value.isEmpty
        ? localizations.translate('office_info_not_available')
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: theme.colorScheme.secondary, size: 24), // أيقونة بلون مميز
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        theme.colorScheme.onSurfaceVariant, // لون لـ "العنوان:"
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface, // لون للقيمة
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context); // للترجمة

    return Scaffold(
      appBar: AppBar(
        // جماليات الـ AppBar
        backgroundColor: theme.colorScheme.primary, // لون متناسق مع الثيم
        elevation: 8.0, // ظل بارز
        shadowColor: theme.colorScheme.shadow.withOpacity(0.5), // لون الظل

        title: Text(
          localizations.translate('taxi_offices_title'), // ترجمة العنوان
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // زر التحديث
          IconButton(
            tooltip:
                localizations.translate('refresh_button_tooltip'), // تلميح للزر
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onPrimary, // لون متناسق
              size: 28, // حجم أكبر قليلاً للأيقونة
            ),
            onPressed: _fetchOffices,
          ),
          const SizedBox(width: 8), // مسافة على اليمين
        ],
      ),
      body: Stack(
        children: [
          // عرض الخريطة فقط إذا لم يكن هناك تحميل أو خطأ
          if (!_isLoading && !_hasError && _offices.isNotEmpty)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                    31.9464, 35.3028), // إحداثيات رام الله كمنطقة افتراضية
                initialZoom: 8.5,
                // عند النقر على الخريطة (فارغ)، يمكنك إغلاق أي modal مفتوح
                onTap: (tapPosition, latLng) {
                  // If a modal sheet was open, this would be a good place to close it
                  // if you had a global key or state to track it.
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.taxi_app',
                ),
                MarkerLayer(
                  markers: _offices
                      .map((office) => Marker(
                            point: office.getLatLng(), // استخدام الدالة الجديدة
                            width: 80, // حجم الماركر ليكون أوضح
                            height: 80,
                            child: GestureDetector(
                              onTap: () => _showOfficeDetails(office),
                              child: OfficeMarker(
                                  office: office), // الـ widget الخاص بالماركر
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),

          // شاشات التحميل، الخطأ، أو لا توجد مكاتب
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('loading_offices'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('error_fetching_offices'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!, // يمكنك إخفاء هذا من المستخدم النهائي
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _fetchOffices,
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.translate('retry_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_offices.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.taxi_alert,
                      color: theme.colorScheme.onSurfaceVariant, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('no_offices_found'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _fetchOffices,
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.translate('retry_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
