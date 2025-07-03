import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';

class SecurityMonitoringPage extends StatelessWidget {
  const SecurityMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red.shade700,
        title:
            Text(AppLocalizations.of(context).translate('security_monitoring')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                AppLocalizations.of(context).translate('emergency_alerts')),
            _buildEmergencyAlerts(context),
            const SizedBox(height: 20),
            _buildSectionTitle(
                AppLocalizations.of(context).translate('suspicious_trips')),
            _buildSuspiciousTripsList(),
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

  Widget _buildEmergencyAlerts(BuildContext context) {
    return Card(
      color: Colors.red.shade100,
      child: ListTile(
        leading: const Icon(LucideIcons.alertCircle, color: Colors.red),
        title: Text(
            AppLocalizations.of(context).translate('sos_button_activated')),
        subtitle: const Text("سائق: أحمد - الموقع الحالي: شارع الملك فهد"),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            // استدعاء الطوارئ
          },
          child: Text(AppLocalizations.of(context).translate('take_action')),
        ),
      ),
    );
  }

  Widget _buildSuspiciousTripsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(LucideIcons.zap, color: Colors.orange),
              title: Text(
                  AppLocalizations.of(context).translate('suspicious_trip') +
                      " #${index + 1}"),
              subtitle: Text(AppLocalizations.of(context)
                  .translate('route_change_detected')),
              trailing: IconButton(
                icon: const Icon(LucideIcons.eye),
                onPressed: () {
                  // عرض التفاصيل
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
