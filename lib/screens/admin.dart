import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/screens/Admin/dashboard_home.dart';
import 'package:taxi_app/screens/Admin/drivers_page.dart';
import 'package:taxi_app/screens/Admin/payments_management.dart';
import 'package:taxi_app/screens/Admin/settings_page.dart';
import 'package:taxi_app/screens/Admin/taxi_offices_page.dart';
import 'package:taxi_app/screens/Admin/trips_management.dart';
import 'package:taxi_app/screens/Admin/users_page.dart';

class AdminDashboard extends StatefulWidget {
  final int userId;
  final String token;

  const AdminDashboard({super.key, required this.userId, required this.token});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<String> _pageTitles;
  String? _fullName;
  bool _isLoading = true;
  bool _accessGranted = false;
  bool _isSidebarExpanded = true;

  // تعريف الصفحات التي ستظهر في الشريط السفلي على الموبايل
  final List<int> _bottomNavIndices = [
    0,
    1,
    2,
    5
  ]; // Home, Drivers, Users, Settings

  @override
  void initState() {
    super.initState();
    _initializePages();
    _verifyAndLoadData();
  }

  void _initializePages() {
    _pages = [
      const DashboardHome(),
      const DriversPage(),
      const UsersPage(),
      const DriverTripsPage(), // تم تغيير اسم الصفحة للاسم الصحيح
      const PaymentsManagementPage(),
      SettingsPage(userId: widget.userId, token: widget.token),
      TaxiOfficesPage(token: widget.token), // تم تمرير التوكن الصحيح
    ];
  }

  void _updatePageTitles(BuildContext context) {
    final local = AppLocalizations.of(context);
    _pageTitles = [
      local.translate('home'),
      local.translate('drivers'),
      local.translate('users'),
      local.translate('trips_management'),
      local.translate('payments_management'),
      local.translate('settings'),
      local.translate('taxi_offices'),
    ];
  }

  Future<void> _verifyAndLoadData() async {
    try {
      final accessResponse = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/users/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (!mounted) return;

      if (accessResponse.statusCode != 200) {
        _handleAccessDenied();
        return;
      }

      final userData = jsonDecode(accessResponse.body);
      final user = userData['user'];
      if (user?['role'] != 'Admin' || user?['isLoggedIn'] != true) {
        _handleAccessDenied();
        return;
      }

      setState(() {
        _fullName = user['fullName'];
        _accessGranted = true;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error during verification: $e');
      _handleAccessDenied();
    }
  }

  void _handleAccessDenied() {
    if (!mounted) return;
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).translate('access_denied')),
          content:
              Text(AppLocalizations.of(context).translate('no_permission')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(AppLocalizations.of(context).translate('ok')),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).translate('verifying_access')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updatePageTitles(context);

    if (!_accessGranted || _isLoading) {
      return _buildLoadingScreen(context);
    }

    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isWeb ? null : _buildMobileAppBar(theme),
      drawer: isWeb ? null : _buildMobileDrawer(theme),
      body: Row(
        children: [
          if (isWeb) _buildDesktopSidebar(theme),
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _pages[_selectedIndex],
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWeb ? null : _buildMobileBottomNav(theme),
    );
  }

  AppBar _buildMobileAppBar(ThemeData theme) {
    return AppBar(
      title: Text(_pageTitles[_selectedIndex]),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings),
          onPressed: () => _navigateToPage(8), // Navigate to settings page
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileDrawer(ThemeData theme) {
    return Drawer(
      child: _buildSidebarContent(theme, isDrawer: true),
    );
  }

  Widget _buildDesktopSidebar(ThemeData theme) {
    return AnimatedContainer(
      width: _isSidebarExpanded ? 260 : 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      color: theme.colorScheme.primary,
      child: _buildSidebarContent(theme, isDrawer: false),
    );
  }

  Widget _buildSidebarContent(ThemeData theme, {required bool isDrawer}) {
    final local = AppLocalizations.of(context);
    final sidebarItems = [
      _buildSidebarItem(local.translate('home'), LucideIcons.layoutDashboard, 0,
          theme, isDrawer),
      _buildSidebarItem(local.translate('drivers'), LucideIcons.userCheck, 1,
          theme, isDrawer),
      _buildSidebarItem(
          local.translate('users'), LucideIcons.users, 2, theme, isDrawer),
      _buildSidebarItem(local.translate('trips_management'), LucideIcons.router,
          3, theme, isDrawer),
      _buildSidebarItem(local.translate('payments_management'),
          LucideIcons.dollarSign, 4, theme, isDrawer),
      _buildSidebarItem(local.translate('settings'), LucideIcons.settings, 5,
          theme, isDrawer), // أضف الإعدادات هنا
      _buildSidebarItem(local.translate('taxi_offices'), LucideIcons.building,
          6, theme, isDrawer),
    ];

    return Column(
      children: [
        isDrawer ? _buildDrawerHeader(theme) : const SizedBox(height: 20),
        if (!isDrawer) _buildSidebarHeader(theme),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: sidebarItems,
          ),
        ),
        if (!isDrawer)
          IconButton(
            icon: Icon(
                _isSidebarExpanded
                    ? LucideIcons.chevronLeft
                    : LucideIcons.chevronRight,
                color: theme.colorScheme.onPrimary),
            onPressed: () =>
                setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSidebarHeader(ThemeData theme) {
    final showText = _isSidebarExpanded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Icon(LucideIcons.shield,
              size: showText ? 50 : 30, color: theme.colorScheme.onPrimary),
          if (showText) const SizedBox(height: 12),
          if (showText)
            Text("Admin Panel",
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
          if (showText && _fullName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(_fullName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8))),
            ),
        ],
      ),
    );
  }

  DrawerHeader _buildDrawerHeader(ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shield,
              size: 50, color: theme.colorScheme.onPrimary),
          const SizedBox(height: 12),
          Text("Admin Panel",
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
          if (_fullName != null)
            Text(_fullName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      String title, IconData icon, int index, ThemeData theme, bool isDrawer) {
    final bool isSelected = _selectedIndex == index;
    final Color selectedColor =
        isDrawer ? theme.colorScheme.primary : theme.colorScheme.onPrimary;
    final Color unselectedColor = isDrawer
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimary.withOpacity(0.7);
    final Color? selectedBgColor = isDrawer
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.onPrimary.withOpacity(0.15);

    return Tooltip(
      message: !_isSidebarExpanded && !isDrawer ? title : '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToPage(index);
            if (isDrawer) Navigator.of(context).pop();
          },
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: isDrawer ? 12 : 8, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: !_isSidebarExpanded && !isDrawer
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, color: isSelected ? selectedColor : unselectedColor),
                if (_isSidebarExpanded || isDrawer) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: isSelected ? selectedColor : unselectedColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav(ThemeData theme) {
    final currentBottomNavIndex = _bottomNavIndices.indexOf(_selectedIndex);

    return BottomNavigationBar(
      currentIndex: currentBottomNavIndex == -1 ? 0 : currentBottomNavIndex,
      onTap: (index) => _navigateToPage(_bottomNavIndices[index]),
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(LucideIcons.layoutDashboard),
            label: _pageTitles[0]),
        BottomNavigationBarItem(
            icon: const Icon(LucideIcons.userCheck), label: _pageTitles[1]),
        BottomNavigationBarItem(
            icon: const Icon(LucideIcons.users), label: _pageTitles[2]),
        BottomNavigationBarItem(
            icon: const Icon(LucideIcons.settings), label: _pageTitles[5]),
      ],
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
