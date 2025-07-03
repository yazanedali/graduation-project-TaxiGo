import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/services/taxi_office_api.dart';
import 'dart:math';

class AddDriverDialog extends StatefulWidget {
  final int officeId;
  final String token;
  final Function() onDriverAdded;

  const AddDriverDialog({
    super.key,
    required this.officeId,
    required this.token,
    required this.onDriverAdded,
  });

  @override
  _AddDriverDialogState createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carPlateController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseExpiryController =
      TextEditingController();

  String _selectedGender =
      'Male'; // القيم الفعلية للـ API يجب أن تبقى Male/Female
  String _carColor = 'أبيض';
  int? _carYear;
  DateTime? _licenseExpiryDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _licenseExpiryDate = DateTime.now().add(const Duration(days: 365));
    _licenseExpiryController.text =
        DateFormat('dd/MM/yyyy').format(_licenseExpiryDate!);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  Future<void> _selectLicenseExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: AppLocalizations.of(context)
          .translate('add_driver_select_expiry_date_prompt'), // مترجمة
      cancelText: AppLocalizations.of(context)
          .translate('add_driver_cancel_button'), // مترجمة
      confirmText: AppLocalizations.of(context)
          .translate('add_driver_confirm_button'), // مترجمة
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _licenseExpiryDate) {
      setState(() {
        _licenseExpiryDate = picked;
        _licenseExpiryController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_licenseExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).translate(
                  'add_driver_select_expiry_date_snackbar'))), // مترجمة
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await TaxiOfficeApi.createDriver(
          officeId: widget.officeId,
          token: widget.token,
          fullName: _fullNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          gender: _selectedGender,
          carModel: _carModelController.text,
          carPlateNumber: _carPlateController.text,
          carColor: _carColor,
          carYear: _carYear ?? DateTime.now().year,
          licenseNumber: _licenseNumberController.text,
          licenseExpiry: _licenseExpiryDate!.toIso8601String(),
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onDriverAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('add_driver_success_message'))), // مترجمة
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context).translate('add_driver_failure_message')} ${e.toString()}')), // مترجمة
        );
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormField(TextEditingController? controller,
      String labelKey, // استخدم key بدلاً من النص مباشرة
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      bool readOnly = false,
      VoidCallback? onTap,
      String? initialValue,
      ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).translate(labelKey), // مترجمة
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownFormField(
      String value,
      List<DropdownMenuItem<String>> items,
      String labelKey, // استخدم key بدلاً من النص مباشرة
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).translate(labelKey), // مترجمة
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    // استخدم key بدلاً من النص مباشرة
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        AppLocalizations.of(context).translate(titleKey), // مترجمة
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    final double contentWidth = isLargeScreen
        ? min(screenWidth * 0.8, 700.0)
        : min(screenWidth * 0.9, 400.0);

    return AlertDialog(
      title: Text(
          AppLocalizations.of(context).translate('add_driver_dialog_title'),
          textAlign: TextAlign.center), // مترجمة
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: contentWidth,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionTitle(
                    context, 'add_driver_car_info_title'), // استخدام key
                isLargeScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildFormField(
                                  _fullNameController,
                                  'add_driver_full_name_label', // استخدام key
                                  validator: (value) => value!.isEmpty
                                      ? AppLocalizations.of(context).translate(
                                          'add_driver_full_name_required') // مترجمة
                                      : null,
                                ),
                                _buildFormField(
                                  _emailController,
                                  'add_driver_email_label', // استخدام key
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) => value!.isEmpty
                                      ? AppLocalizations.of(context).translate(
                                          'add_driver_email_required') // مترجمة
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildFormField(
                                  _phoneController,
                                  'add_driver_phone_label', // استخدام key
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => value!.isEmpty
                                      ? AppLocalizations.of(context).translate(
                                          'add_driver_phone_required') // مترجمة
                                      : null,
                                ),
                                _buildDropdownFormField(
                                  _selectedGender,
                                  [
                                    DropdownMenuItem(
                                        value: 'Male',
                                        child: Text(AppLocalizations.of(context)
                                            .translate(
                                                'gender_male'))), // مترجمة
                                    DropdownMenuItem(
                                        value: 'Female',
                                        child: Text(AppLocalizations.of(context)
                                            .translate(
                                                'gender_female'))), // مترجمة
                                  ],
                                  'add_driver_gender_label', // استخدام key
                                  (value) =>
                                      setState(() => _selectedGender = value!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildFormField(
                            _fullNameController,
                            'add_driver_full_name_label', // استخدام key
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)
                                    .translate('add_driver_full_name_required')
                                : null,
                          ),
                          _buildFormField(
                            _emailController,
                            'add_driver_email_label', // استخدام key
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)
                                    .translate('add_driver_email_required')
                                : null,
                          ),
                          _buildFormField(
                            _phoneController,
                            'add_driver_phone_label', // استخدام key
                            keyboardType: TextInputType.phone,
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)
                                    .translate('add_driver_phone_required')
                                : null,
                          ),
                          _buildDropdownFormField(
                            _selectedGender,
                            [
                              DropdownMenuItem(
                                  value: 'Male',
                                  child: Text(AppLocalizations.of(context)
                                      .translate('gender_male'))),
                              DropdownMenuItem(
                                  value: 'Female',
                                  child: Text(AppLocalizations.of(context)
                                      .translate('gender_female'))),
                            ],
                            'add_driver_gender_label', // استخدام key
                            (value) => setState(() => _selectedGender = value!),
                          ),
                        ],
                      ),

                _buildSectionTitle(
                    context, 'add_driver_car_info_title'), // استخدام key
                isLargeScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildFormField(
                                  _carModelController,
                                  'add_driver_car_model_label', // استخدام key
                                  validator: (value) => value!.isEmpty
                                      ? AppLocalizations.of(context).translate(
                                          'add_driver_car_model_required')
                                      : null,
                                ),
                                _buildFormField(
                                  _carPlateController,
                                  'add_driver_car_plate_label', // استخدام key
                                  validator: (value) => value!.isEmpty
                                      ? AppLocalizations.of(context).translate(
                                          'add_driver_car_plate_required')
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildFormField(
                                  null,
                                  'add_driver_car_color_label', // استخدام key
                                  initialValue: _carColor,
                                  onChanged: (value) => _carColor = value,
                                ),
                                _buildFormField(
                                  null,
                                  'add_driver_car_year_label', // استخدام key
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      _carYear = int.tryParse(value),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)
                                          .translate(
                                              'add_driver_car_year_required');
                                    }
                                    if (int.tryParse(value) == null) {
                                      return AppLocalizations.of(context).translate(
                                          'add_driver_car_year_invalid_number');
                                    }
                                    final year = int.parse(value);
                                    if (year < 1900 ||
                                        year > DateTime.now().year + 2) {
                                      return AppLocalizations.of(context)
                                          .translate(
                                              'add_driver_car_year_invalid_range');
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildFormField(
                            _carModelController,
                            'add_driver_car_model_label', // استخدام key
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)
                                    .translate('add_driver_car_model_required')
                                : null,
                          ),
                          _buildFormField(
                            _carPlateController,
                            'add_driver_car_plate_label', // استخدام key
                            validator: (value) => value!.isEmpty
                                ? AppLocalizations.of(context)
                                    .translate('add_driver_car_plate_required')
                                : null,
                          ),
                          _buildFormField(
                            null,
                            'add_driver_car_color_label', // استخدام key
                            initialValue: _carColor,
                            onChanged: (value) => _carColor = value,
                          ),
                          _buildFormField(
                            null,
                            'add_driver_car_year_label', // استخدام key
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                _carYear = int.tryParse(value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)
                                    .translate('add_driver_car_year_required');
                              }
                              if (int.tryParse(value) == null) {
                                return AppLocalizations.of(context).translate(
                                    'add_driver_car_year_invalid_number');
                              }
                              final year = int.parse(value);
                              if (year < 1900 ||
                                  year > DateTime.now().year + 2) {
                                return AppLocalizations.of(context).translate(
                                    'add_driver_car_year_invalid_range');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                _buildSectionTitle(
                    context, 'add_driver_license_info_title'), // استخدام key
                _buildFormField(
                  _licenseNumberController,
                  'add_driver_license_number_label', // استخدام key
                  validator: (value) => value!.isEmpty
                      ? AppLocalizations.of(context)
                          .translate('add_driver_license_number_required')
                      : null,
                ),
                _buildFormField(
                  _licenseExpiryController,
                  'add_driver_license_expiry_label', // استخدام key
                  readOnly: true,
                  onTap: () => _selectLicenseExpiryDate(context),
                  validator: (value) =>
                      value!.isEmpty || _licenseExpiryDate == null
                          ? AppLocalizations.of(context)
                              .translate('add_driver_license_expiry_required')
                          : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)
              .translate('add_driver_cancel_button')), // مترجمة
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitForm,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: _isLoading
              ? Text(AppLocalizations.of(context)
                  .translate('add_driver_saving_button'))
              : Text(AppLocalizations.of(context)
                  .translate('add_driver_save_button')), // مترجمة
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
