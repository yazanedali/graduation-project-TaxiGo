// import 'package:flutter/material.dart';
// import 'package:taxi_app/language/localization.dart'; // مسار صحيح

// class OfficeDriversManagementPage extends StatelessWidget {
//   final int officeId;
//   const OfficeDriversManagementPage({super.key, required this.officeId});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//           AppLocalizations.of(context)
//               .translate('office_drivers_management_content'),
//           style: Theme.of(context).textTheme.headlineMedium),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/driver.dart';
import 'package:taxi_app/services/drivers_api.dart';
import 'package:taxi_app/services/taxi_office_api.dart';
import 'package:taxi_app/widgets/add_driver_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/driver_detail_page.dart';

class OfficeDriversManagementPage extends StatefulWidget {
  final int officeId;
  final String token;

  const OfficeDriversManagementPage(
      {super.key, required this.officeId, required this.token});

  @override
  _OfficeManagerPageState createState() => _OfficeManagerPageState();
}

class _OfficeManagerPageState extends State<OfficeDriversManagementPage> {
  List<Driver> drivers = [];
  String searchQuery = "";
  String selectedFilter = "الكل";
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final driversList =
          await TaxiOfficeApi.getOfficeDrivers(widget.officeId, widget.token);
      setState(() {
        drivers = driversList;
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

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDriverDialog(
        officeId: widget.officeId,
        token: widget.token,
        onDriverAdded: _loadDrivers, // سيتم استدعاء _loadDrivers بعد الإضافة
      ),
    );
  }

  Future<void> _toggleDriverStatus(Driver driver) async {
    print('Toggling status for driver: ${driver.driverUserId}');
    final newStatus = !driver.isAvailable;
    print('Toggling status for ${driver.fullName} to $newStatus');

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

  List<Driver> getFilteredDrivers() {
    return drivers.where((driver) {
      bool matchesSearch =
          driver.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              driver.phone.contains(searchQuery);
      bool matchesFilter = selectedFilter == "الكل" ||
          (driver.isAvailable ? "نشط" : "غير متصل") == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _callDriver(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final filteredDrivers = getFilteredDrivers();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
   
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: local.translate('search_driver'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["الكل", "نشط", "غير متصل"].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedFilter = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredDrivers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_car, size: 50),
                              const SizedBox(height: 16),
                              Text(local.translate('no_drivers_found')),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return _buildMobileList(
                                  filteredDrivers, theme, local);
                            } else {
                              return _buildDesktopTable(
                                  filteredDrivers, theme, local);
                            }
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddDriverDialog,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'إضافة سائق جديد',
        child: const Icon(Icons.add, size: 18),
      ),
    );
  }

  Widget _buildMobileList(
      List<Driver> drivers, ThemeData theme, AppLocalizations local) {
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(driver.fullName.substring(0, 1)),
            ),
            title: Text(driver.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${local.translate('phone')}: ${driver.phone}"),
                Text(
                    "${local.translate('status')}: ${driver.isAvailable ? local.translate('active') : local.translate('inactive')}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _callDriver(driver.phone),
                ),
                Switch(
                  value: driver.isAvailable,
                  onChanged: (value) => _toggleDriverStatus(driver),
                  activeColor: Colors.green,
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverDetailPageWeb(driver: driver),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
      List<Driver> drivers, ThemeData theme, AppLocalizations local) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(local.translate('name'))),
          DataColumn(label: Text(local.translate('phone'))),
          DataColumn(label: Text(local.translate('status'))),
          DataColumn(label: Text(local.translate('details'))),
          DataColumn(label: Text(local.translate('call'))),
          DataColumn(label: Text(local.translate('status_change'))),
        ],
        rows: drivers.map((driver) {
          return DataRow(
            cells: [
              DataCell(Text(driver.fullName)),
              DataCell(Text(driver.phone)),
              DataCell(
                Chip(
                  label: Text(
                    driver.isAvailable
                        ? local.translate('active')
                        : local.translate('inactive'),
                    style: TextStyle(
                      color: driver.isAvailable ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor:
                      driver.isAvailable ? Colors.green : Colors.grey[300],
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverDetailPageWeb(driver: driver),
                    ),
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _callDriver(driver.phone),
                ),
              ),
              DataCell(
                Switch(
                  value: driver.isAvailable,
                  onChanged: (value) => _toggleDriverStatus(driver),
                  activeColor: Colors.green,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
