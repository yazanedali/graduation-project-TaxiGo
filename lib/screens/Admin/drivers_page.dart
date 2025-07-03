import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/driver.dart';
import 'package:taxi_app/services/drivers_api.dart';
import '../../services/driver_detail_page.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  _DriversPageState createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  List<Driver> drivers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final driversList = await DriversApi.getAllDrivers();
      setState(() {
        drivers = driversList.map((driver) {
          return Driver(
            id: driver.id, // MongoDB ID أو driverId
            driverUserId: driver.driverUserId,
            fullName: driver.fullName,
            profileImageUrl: driver.profileImageUrl,
            isAvailable: driver.isAvailable,
            carModel: driver.carModel, // Provide default or fetched value
            carColor: driver.carColor, // Provide default or fetched value
            carPlateNumber:
                driver.carPlateNumber, // Provide default or fetched value
            rating: driver.rating, // Provide default or fetched value
            numberOfRatings:
                driver.numberOfRatings, // Provide default or fetched value
            phone: driver.phone, // Provide default or fetched value
            email: driver.email, // Provide default or fetched value
            earnings: driver.earnings,
            taxiOfficeId: driver.taxiOfficeId,
            licenseNumber: driver.licenseNumber,
            licenseExpiry: driver.licenseExpiry,
            joinedAt: driver.joinedAt,

            // Provide default or fetched value
          );
        }).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleDriverStatus(Driver driver) async {
    final newStatus = !driver.isAvailable;

    try {
      // تحديث الحالة في الواجهة أولاً
      setState(() {
        driver.isAvailable = newStatus;
        // يمكنك إضافة أي تحديثات أخرى هنا إذا لزم الأمر
      });

      // إرسال التحديث إلى الخادم
      await DriversApi.updateDriverAvailability(driver.driverUserId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'تم تفعيل السائق ${driver.fullName}'
              : 'تم إيقاف السائق ${driver.fullName}'),
        ),
      );
    } catch (e) {
      // في حالة الخطأ، نرجع الحالة كما كانت
      setState(() {
        driver.isAvailable = !newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحديث حالة السائق: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
  
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.translate('drivers_list'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : drivers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.userX,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(local.translate('no_drivers_found')),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadDrivers,
                                child: Text(local.translate('retry')),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDrivers,
                          child: ListView.builder(
                            itemCount: drivers.length,
                            itemBuilder: (context, index) {
                              final driver = drivers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DriverDetailPageWeb(driver: driver),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          child: Icon(LucideIcons.user),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                driver.fullName,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(driver.rating
                                                      .toStringAsFixed(1)),
                                                  const SizedBox(width: 16),
                                                  Icon(
                                                    LucideIcons.dollarSign,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      '${driver.earnings.toStringAsFixed(2)} ${local.translate('trips')}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: driver.isAvailable,
                                          onChanged: (value) =>
                                              _toggleDriverStatus(driver),
                                          activeColor: Colors.green,
                                          inactiveThumbColor: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
