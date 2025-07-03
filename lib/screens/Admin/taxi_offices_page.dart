import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/taxi_office.dart';
import 'package:taxi_app/services/api_office.dart';
import 'package:taxi_app/widgets/add_office_dialog.dart';

class TaxiOfficesPage extends StatefulWidget {
  final String token;

  const TaxiOfficesPage({super.key, required this.token});

  @override
  _TaxiOfficesPageState createState() => _TaxiOfficesPageState();
}

class _TaxiOfficesPageState extends State<TaxiOfficesPage> {
  List<TaxiOffice> _offices = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(
        endpoint: '/api/admin/offices',
        token: widget.token,
      );

      if (response['success'] == true) {
        setState(() {
          _offices = (response['data'] as List)
              .map((office) => TaxiOffice.fromJson(office))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewOffice() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddOfficeDialog(token: widget.token),
    );

    if (result == true) {
      await _loadOffices();
    }
  }

  void _showOfficeDetails(BuildContext context, TaxiOffice office) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(isDesktop ? 100 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 700 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${local.translate('office_details')} #${office.officeId}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: LucideIcons.home,
                  label: local.translate('name'),
                  value: office.name,
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.mapPin,
                  label: local.translate('address'),
                  value: office.location.address,
                  theme: theme,
                ),
                const Divider(height: 32),
                Text(
                  local.translate('contact_info'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: LucideIcons.phone,
                  label: local.translate('phone'),
                  value: office.contact.phone,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: LucideIcons.mail,
                  label: local.translate('email'),
                  value: office.contact.email,
                  theme: theme,
                ),
                if (office.manager != null) ...[
                  const Divider(height: 32),
                  Text(
                    local.translate('manager_info'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: LucideIcons.user,
                    label: local.translate('name'),
                    value: office.manager!.fullName,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: LucideIcons.phone,
                    label: local.translate('phone'),
                    value: office.manager!.phone,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: LucideIcons.mail,
                    label: local.translate('email'),
                    value: office.manager!.email,
                    theme: theme,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(local.translate('close')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? theme.colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(AppLocalizations local, ThemeData theme) {
    // We removed the horizontal SingleChildScrollView.
    // The table will now shrink/grow with the screen width.
    return Container(
      constraints: const BoxConstraints(
          maxWidth: 1200), // Keeps it from getting too wide
      padding: const EdgeInsets.symmetric(horizontal: 32),
      // This Column separates the fixed header from the scrollable body.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. The Fixed Header (uses the new column widths)
          _buildTableHeader(local, theme),
          const SizedBox(height: 12),

          // 2. The Scrollable Body
          // Expanded takes all remaining VERTICAL space for vertical scrolling.
          Expanded(
            child: SingleChildScrollView(
              child: _offices.isEmpty
                  ? _buildEmptyState(theme, local.translate('no_offices_found'))
                  : Table(
                      // IMPORTANT: Use the same columnWidths as the header for alignment.
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(2.5),
                        2: FlexColumnWidth(4.0),
                        3: FlexColumnWidth(2.0),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      children: [
                        for (final office in _offices)
                          TableRow(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.5),
                            ),
                            children: [
                              // Cell 1: ID
                              InkWell(
                                onTap: () =>
                                    _showOfficeDetails(context, office),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    "#${office.officeId}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Cell 2: Name
                              InkWell(
                                onTap: () =>
                                    _showOfficeDetails(context, office),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 8),
                                  child: Text(
                                    office.name,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Cell 3: Address
                              InkWell(
                                onTap: () =>
                                    _showOfficeDetails(context, office),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 8),
                                  child: Text(
                                    office.location.address,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 3, // Allow more lines for address
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign
                                        .start, // Better for multi-line text
                                  ),
                                ),
                              ),
                              // Cell 4: Phone
                              InkWell(
                                onTap: () =>
                                    _showOfficeDetails(context, office),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    office.contact.phone,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // The 'Manager' cell is now removed.
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations local, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        // Use FlexColumnWidth for a responsive layout without horizontal scroll
        columnWidths: const {
          0: FlexColumnWidth(1.5), // ID
          1: FlexColumnWidth(2.5), // Name
          2: FlexColumnWidth(4.0), // Address (gets the most space)
          3: FlexColumnWidth(2.0), // Phone
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell(local.translate('id'), theme),
              _buildHeaderCell(local.translate('name'), theme),
              _buildHeaderCell(local.translate('address'), theme),
              _buildHeaderCell(local.translate('phone'), theme),
              // The 'Manager' header cell is now removed.
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMobileOfficeCard(TaxiOffice office, ThemeData theme) {
    final local = AppLocalizations.of(context);

    return InkWell(
      onTap: () => _showOfficeDetails(context, office),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    office.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Chip(
                    label: Text(
                      '#${office.officeId}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMobileOfficeDetail(
                icon: LucideIcons.mapPin,
                label: local.translate('address'),
                value: office.location.address,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildMobileOfficeDetail(
                icon: LucideIcons.phone,
                label: local.translate('phone'),
                value: office.contact.phone,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildMobileOfficeDetail(
                icon: LucideIcons.mail,
                label: local.translate('email'),
                value: office.contact.email,
                theme: theme,
              ),
              if (office.manager != null) ...[
                const Divider(height: 24),
                Text(
                  local.translate('manager_info'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileOfficeDetail(
                  icon: LucideIcons.user,
                  label: local.translate('name'),
                  value: office.manager!.fullName,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildMobileOfficeDetail(
                  icon: LucideIcons.phone,
                  label: local.translate('phone'),
                  value: office.manager!.phone,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildMobileOfficeDetail(
                  icon: LucideIcons.mail,
                  label: local.translate('email'),
                  value: office.manager!.email,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileOfficeDetail({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, AppLocalizations local) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            local.translate('error_loading_offices'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadOffices,
            icon: Icon(Icons.refresh, size: 18),
            label: Text(local.translate('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.home,
              size: 40,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewOffice,
        child: const Icon(LucideIcons.plus),
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary))
          : _error != null
              ? Center(child: _buildErrorWidget(theme, local))
              : RefreshIndicator(
                  onRefresh: _loadOffices,
                  color: theme.colorScheme.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 0 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 32, top: 16, bottom: 24),
                            child: Text(
                              local.translate('taxi_offices'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        if (!isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Icon(LucideIcons.home,
                                    size: 24, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  local.translate('taxi_offices'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isDesktop)
                          Expanded(child: _buildDesktopTable(local, theme))
                        else
                          Expanded(
                            child: _offices.isEmpty
                                ? _buildEmptyState(
                                    theme, local.translate('no_offices_found'))
                                : ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _offices.length,
                                    itemBuilder: (context, index) =>
                                        _buildMobileOfficeCard(
                                            _offices[index], theme),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
