import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/client.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditClientProfilePage extends StatefulWidget {
  final int clientId;
  const EditClientProfilePage({super.key, required this.clientId});

  @override
  State<EditClientProfilePage> createState() => _EditClientProfilePageState();
}

class _EditClientProfilePageState extends State<EditClientProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = true;
  bool isUploading = false;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    loadClientData();
  }

  Future<void> loadClientData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/clients/${widget.clientId}'),
      );

      if (response.statusCode == 200) {
        final clientData = json.decode(response.body);
        final client = Client.fromJson(clientData);

        setState(() {
          fullNameController.text = client.fullName;
          phoneController.text = client.phone;
          emailController.text = client.email;
          _currentProfileImageUrl = client.profileImageUrl;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load client data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar(context, 'Error loading data: ${e.toString()}');
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Image selection error: ${e.toString()}');
    }
  }

  Future<String?> uploadImage() async {
    if (_selectedImageBytes == null) return null;
    try {
      final uri = Uri.parse(
          '${dotenv.env['BASE_URL']}/api/clients/${widget.clientId}/profile-image');
      final request = http.MultipartRequest('PUT', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _selectedImageBytes!,
        filename: 'client_${widget.clientId}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody)['imageUrl'];
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isUploading = true);
    try {
      final newImageUrl = await uploadImage();
      final data = {
        'fullName': fullNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      };

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/api/clients/${widget.clientId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(context, 'Changes saved successfully');
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to update data');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to save: ${e.toString()}');
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final theme = Theme.of(context);
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
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: imageProvider != null
                  ? Image(image: imageProvider, fit: BoxFit.cover)
                  : Icon(
                      LucideIcons.user,
                      size: 60,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelKey,
    required IconData icon,
    bool isRequired = true,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: local.translate(labelKey),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          filled: true,
          fillColor: theme.cardTheme.color,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: isRequired
            ? (value) => value!.isEmpty ? local.translate('field_required') : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('edit_profile')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? MediaQuery.of(context).size.width * 0.25
                    : 24,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileImage(context),
                    const SizedBox(height: 32),
                    _buildTextField(
                      context: context,
                      controller: fullNameController,
                      labelKey: 'full_name',
                      icon: LucideIcons.user,
                    ),
                    _buildTextField(
                      context: context,
                      controller: phoneController,
                      labelKey: 'phone_number',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      context: context,
                      controller: emailController,
                      labelKey: 'email',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      isRequired: false,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isUploading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.save, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  local.translate('save_changes'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        child: Text(local.translate('cancel')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}