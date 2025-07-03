import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';

class VipCorporatePage extends StatelessWidget {
  const VipCorporatePage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple.shade700,
        title: Text(
            AppLocalizations.of(context).translate('vip_corporate_management')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                AppLocalizations.of(context).translate('company_accounts')),
            _buildCompanyManagementCard(context),
            const SizedBox(height: 20),
            _buildSectionTitle(
                AppLocalizations.of(context).translate('vip_services')),
            _buildVipManagementCard(context),
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

  Widget _buildCompanyManagementCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(LucideIcons.building, color: Colors.blue),
        title: Text(
            AppLocalizations.of(context).translate('manage_company_accounts')),
        subtitle: Text(AppLocalizations.of(context)
            .translate('create_edit_follow_company_accounts')),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }

  Widget _buildVipManagementCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(LucideIcons.star, color: Colors.amber),
        title:
            Text(AppLocalizations.of(context).translate('manage_vip_services')),
        subtitle: Text(
            AppLocalizations.of(context).translate('grant_special_privileges')),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}
