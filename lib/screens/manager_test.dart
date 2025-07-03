// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:taxi_app/language/localization.dart';
// import 'package:taxi_app/screens/Driver/support.dart';
// import 'package:taxi_app/screens/components/NotificationIcon.dart';
// import 'package:taxi_app/screens/chat.dart';

// import 'package:taxi_app/models/taxi_office.dart';
// import 'package:taxi_app/models/driver.dart';
// import 'package:taxi_app/services/taxi_office_api.dart';

// class OfficeManagerHomePage extends StatefulWidget {
//   final int officeId;
//   final String token;

//   const OfficeManagerHomePage({
//     super.key,
//     required this.officeId,
//     required this.token,
//   });

//    @override
//   _OfficeManagerHomePageState createState() => _OfficeManagerHomePageState();
// }

// class _OfficeManagerHomePageState extends State<OfficeManagerHomePage> {
//   late Future<Map<String, dynamic>> _officeData;
//   List<Driver> _activeDrivers = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadOfficeData();
//   }
//  Future<void> _loadOfficeData() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // جلب بيانات المكتب
//       final office = await TaxiOfficeApi.getOfficeDetails(widget.officeId, widget.token);
      
//       // جلب الإحصائيات
//       final stats = await TaxiOfficeApi.getOfficeStats(widget.officeId, widget.token);
//       final dailyStats = await TaxiOfficeApi.getDailyStats(widget.officeId, widget.token);
      
//       // جلب السائقين النشطين
//       final drivers = await TaxiOfficeApi.getOfficeDrivers(widget.officeId, widget.token);
//       final activeDrivers = drivers.where((driver) => driver.isAvailable).toList();
      
//       setState(() {
//         _activeDrivers = activeDrivers;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (kDebugMode) print('Error loading office data: $e');
//       setState(() => _isLoading = false);
//       // يمكنك إضافة معالجة الأخطاء هنا
//     }
//   }
  
//  @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Center(child: CircularProgressIndicator());
//     }

//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             AppLocalizations.of(context).translate('welcome_office_manager'),
//             style: Theme.of(context).textTheme.headlineMedium,
//           ),
//           const SizedBox(height: 20),
//           _buildStatsGrid(context),
//           const SizedBox(height: 30),
//           Text(
//             AppLocalizations.of(context).translate('active_drivers_now'),
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 15),
//           Expanded(
//             child: _buildActiveDriversList(context),
//           ),
//         ],
//       ),
//     );
//   }

//     Widget _buildStatsGrid(BuildContext context) {
//     return FutureBuilder<Map<String, int>>(
//       future: TaxiOfficeApi.getOfficeStats(widget.officeId, widget.token),
//       builder: (context, statsSnapshot) {
//         return FutureBuilder<Map<String, int>>(
//           future: TaxiOfficeApi.getDailyStats(widget.officeId, widget.token),
//           builder: (context, dailyStatsSnapshot) {
//             final driversCount = statsSnapshot.data?['driversCount'] ?? 0;
//             final tripsCount = statsSnapshot.data?['tripsCount'] ?? 0;
//             final dailyTrips = dailyStatsSnapshot.data?['dailyTripsCount'] ?? 0;
//             final dailyEarnings = dailyStatsSnapshot.data?['dailyEarnings'] ?? 0;

//             return GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               childAspectRatio: 2.5,
//               children: [
//                 _buildStatCard(
//                   context,
//                   AppLocalizations.of(context).translate('drivers_count'),
//                   driversCount.toString(),
//                   LucideIcons.users,
//                   Colors.blue,
//                 ),
//                 _buildStatCard(
//                   context,
//                   AppLocalizations.of(context).translate('trips_today'),
//                   dailyTrips.toString(),
//                   LucideIcons.car,
//                   Colors.green,
//                 ),
//                 _buildStatCard(
//                   context,
//                   AppLocalizations.of(context).translate('daily_earnings'),
//                   '$dailyEarnings ر.س',
//                   LucideIcons.dollarSign,
//                   Colors.orange,
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//    Widget _buildStatCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color),
//             ),
//             const SizedBox(width: 15),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(title, style: Theme.of(context).textTheme.bodySmall),
//                 Text(
//                   value,
//                   style: Theme.of(context)
//                       .textTheme
//                       .titleMedium
//                       ?.copyWith(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//    Widget _buildActiveDriversList(BuildContext context) {
//     if (_activeDrivers.isEmpty) {
//       return Center(
//         child: Text(
//           AppLocalizations.of(context).translate('no_active_drivers'),
//           style: Theme.of(context).textTheme.bodyLarge,
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadOfficeData,
//       child: ListView.builder(
//         itemCount: _activeDrivers.length,
//         itemBuilder: (context, index) {
//           final driver = _activeDrivers[index];
//           final status = driver.isAvailable
//               ? AppLocalizations.of(context).translate('status_active')
//               : AppLocalizations.of(context).translate('status_inactive');
          
//           final tripsText = '${driver.driverUserId} ${AppLocalizations.of(context).translate('trips_suffix')}';

//           return Card(
//             margin: const EdgeInsets.only(bottom: 15),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Theme.of(context).colorScheme.secondary,
//                 backgroundImage: driver.profileImageUrl != null
//                     ? NetworkImage(driver.profileImageUrl!)
//                     : null,
//                 child: driver.profileImageUrl == null
//                     ? Icon(Icons.person, 
//                         color: Theme.of(context).colorScheme.onSecondary)
//                     : null,
//               ),
//               title: Text(
//                 driver.fullName,
//                 style: Theme.of(context).textTheme.titleSmall,
//               ),
//               subtitle: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: driver.isAvailable ? Colors.green[100] : Colors.orange[100],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       status,
//                       style: TextStyle(
//                         color: driver.isAvailable ? Colors.green[800] : Colors.orange[800],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     tripsText,
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//               trailing: IconButton(
//                 icon: Icon(
//                   LucideIcons.mapPin,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 onPressed: () {
//                   // TODO: Implement logic to show driver location
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

//   // Moved these helper widgets here so they have direct access to context
//   Widget _buildStatsGrid(BuildContext context) {
//     return GridView.count(
//       shrinkWrap: true,
//       crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
//       crossAxisSpacing: 15,
//       mainAxisSpacing: 15,
//       childAspectRatio: 2.5,
//       children: [
//         _buildStatCard(
//             context,
//             AppLocalizations.of(context).translate('drivers_count'),
//             "25",
//             LucideIcons.users,
//             Colors.blue),
//         _buildStatCard(
//             context,
//             AppLocalizations.of(context).translate('trips_today'),
//             "142",
//             LucideIcons.car,
//             Colors.green),
//         _buildStatCard(
//             context,
//             AppLocalizations.of(context).translate('total_earnings'),
//             "5,420 ر.س",
//             LucideIcons.dollarSign,
//             Colors.orange),
//       ],
//     );
//   }

//   Widget _buildStatCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color),
//             ),
//             const SizedBox(width: 15),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(title, style: Theme.of(context).textTheme.bodySmall),
//                 Text(value,
//                     style: Theme.of(context)
//                         .textTheme
//                         .titleMedium
//                         ?.copyWith(fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActiveDriversList(BuildContext context) {
//     final drivers = [
//       {
//         "name": AppLocalizations.of(context).translate('driver_ahmed'),
//         "status": AppLocalizations.of(context).translate('status_active'),
//         "trips": "8 ${AppLocalizations.of(context).translate('trips_suffix')}"
//       },
//       {
//         "name": AppLocalizations.of(context).translate('driver_khaled'),
//         "status": AppLocalizations.of(context).translate('status_active'),
//         "trips": "12 ${AppLocalizations.of(context).translate('trips_suffix')}"
//       },
//       {
//         "name": AppLocalizations.of(context).translate('driver_samer'),
//         "status": AppLocalizations.of(context).translate('status_on_trip'),
//         "trips": "5 ${AppLocalizations.of(context).translate('trips_suffix')}"
//       },
//       {
//         "name": AppLocalizations.of(context).translate('driver_youssef'),
//         "status": AppLocalizations.of(context).translate('status_active'),
//         "trips": "10 ${AppLocalizations.of(context).translate('trips_suffix')}"
//       },
//     ];

//     return ListView.builder(
//       itemCount: drivers.length,
//       itemBuilder: (context, index) {
//         final driver = drivers[index];
//         bool isActive = driver["status"] ==
//             AppLocalizations.of(context).translate('status_active');
//         return Card(
//           margin: const EdgeInsets.only(bottom: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.secondary,
//               child: Icon(Icons.person,
//                   color: Theme.of(context).colorScheme.onSecondary),
//             ),
//             title: Text(driver["name"]!,
//                 style: Theme.of(context).textTheme.titleSmall),
//             subtitle: Row(
//               children: [
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: isActive ? Colors.green[100] : Colors.orange[100],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(driver["status"]!,
//                       style: TextStyle(
//                           color:
//                               isActive ? Colors.green[800] : Colors.orange[800],
//                           fontSize: 12)),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(driver["trips"]!,
//                     style: Theme.of(context).textTheme.bodySmall),
//               ],
//             ),
//             trailing: IconButton(
//               icon: Icon(LucideIcons.mapPin,
//                   color: Theme.of(context).colorScheme.primary),
//               onPressed: () {
//                 // TODO: Implement logic to show driver location
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }


// // Example placeholders for other manager pages (replace with your actual widgets)
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

// class OfficeManagerSettingsPage extends StatelessWidget {
//   final int officeId;
//   const OfficeManagerSettingsPage({super.key, required this.officeId});
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//           AppLocalizations.of(context).translate('office_settings_content'),
//           style: Theme.of(context).textTheme.headlineMedium),
//     );
//   }
// }

// class OfficeManagerDashboard extends StatefulWidget {
//   final int userId; // Changed from officeId to userId for consistency
//   final String token; // Token is crucial for API calls

//   const OfficeManagerDashboard({
//     super.key,
//     required this.userId,
//     required this.token,
//   });

//   @override
//   _OfficeManagerDashboardState createState() => _OfficeManagerDashboardState();
// }

// class _OfficeManagerDashboardState extends State<OfficeManagerDashboard> {
//   int _selectedIndex = 0;
//   List<Widget>? _pages; // Made nullable, will be initialized in build
//   String? _officeName;
//   String? _managerName;
//   bool _isLoading = true;
//   bool _accessGranted = false;
//   bool _isSidebarExpanded = true;

//   static const double _kWebBreakpoint = 800.0;
//   static const double _kTabletBreakpoint = 600.0;

//   // List of page titles for AppBar and sidebar
//   late List<String> _pageTitles;

//   @override
//   void initState() {
//     super.initState();
//     _verifyAndLoadData();
//   }

//   // This method will now be called within build() after context is ready
//   void _initializePagesAndTitles(BuildContext context) {
//     if (_pages != null) return; // Only initialize once

//     _pages = [
//       OfficeManagerHomePage(officeId: widget.userId, token: '',), // Home/Dashboard
//       OfficeDriversManagementPage(officeId: widget.userId), // Manage Drivers
//       // OfficeRidersManagementPage(officeId: widget.userId), // Example for other pages
//       // OfficeTripsOverviewPage(officeId: widget.userId),
//       // OfficeReportsPage(officeId: widget.userId),
//       SupportPage(), // General Support (could be specific for office manager)
//       OfficeManagerSettingsPage(officeId: widget.userId), // Settings
//     ];

//     _pageTitles = [
//       AppLocalizations.of(context).translate('office_dashboard_home'),
//       AppLocalizations.of(context).translate('manage_office_drivers'),
//       // AppLocalizations.of(context).translate('manage_office_riders'),
//       // AppLocalizations.of(context).translate('office_trips_overview'),
//       // AppLocalizations.of(context).translate('office_reports'),
//       AppLocalizations.of(context).translate('office_support'),
//       AppLocalizations.of(context).translate('office_settings'),
//     ];
//   }

//   Future<void> _verifyAndLoadData() async {
//     try {
//       // Access verification
//       final accessResponse = await http.get(
//         Uri.parse('${dotenv.env['BASE_URL']}/api/users/${widget.userId}'),
//         headers: {
//           'Authorization': 'Bearer ${widget.token}',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (!mounted) return;

//       if (accessResponse.statusCode != 200) {
//         _handleAccessDenied();
//         return;
//       }

//       final userData = jsonDecode(accessResponse.body);
//       // Check if user exists and is logged in
//       if (userData['user'] == null || userData['user']?['isLoggedIn'] != true) {
//         _handleAccessDenied();
//         return;
//       }

//       // Fetch driver data if verification is successful
//       await _loadOfficeManagerData();

//       setState(() {
//         _accessGranted = true;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error during verification: $e');
//       }
//       _handleAccessDenied();
//     }
//   }

//   Future<void> _loadOfficeManagerData() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             '${dotenv.env['BASE_URL']}/api/office-managers/details/${widget.userId}'), // Adjust endpoint
//         headers: {'Authorization': 'Bearer ${widget.token}'},
//       );

//       if (response.statusCode == 200 && mounted) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _officeName = data['officeName']; // Adjust keys
//           _managerName = data['managerName']; // Adjust keys
//         });
//       } else {
//         if (kDebugMode) {
//           print(
//               'Failed to load office manager details: ${response.statusCode}');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading office manager data: $e');
//       }
//     }
//   }

//   void _handleAccessDenied() {
//     if (!mounted) return;

//     Future.delayed(Duration.zero, () {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           title: Text(AppLocalizations.of(context).translate('access_denied')),
//           content: Text(AppLocalizations.of(context)
//               .translate('login_required_office_manager')),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.of(context).popUntil((route) => route.isFirst);
//               },
//               child: Text(AppLocalizations.of(context).translate('ok')),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildLoadingScreen(ThemeData theme, AppLocalizations local) {
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               strokeWidth: 4,
//               valueColor:
//                   AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
//               backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               local.translate('loading_office_manager_data'),
//               style: TextStyle(
//                 fontSize: 18,
//                 color: theme.colorScheme.onSurface.withOpacity(0.7),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               local.translate('please_wait'),
//               style: TextStyle(
//                 fontSize: 14,
//                 color: theme.colorScheme.onSurface.withOpacity(0.5),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final local = AppLocalizations.of(context);

//     // Initialize pages and titles here, where context is guaranteed to be available
//     _initializePagesAndTitles(context);

//     if (!_accessGranted || _isLoading || _pages == null) {
//       return _buildLoadingScreen(theme, local);
//     }

//     final isLargeScreen = MediaQuery.of(context).size.width > _kWebBreakpoint;
//     final isTablet = MediaQuery.of(context).size.width > _kTabletBreakpoint &&
//         !isLargeScreen;

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         elevation: isLargeScreen ? 0 : 4,
//         title: Text(
//           _pageTitles[_selectedIndex], // Dynamic title based on selected page
//           style: theme.textTheme.titleLarge?.copyWith(
//             color: theme.colorScheme.onPrimary,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           NotificationIcon(
//             userId: widget.userId,
//           ),
//           const SizedBox(width: 8),
//           if (isLargeScreen) // Settings icon only on web app bar
//             IconButton(
//               icon: Icon(LucideIcons.settings,
//                   color: theme.colorScheme.onPrimary),
//               tooltip: local.translate('office_settings'),
//               onPressed: () =>
//                   _navigateToPage(_pages!.length - 1), // Last page is settings
//             ),
//           const SizedBox(width: 8),
//         ],
//         iconTheme: IconThemeData(
//             color: theme.colorScheme.onPrimary), // For Drawer icon
//       ),
//       drawer: isLargeScreen ? null : _buildMobileSidebar(theme, local),
//       body: isLargeScreen
//           ? Row(
//               children: [
//                 _buildDesktopSidebar(theme, local),
//                 Expanded(
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 300),
//                     transitionBuilder: (child, animation) {
//                       return FadeTransition(opacity: animation, child: child);
//                     },
//                     child: _pages![
//                         _selectedIndex], // Use _pages! as it's guaranteed to be initialized
//                   ),
//                 ),
//               ],
//             )
//           : _pages![_selectedIndex], // Use _pages!
//       bottomNavigationBar:
//           isLargeScreen || isTablet ? null : _buildBottomNavBar(theme, local),
//     );
//   }

//   Widget _buildMobileSidebar(ThemeData theme, AppLocalizations local) {
//     return Drawer(
//       backgroundColor:
//           theme.colorScheme.background, // Lighter background for drawer
//       child: SafeArea(
//         child: Column(
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primary,
//               ),
//               child: _buildSidebarHeaderContent(theme, local),
//             ),
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   _buildSidebarItem(local.translate('office_dashboard_home'),
//                       LucideIcons.layoutDashboard, 0, theme,
//                       isDrawer: true),
//                   _buildSidebarItem(local.translate('manage_office_drivers'),
//                       LucideIcons.users, 1, theme,
//                       isDrawer: true),
//                   // _buildSidebarItem(local.translate('manage_office_riders'), LucideIcons.user, 2, theme, isDrawer: true),
//                   // _buildSidebarItem(local.translate('office_trips_overview'), LucideIcons.route, 3, theme, isDrawer: true),
//                   // _buildSidebarItem(local.translate('office_reports'), LucideIcons.clipboardList, 4, theme, isDrawer: true),
//                   _buildSidebarItem(local.translate('office_support'),
//                       LucideIcons.lifeBuoy, _pages!.length - 2, theme,
//                       isDrawer: true), // Example: Support is second to last
//                   _buildSidebarItem(local.translate('office_settings'),
//                       LucideIcons.settings, _pages!.length - 1, theme,
//                       isDrawer: true), // Example: Settings is last
//                   Divider(
//                       color: theme.dividerColor.withOpacity(0.5), height: 1),
//                   _buildChatListItem(theme, local, isDrawer: true),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 local.translate('office_manager_system_version'),
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.onPrimary.withOpacity(0.6),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDesktopSidebar(ThemeData theme, AppLocalizations local) {
//     return AnimatedContainer(
//       width:
//           _isSidebarExpanded ? 280 : 70, // Adjust width for expanded/collapsed
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       child: Container(
//         decoration: BoxDecoration(
//           color: theme.colorScheme.primary,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 15,
//               offset: const Offset(3, 0),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             _buildSidebarHeaderContent(theme, local, isDesktop: true),
//             // Toggle button for sidebar expansion
//             IconButton(
//               icon: Icon(
//                 _isSidebarExpanded
//                     ? LucideIcons.chevronLeft
//                     : LucideIcons.chevronRight,
//                 color: theme.colorScheme.onPrimary,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _isSidebarExpanded = !_isSidebarExpanded;
//                 });
//               },
//               tooltip: _isSidebarExpanded
//                   ? local.translate('collapse_sidebar')
//                   : local.translate('expand_sidebar'),
//             ),
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   _buildCollapsibleSidebarItem(
//                       local.translate('office_dashboard_home'),
//                       LucideIcons.layoutDashboard,
//                       0,
//                       theme),
//                   _buildCollapsibleSidebarItem(
//                       local.translate('manage_office_drivers'),
//                       LucideIcons.users,
//                       1,
//                       theme),
//                   // _buildCollapsibleSidebarItem(local.translate('manage_office_riders'), LucideIcons.user, 2, theme),
//                   // _buildCollapsibleSidebarItem(local.translate('office_trips_overview'), LucideIcons.route, 3, theme),
//                   // _buildCollapsibleSidebarItem(local.translate('office_reports'), LucideIcons.clipboardList, 4, theme),
//                   _buildCollapsibleSidebarItem(
//                       local.translate('office_support'),
//                       LucideIcons.lifeBuoy,
//                       _pages!.length - 2,
//                       theme),
//                   _buildCollapsibleSidebarItem(
//                       local.translate('office_settings'),
//                       LucideIcons.settings,
//                       _pages!.length - 1,
//                       theme),
//                   Divider(
//                       color: theme.colorScheme.onPrimary.withOpacity(0.2),
//                       height: 1),
//                   _buildCollapsibleChatListItem(theme, local),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: _isSidebarExpanded
//                   ? Text(
//                       local.translate('office_manager_system_version'),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onPrimary.withOpacity(0.6),
//                       ),
//                       textAlign: TextAlign.center,
//                     )
//                   : Icon(LucideIcons.info,
//                       size: 20,
//                       color: theme.colorScheme.onPrimary
//                           .withOpacity(0.6)), // Small icon when collapsed
//             ),
//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSidebarHeaderContent(ThemeData theme, AppLocalizations local,
//       {bool isDesktop = false}) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           width: _isSidebarExpanded || !isDesktop
//               ? 80
//               : 40, // Smaller for collapsed
//           height: _isSidebarExpanded || !isDesktop ? 80 : 40,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: theme.colorScheme.onPrimary.withOpacity(0.1),
//             border: Border.all(
//               color: theme.colorScheme.onPrimary.withOpacity(0.3),
//               width: 2,
//             ),
//           ),
//           child: Icon(
//             LucideIcons.building,
//             size: _isSidebarExpanded || !isDesktop
//                 ? 40
//                 : 20, // Smaller for collapsed
//             color: theme.colorScheme.onPrimary,
//           ),
//         ),
//         const SizedBox(height: 10),
//         if (_isSidebarExpanded || !isDesktop) // Hide text when collapsed
//           Text(
//             local.translate('office_manager'),
//             style: theme.textTheme.headlineSmall?.copyWith(
//               color: theme.colorScheme.onPrimary,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         if (_isSidebarExpanded || !isDesktop)
//           if (_managerName != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4.0),
//               child: Text(
//                 _managerName!,
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.colorScheme.onPrimary.withOpacity(0.8),
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//         if (_isSidebarExpanded || !isDesktop) const SizedBox(height: 10),
//         if (_isSidebarExpanded || !isDesktop)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               local.translate('level_manager'),
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: Colors.blue,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         const SizedBox(height: 10),
//         if (isDesktop) // Only show divider for desktop sidebar header
//           Divider(
//             color: theme.colorScheme.onPrimary.withOpacity(0.2),
//             thickness: 1,
//             indent: _isSidebarExpanded ? 20 : 0, // Adjust indent for collapsed
//             endIndent: _isSidebarExpanded ? 20 : 0,
//           ),
//       ],
//     );
//   }

//   Widget _buildSidebarItem(
//     String title,
//     IconData icon,
//     int index,
//     ThemeData theme, {
//     bool isDrawer = false,
//   }) {
//     final bool isSelected = _selectedIndex == index;
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () {
//           setState(() => _selectedIndex = index);
//           if (isDrawer) {
//             Navigator.of(context).pop(); // Close the drawer on item tap
//           }
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//           decoration: BoxDecoration(
//             color: isSelected
//                 ? theme.colorScheme.secondary.withOpacity(0.2)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(10),
//             border: isSelected
//                 ? Border.all(
//                     color: theme.colorScheme.secondary.withOpacity(0.4),
//                     width: 1)
//                 : null,
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 icon,
//                 color: isSelected
//                     ? theme.colorScheme.secondary
//                     : theme.colorScheme.onPrimary.withOpacity(0.8),
//                 size: 24,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: isSelected
//                         ? theme.colorScheme.secondary
//                         : theme.colorScheme.onPrimary,
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCollapsibleSidebarItem(
//     String title,
//     IconData icon,
//     int index,
//     ThemeData theme,
//   ) {
//     final bool isSelected = _selectedIndex == index;
//     return Tooltip(
//       message:
//           _isSidebarExpanded ? '' : title, // Only show tooltip when collapsed
//       preferBelow: false,
//       verticalOffset: 10,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => setState(() => _selectedIndex = index),
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? theme.colorScheme.secondary.withOpacity(0.2)
//                   : Colors.transparent,
//               borderRadius: BorderRadius.circular(10),
//               border: isSelected
//                   ? Border.all(
//                       color: theme.colorScheme.secondary.withOpacity(0.4),
//                       width: 1)
//                   : null,
//             ),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal:
//                     _isSidebarExpanded ? 16 : 0, // Adjust padding for collapsed
//                 vertical: 12,
//               ),
//               child: Row(
//                 mainAxisAlignment: _isSidebarExpanded
//                     ? MainAxisAlignment.start
//                     : MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     icon,
//                     color: isSelected
//                         ? theme.colorScheme.secondary
//                         : theme.colorScheme.onPrimary.withOpacity(0.8),
//                     size: 24,
//                   ),
//                   if (_isSidebarExpanded) ...[
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Text(
//                         title,
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: isSelected
//                               ? theme.colorScheme.secondary
//                               : theme.colorScheme.onPrimary,
//                           fontWeight:
//                               isSelected ? FontWeight.bold : FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChatListItem(ThemeData theme, AppLocalizations local,
//       {bool isDrawer = false}) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () {
//           if (isDrawer) {
//             Navigator.of(context).pop();
//           }
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ChatScreen(
//                 userId: widget.userId.toString(),
//                 userType: 'office_manager',
//               ),
//             ),
//           );
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//           decoration: BoxDecoration(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Row(
//             children: [
//               Icon(LucideIcons.messageSquare,
//                   color: theme.colorScheme.onPrimary.withOpacity(0.8),
//                   size: 24),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   local.translate('office_manager_chat'),
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: theme.colorScheme.onPrimary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCollapsibleChatListItem(
//       ThemeData theme, AppLocalizations local) {
//     return Tooltip(
//       message: _isSidebarExpanded ? '' : local.translate('office_manager_chat'),
//       preferBelow: false,
//       verticalOffset: 10,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => ChatScreen(
//                   userId: widget.userId.toString(),
//                   userType: 'office_manager',
//                 ),
//               ),
//             );
//           },
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.transparent,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: _isSidebarExpanded ? 16 : 0,
//                 vertical: 12,
//               ),
//               child: Row(
//                 mainAxisAlignment: _isSidebarExpanded
//                     ? MainAxisAlignment.start
//                     : MainAxisAlignment.center,
//                 children: [
//                   Icon(LucideIcons.messageSquare,
//                       color: theme.colorScheme.onPrimary.withOpacity(0.8),
//                       size: 24),
//                   if (_isSidebarExpanded) ...[
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Text(
//                         local.translate('office_manager_chat'),
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.colorScheme.onPrimary,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNavBar(ThemeData theme, AppLocalizations local) {
//     // Indices for bottom navigation bar items (subset of all pages)
//     final List<int> bottomNavPageIndices = [
//       0,
//       1,
//       _pages!.length - 1
//     ]; // Home, Drivers, Settings

//     final currentBottomNavIndex = bottomNavPageIndices.indexOf(_selectedIndex);

//     return Container(
//       decoration: BoxDecoration(
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         child: BottomNavigationBar(
//           currentIndex: currentBottomNavIndex == -1 ? 0 : currentBottomNavIndex,
//           onTap: (index) =>
//               setState(() => _selectedIndex = bottomNavPageIndices[index]),
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: theme.colorScheme.primary,
//           selectedItemColor: theme.colorScheme.onPrimary,
//           unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.6),
//           selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//           unselectedLabelStyle: theme.textTheme.labelSmall,
//           showSelectedLabels: true,
//           showUnselectedLabels: true,
//           items: [
//             _buildNavBarItem(LucideIcons.layoutDashboard,
//                 local.translate('office_dashboard_home')),
//             _buildNavBarItem(
//                 LucideIcons.users, local.translate('manage_office_drivers')),
//             _buildNavBarItem(
//                 LucideIcons.settings, local.translate('office_settings')),
//           ],
//         ),
//       ),
//     );
//   }

//   BottomNavigationBarItem _buildNavBarItem(IconData icon, String label) {
//     return BottomNavigationBarItem(
//       icon: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Icon(icon, size: 24),
//       ),
//       label: label,
//     );
//   }

//   void _navigateToPage(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
// }
