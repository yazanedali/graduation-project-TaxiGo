import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:taxi_app/models/driver.dart';
import 'package:taxi_app/language/localization.dart'; // <--- إضافة استيراد الترجمة

class EditDriverProfilePage extends StatefulWidget {
  final int driverId;
  const EditDriverProfilePage({super.key, required this.driverId});

  @override
  State<EditDriverProfilePage> createState() => _EditDriverProfilePageState();
}

class _EditDriverProfilePageState extends State<EditDriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // عناصر التحكم في النموذج
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController carColorController = TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController licenseExpiryController = TextEditingController();

  bool isLoading = true;
  bool isUploading = false;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    // لا يمكن استدعاء AppLocalizations.of(context) هنا مباشرة
    // سيتم الحصول عليها داخل الدوال عند الحاجة أو في build
    loadDriverData();
  }

  Future<void> loadDriverData() async {
    setState(() => isLoading = true); // أضفت هذه لضمان عرض المؤشر عند كل تحميل
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/drivers/${widget.driverId}'),
      );

      if (response.statusCode == 200) {
        final driverData = json.decode(response.body);
        final driver = Driver.fromJson(driverData); // استخدم driverData هنا
        setState(() {
          fullNameController.text = driver.fullName;
          phoneController.text = driver.phone;
          emailController.text = driver.email;
          carModelController.text = driver.carModel;
          carColorController.text = driver.carColor;
          plateNumberController.text = driver.carPlateNumber;
          licenseNumberController.text = driver.licenseNumber;
          licenseExpiryController.text =
              driver.licenseExpiry.toString().substring(0, 10);
          _currentProfileImageUrl =
              driver.profileImageUrl; // <--- تخزين رابط الصورة
          isLoading = false;
        });
      } else {
        // محاولة تحليل رسالة الخطأ من الباكند إذا كانت موجودة
        String errorMessage = 'Failed to load driver data';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {
          // فشل في تحليل رسالة الخطأ، استخدم الرسالة الافتراضية
        }
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        // تحقق من أن الويدجت ما زال في شجرة الويدجتس
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: ${e.toString()}')),
        );
      }
      print('Error loading driver data: $e'); // للتحقق من الخطأ في الكونسول
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: ${e.toString()}')),
      );
    }
  }

  Future<String?> uploadImage() async {
    if (_selectedImageBytes == null) return null;

    try {
      final uri = Uri.parse(
        '${dotenv.env['BASE_URL']}/api/drivers/${widget.driverId}/profile-image',
      );

      final request = http.MultipartRequest('PUT', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _selectedImageBytes!,
        filename:
            'driver_${widget.driverId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody)['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);

    try {
      // رفع الصورة أولاً إذا تم اختيارها
      String? newImageUrl = await uploadImage();

      // تحديث بيانات السائق
      final updatedData = {
        "fullName": fullNameController.text,
        "phone": phoneController.text,
        "email": emailController.text,
        "carModel": carModelController.text,
        "carColor": carColorController.text,
        "carPlateNumber": plateNumberController.text,
        "licenseNumber": licenseNumberController.text,
        "licenseExpiry": licenseExpiryController.text,
        if (newImageUrl != null) "profileImageUrl": newImageUrl,
      };

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/api/drivers/${widget.driverId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
        );
        Navigator.pop(context, true); // العودة مع تحديث البيانات
      } else {
        throw Exception('Failed to update profile: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في الحفظ: ${e.toString()}")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Widget _buildProfileImage(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    ImageProvider? imageProvider;

    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentProfileImageUrl!);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: imageProvider,
              onBackgroundImageError: imageProvider is NetworkImage
                  ? (exception, stackTrace) {
                      print(
                          "Error loading network image for driver: $exception");
                    }
                  : null,
              child: imageProvider == null
                  ? Icon(Icons.person,
                      size: 50, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                onPressed: pickImage,
                tooltip: local.translate('tooltip_pick_image'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWidget({
    // تم تغيير الاسم لتجنب التعارض إذا كنت ستستخدمه بشكل مختلف في مكان آخر
    required BuildContext context,
    required TextEditingController controller,
    required String labelKey,
    required IconData icon,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Padding(
      // الحشوة العمودية هنا، والحشوة الأفقية ستتم إدارتها بواسطة Row أو Column
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
  labelText: local.translate(labelKey),
  prefixIcon: Icon(icon, color: theme.colorScheme.primary),
  filled: true,
  fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface, // متوافق مع الثيم
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: theme.dividerColor), // من الثيم
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
),
        validator: isRequired
            ? (value) => value!.isEmpty
                ? local.translate('validation_field_required')
                : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // تحديد نقطة الفصل بين التخطيطين، يمكنك تعديل هذه القيمة
    // 600 تعتبر نقطة فصل شائعة بين الهواتف والأجهزة اللوحية الصغيرة
    final bool useTwoColumns = screenWidth > 500; // <--- نقطة التحكم في التخطيط

    final double horizontalPagePadding = screenWidth < 400 ? 16 : 24;

    List<Widget> formFields = [
      _buildTextFieldWidget(
        context: context,
        controller: fullNameController,
        labelKey: 'label_full_name',
        icon: Icons.person_outline,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: phoneController,
        labelKey: 'label_phone_number',
        icon: Icons.phone_android_outlined,
        keyboardType: TextInputType.phone,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: emailController,
        labelKey: 'label_email',
        icon: Icons.email_outlined,
        isRequired: false,
        keyboardType: TextInputType.emailAddress,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: carModelController,
        labelKey: 'label_car_model',
        icon: Icons.directions_car_filled_outlined,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: carColorController,
        labelKey: 'label_car_color',
        icon: Icons.color_lens_outlined,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: plateNumberController,
        labelKey: 'label_plate_number',
        icon: Icons.confirmation_number_outlined,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: licenseNumberController,
        labelKey: 'label_license_number',
        icon: Icons.card_membership_outlined,
      ),
      _buildTextFieldWidget(
        context: context,
        controller: licenseExpiryController,
        labelKey: 'label_license_expiry_date',
        icon: Icons.calendar_today_outlined,
        keyboardType: TextInputType.datetime,
      ),
    ];

   return Scaffold(
  appBar: AppBar(
    title: Text(local.translate('title_edit_driver_profile')),
    centerTitle: true,
    elevation: 0,
    backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
  ),
  body: isLoading
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPagePadding,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileImage(context),
                const SizedBox(height: 24),
                if (useTwoColumns)
                  ..._buildTwoColumnLayout(context, formFields)
                else
                  ..._buildSingleColumnLayout(context, formFields),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isUploading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          local.translate('button_save_changes'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
);
  }

  // دالة لبناء تخطيط العمود الواحد
  List<Widget> _buildSingleColumnLayout(
      BuildContext context, List<Widget> fields) {
    List<Widget> widgets = [];
    for (var field in fields) {
      widgets.add(field);
      // لا حاجة لـ SizedBox إضافي هنا لأن _buildTextFieldWidget لديه vertical padding
    }
    return widgets;
  }

  // دالة لبناء تخطيط العمودين
  List<Widget> _buildTwoColumnLayout(
      BuildContext context, List<Widget> fields) {
    List<Widget> rows = [];
    for (int i = 0; i < fields.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment
              .start, // لمحاذاة الحقول بشكل أفضل إذا كان ارتفاعها مختلفًا
          children: [
            Expanded(child: fields[i]),
            const SizedBox(width: 12), // مسافة بين الحقلين في نفس الصف
            if (i + 1 < fields.length)
              Expanded(child: fields[i + 1])
            else
              Expanded(
                  child: Container()), // حقل فارغ ممتد إذا كان العدد فرديًا
          ],
        ),
      );
      // لا حاجة لـ SizedBox إضافي هنا لأن _buildTextFieldWidget لديه vertical padding
    }
    return rows;
  }
}
