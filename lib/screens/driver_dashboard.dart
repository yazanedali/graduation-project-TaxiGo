import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart'; // Ensure this path is correct
import 'package:taxi_app/screens/Driver/driver_requests.dart';
import 'package:taxi_app/screens/components/NotificationIcon.dart'; // Ensure this path is correct
import 'Driver/driver_home.dart';
import 'Driver/driver_trips.dart';
import 'Driver/earnings.dart';
import 'Driver/driver_settings.dart';
import 'chat.dart'; // Ensure this path is correct

class DriverDashboard extends StatefulWidget {
  final int userId;
  final String token;

  const DriverDashboard({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  String? _fullName;
  bool _isLoading = true;
  bool _accessGranted = false;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _kWebBreakpoint = 800.0;

  late List<String> _pageTitles;

  // Pages that are included in the bottom navigation bar
  final List<int> _bottomNavBarPagesIndices = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _initializePages();
    _verifyAndLoadData();
  }

  void _initializePages() {
    _pages = [
      DriverHomePage(driverId: widget.userId),
      DriverRequestsPage(driverId: widget.userId),
      DriverTripsPage(driverId: widget.userId),
      EarningsPage(driverId: widget.userId),
      DriverSettingsPage(
        driverId: widget.userId,
        onAvailabilityChanged: (bool value) {},
      ),
    ];
  }

  // Helper to get translated page titles
  void _updatePageTitles() {
    final local = AppLocalizations.of(context);
    _pageTitles = [
      local.translate('home'),
      local.translate('trip_requests'),
      local.translate('my_trips'),
      local.translate('earnings'),
      local.translate('settings'),
    ];
  }

  Future<void> _verifyAndLoadData() async {
    // This function remains the same as it handles logic, not UI
    // I'm keeping it here for completeness.
    try {
      final userAccessResponse = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (!mounted) return;
      if (userAccessResponse.statusCode != 200) {
        _handleAccessDenied(
            AppLocalizations.of(context).translate('access_denied_general'));
        return;
      }
      final userData = jsonDecode(userAccessResponse.body);
      final userDetails = userData['user'];
      if (userDetails == null || userDetails['isLoggedIn'] != true) {
        _handleAccessDenied(
            AppLocalizations.of(context).translate('login_required_driver'));
        return;
      }
      final String? userRole = userDetails['role'];
      if (userRole != 'Driver') {
        _handleAccessDenied(AppLocalizations.of(context)
            .translate('access_denied_not_driver'));
        return;
      }
      final driverStatusResponse = await http.get(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/drivers/status/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (driverStatusResponse.statusCode != 200) {
        _handleAccessDenied(AppLocalizations.of(context)
            .translate('driver_details_not_found'));
        return;
      }
      final driverData = jsonDecode(driverStatusResponse.body);
      final bool isAvailable = driverData['isAvailable'] == true;
      if (!isAvailable) {
        _handleAccessDenied(
            AppLocalizations.of(context).translate('driver_not_available'));
        return;
      }
      await _loadDriverData();
      setState(() {
        _accessGranted = true;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error during verification: $e');
      }
      if (mounted) {
        _handleAccessDenied(
            AppLocalizations.of(context).translate('error_verifying_access'));
      }
    }
  }

  Future<void> _loadDriverData() async {
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
      if (kDebugMode) {
        print('Error loading driver data: $e');
      }
    }
  }

  void _handleAccessDenied(String message) {
    if (!mounted) return;
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).translate('access_denied')),
          content: Text(message),
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).translate('verifying_access')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessGranted || _isLoading) {
      return _buildLoadingScreen();
    }
    bool isWeb = MediaQuery.of(context).size.width > 800;
    // Initialize titles here to access context for localization
    _updatePageTitles();

    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > _kWebBreakpoint;
    final local = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
           automaticallyImplyLeading: false,
           leading: !isWeb
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
        // Theming is now handled by app_theme.dart
        elevation: isLargeScreen ? 0 : 4,
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          NotificationIcon(userId: widget.userId),
          const SizedBox(width: 8),
          // MODIFICATION: The settings icon is now visible on both mobile and web.
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: local.translate('settings'),
            onPressed: () => _navigateToPage(4),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isLargeScreen ? null : _buildMobileDrawer(theme, local),
      body: isLargeScreen
          ? Row(
              children: [
                _buildDesktopSidebar(theme, local),
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar:
          isLargeScreen ? null : _buildBottomNavBar(theme, local),
    );
  }

  Widget _buildMobileDrawer(ThemeData theme, AppLocalizations local) {
    return Drawer(
      // The drawer color will now correctly adapt to the theme
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: _buildSidebarHeaderContent(theme),
            ),
            _buildSidebarItem(
                local.translate('home'), LucideIcons.home, 0, theme,
                isDrawer: true),
            _buildSidebarItem(
                local.translate('trip_requests'), LucideIcons.list, 1, theme,
                isDrawer: true),
            _buildSidebarItem(
                local.translate('my_trips'), LucideIcons.car, 2, theme,
                isDrawer: true),
            _buildSidebarItem(
                local.translate('earnings'), LucideIcons.dollarSign, 3, theme,
                isDrawer: true),
            _buildSidebarItem(
                local.translate('settings'), LucideIcons.settings, 4, theme,
                isDrawer: true),
            Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
            _buildChatListItem(theme, local, isDrawer: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(ThemeData theme, AppLocalizations local) {
    return SizedBox(
      width: 280,
      child: Container(
        color: theme.colorScheme.primary, // The main sidebar color
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Center(child: _buildSidebarHeaderContent(theme)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarItem(local.translate('home'), LucideIcons.home, 0, theme),
                  _buildSidebarItem(local.translate('trip_requests'), LucideIcons.list, 1, theme),
                  _buildSidebarItem(local.translate('my_trips'), LucideIcons.car, 2, theme),
                  _buildSidebarItem(local.translate('earnings'), LucideIcons.dollarSign, 3, theme),
                  _buildSidebarItem(local.translate('settings'), LucideIcons.settings, 4, theme),
                  Divider(color: theme.colorScheme.onPrimary.withOpacity(0.2), height: 1),
                  _buildChatListItem(theme, local),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeaderContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.car,
          size: 60,
          color: theme.colorScheme.onPrimary,
        ),
        const SizedBox(height: 10),
        Text(
          "TaxiGo Driver",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_fullName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _fullName!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    int index,
    ThemeData theme, {
    bool isDrawer = false,
  }) {
    final bool isSelected = _selectedIndex == index;

    // Define colors based on whether it's a drawer (light/dark background) or sidebar (primary color background)
    final Color selectedColor = isDrawer ? theme.colorScheme.primary : theme.colorScheme.onPrimary;
    final Color unselectedColor = isDrawer ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary.withOpacity(0.8);
    final Color selectedTextColor = isDrawer ? theme.colorScheme.primary : theme.colorScheme.onPrimary;
    final Color unselectedTextColor = isDrawer ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;
    final Color? selectedBgColor = isDrawer ? theme.colorScheme.primary.withOpacity(0.12) : theme.colorScheme.onPrimary.withOpacity(0.15);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _navigateToPage(index);
          if (isDrawer) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatListItem(ThemeData theme, AppLocalizations local,
      {bool isDrawer = false}) {
    final Color iconColor = isDrawer ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary.withOpacity(0.8);
    final Color textColor = isDrawer ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;
      
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDrawer) Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userId: widget.userId,
                userType: 'Driver',
                token: widget.token,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(LucideIcons.messageSquare, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  local.translate('chat'),
                  style: theme.textTheme.titleMedium?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme, AppLocalizations local) {
    // Finds the index in the bottom bar list. If the page isn't in the bar (like settings), it returns -1.
    final currentBottomNavIndex =
        _bottomNavBarPagesIndices.indexOf(_selectedIndex);

    return BottomNavigationBar(
      // Theming is now handled by BottomNavigationBarThemeData in app_theme.dart
      // If current page is not in the bottom bar, default to index 0 (Home) visually.
      currentIndex: currentBottomNavIndex == -1 ? 0 : currentBottomNavIndex,
      onTap: (index) {
        _navigateToPage(_bottomNavBarPagesIndices[index]);
      },
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.home),
          label: local.translate('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.list),
          label: local.translate('trip_requests'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.car),
          label: local.translate('my_trips'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.dollarSign),
          label: local.translate('earnings'),
        ),
        
      ],
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}