import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/screens/User/drivers_list_page.dart';
import 'package:taxi_app/screens/User/scheduled_trips_page.dart';
import 'package:taxi_app/screens/components/NotificationIcon.dart';
import 'User/user_home.dart';
import 'User/mytrip.dart';
import 'User/offers_page.dart';
import 'User/settings_page.dart';
import 'User/support_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserDashboard extends StatefulWidget {
  final int userId;
  final String token;

  const UserDashboard({super.key, required this.userId, required this.token});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late List<Widget> _pages;
  String? _fullName;
  bool _isLoading = true;
  bool _accessGranted = false;

  @override
  void initState() {
    super.initState();
    _pages = _initializePages();
    _verifyAndLoadData();
  }

  List<Widget> _initializePages() {
    return [
      HomePage(userId: widget.userId),
      ScheduledTripsPage(userId: widget.userId), // الصفحة الجديدة
      ClientTripsPage(userId: widget.userId),
      const DriversListPage(),
      SettingsPage(userId: widget.userId, token: widget.token),
      const SupportPage(),
      const OffersPage(),
    ];
  }

  Future<void> _verifyAndLoadData() async {
    try {
      // التحقق من صلاحية المستخدم
      final accessResponse = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (accessResponse.statusCode != 200) {
        _handleAccessDenied();
        return;
      }

      final userData = jsonDecode(accessResponse.body);
      if (userData['user']?['isLoggedIn'] != true) {
        _handleAccessDenied();
        return;
      }

      // جلب بيانات المستخدم إذا التحقق ناجح
      await _loadUserData();

      setState(() {
        _accessGranted = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during verification: $e');
      _handleAccessDenied();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/users/fullname/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _fullName = jsonDecode(response.body)['fullName'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _handleAccessDenied() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('access_denied')),
        content: Text(AppLocalizations.of(context).translate('no_permission')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الـ AlertDialog
              Navigator.of(context).popUntil(
                  (route) => route.isFirst); // العودة إلى الشاشة الأولى
            },
            child: Text(AppLocalizations.of(context).translate('ok')),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).translate('verifying_access'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessGranted || _isLoading) {
      return _buildLoadingScreen();
    }

    var theme = Theme.of(context);
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey, // أضف هذا السطر هنا
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.primary,
        leading: !isWeb
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('user_dashboard'),
              style: TextStyle(
                fontSize: kIsWeb ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (isWeb) ...[
            NotificationIcon(userId: widget.userId),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _navigateToPage(3),
            ),
          ] else ...[
            NotificationIcon(userId: widget.userId),
            const SizedBox(width: 8),
          ],
        ],
      ),
      drawer: isWeb ? null : Drawer(child: _buildSidebarContent(theme)),
      body: Row(
        children: [
          if (isWeb) _buildSidebarContent(theme),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWeb
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _navigateToPage,
              selectedItemColor: theme.colorScheme.onPrimary,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
              backgroundColor: theme.colorScheme.primary,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.home),
                    label: AppLocalizations.of(context).translate('home')),
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.settings),
                    label: AppLocalizations.of(context)
                        .translate('new_scheduled_ride')),
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.history),
                    label: AppLocalizations.of(context)
                        .translate('trips_history')),
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.list),
                    label:
                        AppLocalizations.of(context).translate('drivers_list')),
                // BottomNavigationBarItem(
                //     icon: Icon(LucideIcons.creditCard),
                //     label: AppLocalizations.of(context)
                //         .translate('payment_methods')),
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.settings),
                    label: AppLocalizations.of(context).translate('settings')),
                BottomNavigationBarItem(
                    icon: Icon(LucideIcons.helpCircle),
                    label: AppLocalizations.of(context).translate('support')),
              ],
            ),
    );
  }

  Widget _buildSidebarContent(ThemeData theme) {
    return Container(
      width: 250,
      color: theme.colorScheme.primary,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(LucideIcons.car, size: 60, color: theme.colorScheme.onPrimary),
          const SizedBox(height: 10),
          Text("TaxiGo User",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary)),
          if (_fullName != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _fullName!,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          Divider(color: theme.colorScheme.onPrimary),
          _buildSidebarItem(AppLocalizations.of(context).translate('home'),
              LucideIcons.home, 0, theme),
          _buildSidebarItem(
              AppLocalizations.of(context).translate('new_scheduled_ride'),
              LucideIcons.history,
              1,
              theme),
          _buildSidebarItem(
              AppLocalizations.of(context).translate('trips_history'),
              LucideIcons.history,
              2,
              theme),
          _buildSidebarItem(
              AppLocalizations.of(context).translate('drivers_list'),
              LucideIcons.list,
              3,
              theme),
          // _buildSidebarItem(
          //     AppLocalizations.of(context).translate('payment_methods'),
          //     LucideIcons.creditCard,
          //     3,
          //     theme),
          _buildSidebarItem(AppLocalizations.of(context).translate('settings'),
              LucideIcons.settings, 4, theme),
          _buildSidebarItem(AppLocalizations.of(context).translate('support'),
              LucideIcons.helpCircle, 5, theme),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      String title, IconData icon, int index, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onPrimary),
      title: Text(title, style: TextStyle(color: theme.colorScheme.onPrimary)),
      selected: _selectedIndex == index,
      onTap: () => _navigateToPage(index),
    );
  }
}
