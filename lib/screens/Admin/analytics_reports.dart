import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:taxi_app/language/localization.dart';

class AnalyticsReportsPage extends StatelessWidget {
  const AnalyticsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
   
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)
                .translate('trips_statistics')), // استخدام الترجمة
            _buildTripsChart(),
            const SizedBox(height: 20),
            _buildSectionTitle(AppLocalizations.of(context)
                .translate('active_drivers_percentage')), // استخدام الترجمة
            _buildActiveDriversPieChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTripsChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (int i = 1; i <= 7; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: (i * 10).toDouble(), color: Colors.blue)
              ])
          ],
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildActiveDriversPieChart(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
                value: 70,
                title: AppLocalizations.of(context).translate('active'),
                color: Colors.green,
                radius: 50), // استخدام الترجمة
            PieChartSectionData(
                value: 30,
                title: AppLocalizations.of(context).translate('inactive'),
                color: Colors.red,
                radius: 50), // استخدام الترجمة
          ],
        ),
      ),
    );
  }
}
