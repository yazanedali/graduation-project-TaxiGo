import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/language/localization.dart';
import 'dart:convert';

class PaymentsManagementPage extends StatefulWidget {
  const PaymentsManagementPage({super.key});

  @override
  State<PaymentsManagementPage> createState() => _PaymentsManagementPageState();
}

class _PaymentsManagementPageState extends State<PaymentsManagementPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _didLoadInitialData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadInitialData) {
      _fetchCompletedPayments();
      _didLoadInitialData = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // دالة مساعدة للحصول على القيمة المعروضة بشكل آمن
  String _getDisplayValue(dynamic value) {
    if (value == null)
      return AppLocalizations.of(context).translate('N/A'); // تم ترجمة 'N/A'
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is Map && value.containsKey('name')) {
      // إذا كان كائن (Map) ويحتوي على مفتاح 'name' (مثل {id: ..., name: ...})
      return value['name']?.toString() ??
          AppLocalizations.of(context).translate('N/A');
    }
    // في حال كانت القيمة من نوع آخر أو كائن بدون 'name'
    return value.toString();
  }

  Future<void> _fetchCompletedPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _transactions = [];
    });

    final localizations = AppLocalizations.of(context);

    try {
      final String? baseUrl = dotenv.env['BASE_URL'];
      if (baseUrl == null) {
        throw Exception(localizations.translate('api_error_config'));
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/completed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] is List) {
          setState(() {
            _transactions = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception("Invalid data format received.");
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to load payments with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching payments: $e');
      setState(() {
        _errorMessage = localizations.translate('error_loading_transactions') +
            (e is Exception ? ": ${e.toString().split(':').last}" : "");
        _isLoading = false;
      });
    }
  }

  // دالة مساعدة لترجمة النصوص (تغيرت لتنادي من AppLocalizations مباشرة)
  // String _localizedStrings(String key) => AppLocalizations.of(context).translate(key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchCompletedPayments,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : 16.0,
              vertical: isDesktop ? 32.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('payments_management_title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: isDesktop ? 32 : 24),
              _buildSectionTitle(
                  localizations.translate('transactions_section_title'),
                  theme,
                  isDesktop),
              SizedBox(height: isDesktop ? 20 : 16),
              _isLoading
                  ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                              color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(localizations.translate('loading_transactions'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget(theme, localizations, _errorMessage!)
                      : _transactions.isEmpty
                          ? _buildEmptyState(theme,
                              localizations.translate('no_transactions_found'))
                          : isDesktop
                              ? _buildDesktopTransactionTable(
                                  localizations, theme)
                              : _buildMobileTransactionList(
                                  localizations, theme),
              SizedBox(height: isDesktop ? 40 : 30),
              _buildSectionTitle(
                  localizations.translate('pricing_offers_section_title'),
                  theme,
                  isDesktop),
              SizedBox(height: isDesktop ? 20 : 16),
              _buildPricingControls(context, theme, localizations, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets المشتركة والمحسنة ---

  Widget _buildSectionTitle(String title, ThemeData theme, bool isCentered) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        textAlign: isCentered ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget _buildErrorWidget(
      ThemeData theme, AppLocalizations local, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchCompletedPayments,
            icon: const Icon(Icons.refresh),
            label: Text(local.translate('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Icon(LucideIcons.wallet,
                size: 60, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- تصميم الويب (Table) ---

  Widget _buildDesktopTransactionTable(
      AppLocalizations local, ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200), // عرض أقصى للجدول
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          // لضمان أن الحدود الدائرية تعمل مع Table
          borderRadius: BorderRadius.circular(15),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(100), // Trip ID
              1: FlexColumnWidth(1.5), // User
              2: FlexColumnWidth(1.5), // Driver
              3: FixedColumnWidth(120), // Amount
              4: FixedColumnWidth(150), // Payment Method
              5: FixedColumnWidth(150), // Date
              6: FixedColumnWidth(120), // Status
              7: FixedColumnWidth(80), // Action
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            children: [
              // رأس الجدول (Header Row)
              _buildTableHeader(local, theme),

              // صفوف البيانات (Data Rows)
              for (final transaction in _transactions)
                TableRow(
                  decoration: BoxDecoration(
                    color: (_getStatusColor(
                            transaction['status']?.toString() ?? 'unknown'))
                        .withOpacity(0.03), // لون خفيف للحالة
                  ),
                  children: [
                    // Trip ID
                    _buildTableCell(
                        context,
                        Text("#${_getDisplayValue(transaction['tripId'])}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary))),
                    // User
                    _buildTableCell(
                        context,
                        Text(_getDisplayValue(transaction['user']),
                            style: theme.textTheme.bodyMedium)),
                    // Driver
                    _buildTableCell(
                        context,
                        Text(_getDisplayValue(transaction['driver']),
                            style: theme.textTheme.bodyMedium)),
                    // Amount
                    _buildTableCell(
                        context,
                        Text(
                            "\$${transaction['amount']?.toStringAsFixed(2) ?? '--'}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface))),
                    // Payment Method
                    _buildTableCell(
                        context,
                        Text(_getDisplayValue(transaction['paymentMethod']),
                            style: theme.textTheme.bodyMedium)),
                    // Date
                    _buildTableCell(
                        context,
                        Text(
                          _formatDateTime(transaction['date']),
                          style: theme.textTheme.bodyMedium,
                        )),
                    // Status Badge
                    _buildTableCell(
                        context,
                        _buildStatusBadge(
                            transaction['status']?.toString(), local, theme)),
                    // Action (View Details)
                    _buildTableCell(
                      context,
                      IconButton(
                        icon: Icon(LucideIcons.eye,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)),
                        onPressed: () =>
                            _showTransactionDetails(context, transaction),
                        tooltip: local.translate('transaction_details'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader(AppLocalizations local, ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1), // لون لرأس الجدول
      ),
      children: [
        _buildHeaderCell(local.translate('trip_id'), theme),
        _buildHeaderCell(local.translate('user'), theme),
        _buildHeaderCell(local.translate('driver'), theme),
        _buildHeaderCell(local.translate('amount'), theme),
        _buildHeaderCell(local.translate('payment_method'), theme),
        _buildHeaderCell(local.translate('date'), theme),
        _buildHeaderCell(local.translate('status'), theme),
        _buildHeaderCell("", theme), // للزر (Action)
      ],
    );
  }

  Widget _buildHeaderCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          // خط أصغر قليلاً للرأس
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center, // توسيط نص الرأس
      ),
    );
  }

  Widget _buildTableCell(BuildContext context, Widget child) {
    return InkWell(
      // لجعل الخلية قابلة للضغط
      onTap: () {
        // يمكنك هنا تحديد إجراء عند الضغط على الخلية، مثلاً فتح التفاصيل
        // إذا كان child هو زر أو أيقونة، قد لا تحتاج لإعادة تعريف onTap
        // أو يمكنك تمرير المعاملة لفتح تفاصيلها
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Center(child: child), // توسيط محتوى الخلية
      ),
    );
  }

  Widget _buildStatusBadge(
      String? status, AppLocalizations local, ThemeData theme) {
    final statusText = _getStatusText(status ?? 'unknown', local);
    final statusColor = _getStatusColor(status ?? 'unknown');
    final statusIcon = _getStatusIcon(status ?? 'unknown');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- تصميم الموبايل (List) ---

  Widget _buildMobileTransactionList(AppLocalizations local, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // لمنع الـ scroll المزدوج
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              _getStatusIcon(transaction['status']?.toString() ?? 'unknown'),
              color: _getStatusColor(
                  transaction['status']?.toString() ?? 'unknown'),
              size: 30,
            ),
            title: Text(
                '${local.translate('trip_id')} #${_getDisplayValue(transaction['tripId'])}',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildInfoRow(LucideIcons.user, local.translate('user'),
                    _getDisplayValue(transaction['user']), theme),
                _buildInfoRow(LucideIcons.truck, local.translate('driver'),
                    _getDisplayValue(transaction['driver']), theme),
                _buildInfoRow(
                    LucideIcons.dollarSign,
                    local.translate('amount'),
                    "\$${transaction['amount']?.toStringAsFixed(2) ?? '--'}",
                    theme),
                _buildInfoRow(
                    LucideIcons.creditCard,
                    local.translate('payment_method'),
                    _getDisplayValue(transaction['paymentMethod']),
                    theme),
                _buildInfoRow(LucideIcons.calendar, local.translate('date'),
                    _formatDateTime(transaction['date']), theme),
                const SizedBox(height: 8),
                _buildStatusBadge(
                    transaction['status']?.toString(), local, theme),
              ],
            ),
            trailing: IconButton(
              icon: Icon(LucideIcons.eye,
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () {
                _showTransactionDetails(context, transaction);
              },
              tooltip: local.translate('transaction_details'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  TextSpan(
                    text: value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, dynamic transaction) {
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
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${local.translate('transaction_details')} #${_getDisplayValue(transaction['tripId'])}",
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
                  icon: LucideIcons.user,
                  label: local.translate('user'),
                  value: _getDisplayValue(transaction['user']),
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.truck,
                  label: local.translate('driver'),
                  value: _getDisplayValue(transaction['driver']),
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.creditCard,
                  label: local.translate('payment_method'),
                  value: _getDisplayValue(transaction['paymentMethod']),
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.dollarSign,
                  label: local.translate('amount'),
                  value:
                      "\$${transaction['amount']?.toStringAsFixed(2) ?? '--'}",
                  theme: theme,
                  color: theme.colorScheme.primary,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: LucideIcons.calendar,
                  label: local.translate('transaction_date_time'),
                  value: _formatDateTime(transaction['date']),
                  theme: theme,
                ),
                const Divider(height: 32),
                _buildDetailRow(
                  icon: _getStatusIcon(
                      transaction['status']?.toString() ?? 'unknown'),
                  label: local.translate('payment_status'),
                  value: _getStatusText(
                      transaction['status']?.toString() ?? 'unknown', local),
                  color: _getStatusColor(
                      transaction['status']?.toString() ?? 'unknown'),
                  theme: theme,
                ),
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
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }

  Widget _buildPricingControls(BuildContext context, ThemeData theme,
      AppLocalizations local, bool isDesktop) {
    return Center(
      child: Container(
        constraints:
            BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
        child: Column(
          children: [
            Card(
              color: theme.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Icon(LucideIcons.dollarSign,
                    color: theme.colorScheme.primary, size: 28),
                title: Text(local.translate('edit_fare_prices'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                trailing: IconButton(
                  icon: Icon(LucideIcons.edit,
                      color: theme.colorScheme.secondary, size: 24),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Future: Edit Fare Prices feature")),
                    );
                  },
                  tooltip: local.translate('edit_fare_prices'),
                ),
              ),
            ),
            Card(
              color: theme.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Icon(LucideIcons.percent,
                    color: theme.colorScheme.primary, size: 28),
                title: Text(local.translate('manage_offers_discounts'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                trailing: IconButton(
                  icon: Icon(LucideIcons.edit,
                      color: theme.colorScheme.secondary, size: 24),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Future: Manage Offers & Discounts feature")),
                    );
                  },
                  tooltip: local.translate('manage_offers_discounts'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return LucideIcons.checkCircle;
      case 'pending':
        return LucideIcons.clock;
      default:
        return LucideIcons.alertTriangle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations local) {
    switch (status) {
      case 'completed':
        return local.translate('completed');
      case 'pending':
        return local.translate('pending');
      default:
        return local.translate('pending');
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '--';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return '--';
    }
  }
}
