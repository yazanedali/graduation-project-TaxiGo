import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/screens/components/NotificationIcon.dart';
import 'package:taxi_app/screens/chat.dart';

// استيراد صفحات مدير المكتب
import 'package:taxi_app/screens/office_manage/ffice_manager_home_page.dart';
import 'package:taxi_app/screens/office_manage/office_drivers_management_page.dart';
import 'package:taxi_app/screens/office_manage/office_manager_settings_page.dart';

class OfficeManagerDashboard extends StatefulWidget {
  final int userId;
  final String token;

  const OfficeManagerDashboard({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  _OfficeManagerDashboardState createState() => _OfficeManagerDashboardState();
}

class _OfficeManagerDashboardState extends State<OfficeManagerDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<String> _pageTitles;
  String? _managerName;
  bool _isLoading = true;
  bool _accessGranted = false;
  bool _isSidebarExpanded = true;

  static const double _kWebBreakpoint = 800.0;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _verifyAndLoadData();
  }

  void _initializePages() {
    _pages = [
      OfficeManagerHomePage(
          officeId: widget.userId, token: widget.token), // index 0
      OfficeDriversManagementPage(
          officeId: widget.userId, token: widget.token), // index 1
      OfficeManagerSettingsPage(
          userId: widget.userId, token: widget.token), // index 2
    ];
  }

  void _updatePageTitles(BuildContext context) {
    final local = AppLocalizations.of(context);
    _pageTitles = [
      local.translate('office_dashboard_home'), // index 0
      local.translate('manage_office_drivers'), // index 1
      local.translate('office_settings'), // index 2
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
      final userDetails = userData['user'];


      if (userDetails == null || userDetails['isLoggedIn'] != true || userDetails['role'] != 'Manager') {
        _handleAccessDenied();
        return;
      }

      // Load manager name for display
      setState(() {
        _managerName = userDetails['fullName'];
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
          content: Text(AppLocalizations.of(context)
              .translate('login_required_office_manager')),
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
    final local = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(local.translate('loading_office_manager_data')),
            const SizedBox(height: 8),
            Text(local.translate('please_wait')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updatePageTitles(context); // Update titles whenever build runs

    if (!_accessGranted || _isLoading) {
      return _buildLoadingScreen(context);
    }

    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > _kWebBreakpoint;

    return Scaffold(
      key: _scaffoldKey, // أضف هذا السطر
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.primary,
        leading: !isLargeScreen
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          NotificationIcon(userId: widget.userId),
          const SizedBox(width: 8),
          if (isLargeScreen)
            IconButton(
              icon: const Icon(LucideIcons.settings),
              tooltip: local.translate('office_settings'),
              onPressed: () => _navigateToPage(_pages.length - 1),
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
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: _buildSidebarHeaderContent(theme, local),
            ),
            _buildSidebarItem(local.translate('office_dashboard_home'),
                LucideIcons.layoutDashboard, 0, theme,
                isDrawer: true),
            _buildSidebarItem(local.translate('manage_office_drivers'),
                LucideIcons.users, 1, theme,
                isDrawer: true),
            _buildSidebarItem(local.translate('office_settings'),
                LucideIcons.settings, 2, theme,
                isDrawer: true),
            Divider(color: theme.dividerColor, height: 1),
            _buildChatListItem(theme, local, isDrawer: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(ThemeData theme, AppLocalizations local) {
    return AnimatedContainer(
      width: _isSidebarExpanded ? 280 : 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      color: theme.colorScheme.primary,
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildSidebarHeaderContent(theme, local, isDesktop: true),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(local.translate('office_dashboard_home'),
                    LucideIcons.layoutDashboard, 0, theme),
                _buildSidebarItem(local.translate('manage_office_drivers'),
                    LucideIcons.users, 1, theme),
                _buildSidebarItem(local.translate('office_settings'),
                    LucideIcons.settings, 2, theme),
                Divider(
                    color: theme.colorScheme.onPrimary.withOpacity(0.2),
                    height: 1),
                _buildChatListItem(theme, local),
              ],
            ),
          ),
          IconButton(
              icon: Icon(
                  _isSidebarExpanded
                      ? LucideIcons.chevronLeft
                      : LucideIcons.chevronRight,
                  color: theme.colorScheme.onPrimary),
              onPressed: () =>
                  setState(() => _isSidebarExpanded = !_isSidebarExpanded)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSidebarHeaderContent(ThemeData theme, AppLocalizations local,
      {bool isDesktop = false}) {
    bool showText = !isDesktop || _isSidebarExpanded;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.building,
            size: showText ? 50 : 30, color: theme.colorScheme.onPrimary),
        if (showText) const SizedBox(height: 12),
        if (showText)
          Text(
            local.translate('office_manager'),
            style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold),
          ),
        if (showText && _managerName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _managerName!,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarItem(
      String title, IconData icon, int index, ThemeData theme,
      {bool isDrawer = false}) {
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
      message: _isSidebarExpanded || isDrawer ? '' : title,
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

  Widget _buildChatListItem(ThemeData theme, AppLocalizations local,
      {bool isDrawer = false}) {
    final Color color = isDrawer
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimary.withOpacity(0.7);

    return Tooltip(
      message: _isSidebarExpanded || isDrawer
          ? ''
          : local.translate('office_manager_chat'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                        userId: widget.userId,
                        userType: 'Manager',
                        token: widget.token)));
          },
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: isDrawer ? 12 : 8, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: !_isSidebarExpanded && !isDrawer
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(LucideIcons.messageSquare, color: color),
                if (_isSidebarExpanded || isDrawer) ...[
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(local.translate('office_manager_chat'),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: color))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme, AppLocalizations local) {
    // Pages to show in the bottom bar: Home, Drivers, Settings
    final List<int> bottomNavPageIndices = [0, 1, 2];
    final currentBottomNavIndex = bottomNavPageIndices.indexOf(_selectedIndex);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentBottomNavIndex == -1 ? 0 : currentBottomNavIndex,
          onTap: (index) => _navigateToPage(bottomNavPageIndices[index]),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(LucideIcons.layoutDashboard),
                label: local.translate('office_dashboard_home')),
            BottomNavigationBarItem(
                icon: const Icon(LucideIcons.users),
                label: local.translate('manage_office_drivers')),
            BottomNavigationBarItem(
                icon: const Icon(LucideIcons.settings),
                label: local.translate('office_settings')),
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
}
