import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart';
import 'package:taxi_app/language/localization.dart'; // استيراد الترجمة

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Country? selectedCountry;
  String? selectedCity;
  List<String> cities = [];

  /// 🗺️ قائمة المدن لكل دولة
  final Map<String, List<String>> countryCities = {
    'PS': ['Gaza', 'Ramallah', 'Nablus', 'Hebron', 'Jenin', 'Jericho'],
    'JO': ['Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Salt', 'Madaba'],
    'US': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami'],
    'AE': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'],
    'SA': ['Riyadh', 'Jeddah', 'Dammam', 'Medina', 'Mecca'],
    'EG': ['Cairo', 'Alexandria', 'Giza', 'Luxor', 'Aswan'],
    'FR': ['Paris', 'Lyon', 'Marseille', 'Nice', 'Toulouse'],
    'DE': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Cologne'],
    'IN': ['Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Hyderabad'],
    'CN': ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen'],
  };

  /// 📸 التقاط صورة أو اختيارها من الجهاز
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_album),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);

    bool isWeb = MediaQuery.of(context).size.width > 600;

    Widget profileForm = Column(
      children: [
        /// ✅ صورة البروفايل (مع إمكانية التغيير)
        Center(
          child: GestureDetector(
            onTap: () => _showImageSourceDialog(context),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : AssetImage('../../assets/image-removebg-preview1.png')
                      as ImageProvider,
              child: _profileImage == null
                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),

        /// ✅ الحقول النصية مع الترجمة
        _buildTextField(_fullNameController, Icons.person, localization.translate('full_name')),
        const SizedBox(height: 10),

        /// ✅ اختيار الدولة
        _buildCountryPicker(localization),
        const SizedBox(height: 10),

        /// ✅ اختيار المدينة بناءً على الدولة المختارة
        _buildCityDropdown(localization),
        const SizedBox(height: 10),

        /// ✅ باقي الحقول مع الترجمة
        _buildTextField(_emailController, Icons.email, localization.translate('email')),
        const SizedBox(height: 10),
        _buildTextField(_streetController, Icons.home, localization.translate('street')),
        const SizedBox(height: 10),
        _buildTextField(_districtController, Icons.business, localization.translate('district')),
        const SizedBox(height: 20),

        /// ✅ أزرار الحفظ والإلغاء مع الترجمة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButton(localization.translate('cancel'), Colors.grey, () {
              Navigator.pop(context);
            }),
            _buildButton(localization.translate('save'), Colors.yellow[700]!, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localization.translate('profile_saved'))),
              );
            }),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWeb
            ? Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: profileForm,
                ),
              )
            : SingleChildScrollView(child: profileForm),
      ),
    );
  }

  /// 🎨 اختيار الدولة مع الترجمة
 Widget _buildCountryPicker(AppLocalizations localization) {
  return TextFormField(
    readOnly: true,
    decoration: InputDecoration(
      labelText: selectedCountry != null
          ? "${selectedCountry!.name} (+${selectedCountry!.phoneCode})"
          : localization.translate('select_country'),
      prefixIcon: selectedCountry != null
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 20)),
            )
          : const Icon(Icons.public),
      border: OutlineInputBorder(),
      suffixIcon: const Icon(Icons.arrow_drop_down),
    ),
    onTap: () {
      showCountryPicker(
        context: context,
        showPhoneCode: true,
        onSelect: (Country country) {
          setState(() {
            selectedCountry = country;
            selectedCity = null;
            cities = countryCities[country.countryCode] ?? [];
          });
        },
      );
    },
  );
}


  /// 🎨 اختيار المدينة مع الترجمة
  Widget _buildCityDropdown(AppLocalizations localization) {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration(Icons.location_city, localization.translate('city')),
      value: selectedCity,
      items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
      onChanged: (value) {
        setState(() {
          selectedCity = value;
        });
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String label) {
    return TextField(
      controller: controller,
      decoration: _buildInputDecoration(icon, label),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon, String label) {
    return InputDecoration(labelText: label, border: OutlineInputBorder(), prefixIcon: Icon(icon));
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
