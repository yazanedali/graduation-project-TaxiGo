import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool isLoading = true;
  int todayTrips = 0;
  int availableDrivers = 0;
  int newUsers = 0;
  double revenueToday = 0.0;
  List<int> weeklyTrips = [0, 0, 0, 0, 0, 0, 0];
  double activeDriversPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/dashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          todayTrips = data['todayTrips'] ?? 0;
          availableDrivers = data['availableDrivers'] ?? 0;
          newUsers = data['newUsers'] ?? 0;
          revenueToday = (data['revenueToday'] as num?)?.toDouble() ?? 0.0;
          weeklyTrips =
              List<int>.from(data['weeklyTrips'] ?? [0, 0, 0, 0, 0, 0, 0]);
          activeDriversPercentage =
              (data['activeDriversPercentage'] as num?)?.toDouble() ?? 0.0;
          isLoading = false;
        });
      }
    } catch (e) {
      // يمكنك إضافة معالجة الأخطاء هنا
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(local.translate('dashboard'),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStatCard(local.translate('todayTrips'),
                            "$todayTrips", LucideIcons.map),
                        _buildStatCard(local.translate('availableDrivers'),
                            "$availableDrivers", LucideIcons.userCheck),
                        _buildStatCard(local.translate('newUsers'), "$newUsers",
                            LucideIcons.users),
                        _buildStatCard(
                            local.translate('revenueToday'),
                            "\$${revenueToday.toStringAsFixed(2)}",
                            LucideIcons.dollarSign),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(local),
                    const SizedBox(height: 20),
                    _buildPieChart(local),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(AppLocalizations local) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(local.translate('weeklyTrips')),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < 7; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: weeklyTrips[i].toDouble())
                        ],
                      )
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                     getTitlesWidget: (value, meta) {
  final daysShort = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];
  return SideTitleWidget(
    meta: meta,
    space: 8,
    child: Transform.rotate(
      angle: -0.5, // زاوية دوران النص (بالراديان، حوالي -30 درجة)
      child: Text(
        daysShort[value.toInt()],
        style: const TextStyle(fontSize: 12),
      ),
    ),
  );
},

                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(AppLocalizations local) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(local.translate('activeDriversPercentage')),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: activeDriversPercentage,
                      title: '${activeDriversPercentage.toStringAsFixed(1)}%',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: 100 - activeDriversPercentage,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
