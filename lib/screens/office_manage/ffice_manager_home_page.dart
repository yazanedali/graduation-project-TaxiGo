import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/driver.dart'; // تأكد من صحة المسار
import 'package:taxi_app/services/taxi_office_api.dart'; // تأكد من صحة المسار

class OfficeManagerHomePage extends StatefulWidget {
  final int officeId;
  final String token;

  const OfficeManagerHomePage({
    super.key,
    required this.officeId,
    required this.token,
  });

  @override
  _OfficeManagerHomePageState createState() => _OfficeManagerHomePageState();
}

class _OfficeManagerHomePageState extends State<OfficeManagerHomePage> {
  List<Driver> _activeDrivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _driversCount = 0;
  int _dailyTrips = 0;
  int _dailyEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
  }

  Future<void> _loadOfficeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats =
          await TaxiOfficeApi.getOfficeStats(widget.officeId, widget.token);
      final dailyStats =
          await TaxiOfficeApi.getDailyStats(widget.officeId, widget.token);
      final drivers =
          await TaxiOfficeApi.getOfficeDrivers(widget.officeId, widget.token);

      final activeDrivers =
          drivers.where((driver) => driver.isAvailable).toList();

      if (!mounted) return;
      setState(() {
        _activeDrivers = activeDrivers;
        _driversCount = stats['driversCount'] ?? 0;
        _dailyTrips = dailyStats['dailyTripsCount'] ?? 0;
        _dailyEarnings = dailyStats['dailyEarnings'] ?? 0;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading office data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            AppLocalizations.of(context).translate('error_loading_data');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.refreshCw),
              label: Text(local.translate('retry')),
              onPressed: _loadOfficeData,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOfficeData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  local.translate('welcome_office_manager'),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  local.translate('your_daily_overview'),
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                _buildStatsGrid(context, constraints),
                const SizedBox(height: 32),
                Text(
                  local.translate('active_drivers_now'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildActiveDriversList(context),
              ],
            ),
          );
        },
      ),
    );
  }

  //  ======  التعديل الأول: تعديل GridView ======
  Widget _buildStatsGrid(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    // تحديد عدد الأعمدة ونسبة العرض إلى الارتفاع بناءً على حجم الشاشة
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;
    // إعطاء مساحة أكبر للكروت على الموبايل
    final double childAspectRatio =
        screenWidth < 400 ? 1.4 : (screenWidth < 600 ? 1.6 : 2.5);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          context,
          AppLocalizations.of(context).translate('drivers_count'),
          _driversCount.toString(),
          LucideIcons.users,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          context,
          AppLocalizations.of(context).translate('todayTrips'),
          _dailyTrips.toString(),
          LucideIcons.car,
          Colors.green.shade600,
        ),
        _buildStatCard(
          context,
          AppLocalizations.of(context).translate('today_earnings'),
          '\$${_dailyEarnings.toStringAsFixed(2)}',
          LucideIcons.dollarSign,
          Colors.orange.shade700,
        ),
      ],
    );
  }

  // ======  التعديل الثاني: جعل كرت الإحصائيات مرنًا ======
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    final isVerySmallScreen = MediaQuery.of(context).size.width < 380;

    // التصميم العمودي للشاشات الصغيرة جدًا
    if (isVerySmallScreen) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // التصميم الأفقي للشاشات الأكبر (الوضع الافتراضي)
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // هذا الجزء يبقى كما هو لأنه يعمل بشكل جيد
  Widget _buildActiveDriversList(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    if (_activeDrivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(LucideIcons.userX,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              local.translate('no_active_drivers'),
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeDrivers.length,
      itemBuilder: (context, index) {
        final driver = _activeDrivers[index];
        final status = local.translate('active');

        final double driverEarnings = (driver.earnings).toDouble();
        final tripsText = '\$${driverEarnings.toStringAsFixed(2)}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: driver.profileImageUrl != null
                  ? NetworkImage(driver.profileImageUrl!)
                  : null,
              child: driver.profileImageUrl == null
                  ? Text(
                      driver.fullName.isNotEmpty
                          ? driver.fullName[0].toUpperCase()
                          : 'D',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            title: Text(
              driver.fullName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(LucideIcons.dollarSign,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 4),
                Flexible(
                  // استخدام Flexible لمنع تجاوز النص
                  child: Text(
                    tripsText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(LucideIcons.mapPin, color: theme.colorScheme.primary),
              tooltip: local.translate('show_location'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${local.translate("show_location_for")} ${driver.fullName}')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
