import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/services/api_office.dart';

class AddOfficeDialog extends StatefulWidget {
  final String token;

  const AddOfficeDialog({super.key, required this.token});

  @override
  _AddOfficeDialogState createState() => _AddOfficeDialogState();
}

class _AddOfficeDialogState extends State<AddOfficeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _officeIdentifierController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerEmailController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  String? _gender = 'Male';
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.post(
        endpoint: '/api/admin/offices/with-manager',
        token: widget.token,
        data: {
          'officeIdentifier': _officeIdentifierController.text,
          'name': _nameController.text,
          'location': {
            'longitude': double.parse(_longitudeController.text),
            'latitude': double.parse(_latitudeController.text),
            'address': _addressController.text,
          },
          'contact': {
            'phone': _phoneController.text,
            'email': _emailController.text,
          },
          'managerData': {
            'fullName': _managerNameController.text,
            'email': _managerEmailController.text,
            'phone': _managerPhoneController.text,
            'gender': _gender,
          },
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // أضف هذه الدالة
  Future<void> _pickLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          onLocationSelected: (latLng, address) {
            setState(() {
              _latitudeController.text = latLng.latitude.toString();
              _longitudeController.text = latLng.longitude.toString();
              _addressController.text = address.isNotEmpty
                  ? address
                  : '${latLng.latitude}, ${latLng.longitude}';
            });
          },
        ),
      ),
    );
  }

// استبدل حقول الموقع بهذا الـ Ro

  @override
  void dispose() {
    _officeIdentifierController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    _managerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          minWidth: 400,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  local.translate('add_new_office'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _officeIdentifierController,
                        decoration: InputDecoration(
                          labelText: local.translate('office_identifier'),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: local.translate('office_name'),
                          prefixIcon: const Icon(Icons.business),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: local.translate('address'),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: local.translate('latitude'),
                                prefixIcon: const Icon(Icons.map),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: local.translate('longitude'),
                                prefixIcon: const Icon(Icons.map),
                              ),
                              readOnly: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map_outlined),
                            onPressed: _pickLocation,
                            tooltip: local.translate('select_from_map'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: local.translate('office_phone'),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: local.translate('office_email'),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const Divider(height: 32),
                      Text(
                        local.translate('manager_info'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _managerNameController,
                        decoration: InputDecoration(
                          labelText: local.translate('full_name'),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _managerEmailController,
                        decoration: InputDecoration(
                          labelText: local.translate('email'),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _managerPhoneController,
                        decoration: InputDecoration(
                          labelText: local.translate('phone'),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) => value!.isEmpty
                            ? local.translate('field_required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: ['Male', 'Female']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(
                                      local.translate(gender.toLowerCase())),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        decoration: InputDecoration(
                          labelText: local.translate('gender'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(local.translate('cancel')),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : Text(local.translate('add')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocationPicker extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;
  final LatLng? initialLocation;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String _address = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خدمة الموقع معطلة. يرجى تفعيلها')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفض إذن الموقع')),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحصول على الموقع: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateLocation(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
      _mapController.move(newLocation, 15.0);
    });

    // يمكنك هنا استدعاء API لعكس الجيوكودينج للحصول على العنوان المفصل
    _address = '${newLocation.latitude.toStringAsFixed(4)}, '
        '${newLocation.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الموقع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'الموقع الحالي',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedLocation != null) {
                widget.onLocationSelected(_selectedLocation!, _address);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _selectedLocation ?? const LatLng(31.9454, 35.9284),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                _updateLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taxi_app',
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن موقع...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _searchLocation(value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإحداثيات:',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      ),
                      if (_address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'العنوان:',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(_address),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedLocation != null) {
                            widget.onLocationSelected(
                                _selectedLocation!, _address);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('تأكيد الموقع'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);

          _updateLocation(LatLng(lat, lon));
          _address = firstResult['display_name'];
          _searchController.text = _address;
        }
      }
    } catch (e) {
      // يمكنك إضافة عرض رسالة خطأ هنا إذا لزم الأمر
      print('فشل في البحث: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

}
