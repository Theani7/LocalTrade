import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _shopNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _hoursController;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();
  List<String> _selectedCategories = [];

  final List<String> _allCategories = [
    'Vegetables', 'Dairy', 'Handicrafts', 'Clothing', 'Local Goods', 'Tailoring', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<VendorProvider>(context, listen: false).profile;

    _fullNameController = TextEditingController(text: profile?['fullName'] ?? '');
    _shopNameController = TextEditingController(text: profile?['shopName'] ?? '');
    _phoneController = TextEditingController(text: profile?['phone'] ?? '');
    _addressController = TextEditingController(text: profile?['address'] ?? '');
    _descriptionController = TextEditingController(text: profile?['businessDescription'] ?? '');
    _hoursController = TextEditingController(text: profile?['openingHours'] ?? '9:00 AM - 6:00 PM');

    if (profile?['categories'] != null) {
      _selectedCategories = List<String>.from(profile!['categories']);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<VendorProvider>(context, listen: false);

    final Map<String, String> fields = {
      'fullName': _fullNameController.text.trim(),
      'shopName': _shopNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'businessDescription': _descriptionController.text.trim(),
      'openingHours': _hoursController.text.trim(),
      'categories': json.encode(_selectedCategories),
    };

    final success = await provider.updateProfile(fields, image: _imageFile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully' : (provider.error ?? 'Update failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<VendorProvider>(context).profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.coralLight,
                        image: _imageBytes != null
                            ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                            : (profile?['profileImage'] != null && profile!['profileImage'].isNotEmpty)
                                ? DecorationImage(image: NetworkImage(profile['profileImage']), fit: BoxFit.cover)
                                : null,
                      ),
                      child: (_imageBytes == null && (profile?['profileImage'] == null || profile!['profileImage'].isEmpty))
                          ? const Icon(Icons.store_rounded, size: 40, color: AppColors.coral)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Owner info
              const Text('Owner information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 12),
              _buildField(controller: _fullNameController, label: 'Full name', icon: Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildField(controller: _phoneController, label: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),

              // Business details
              const Text('Business details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 12),
              _buildField(controller: _shopNameController, label: 'Shop name', icon: Icons.storefront_rounded),
              const SizedBox(height: 12),
              _buildField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 12),
              _buildField(controller: _hoursController, label: 'Opening hours', icon: Icons.access_time_rounded),
              const SizedBox(height: 12),
              _buildField(controller: _descriptionController, label: 'Description', icon: Icons.description_outlined, maxLines: 4),
              const SizedBox(height: 20),

              // Categories
              const Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 12),
              MultiSelectDialogField(
                items: _allCategories.map((e) => MultiSelectItem(e, e)).toList(),
                initialValue: _selectedCategories,
                title: const Text('Select categories'),
                selectedColor: AppColors.coral,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                buttonIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.coral),
                buttonText: Text(
                  _selectedCategories.isEmpty ? 'Select categories' : _selectedCategories.join(', '),
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                onConfirm: (results) {
                  setState(() => _selectedCategories = List<String>.from(results));
                },
              ),
              const SizedBox(height: 24),

              // Save button
              Consumer<VendorProvider>(
                builder: (context, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
        prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
