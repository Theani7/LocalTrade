import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../providers/vendor_provider.dart';
import '../../core/theme/app_theme.dart';
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
  
  File? _imageFile;
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
      setState(() => _imageFile = File(pickedFile.path));
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
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Update failed'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<VendorProvider>(context).profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Business Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        boxShadow: AppTheme.softShadow,
                        image: _imageFile != null 
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (profile?['profileImage'] != null && profile!['profileImage'].isNotEmpty)
                            ? DecorationImage(image: NetworkImage(profile['profileImage']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_imageFile == null && (profile?['profileImage'] == null || profile!['profileImage'].isEmpty))
                        ? const Icon(Icons.store, size: 50, color: Colors.grey)
                        : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Owner Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Owner Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Business Phone', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Business Details'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Shop / Brand Name', prefixIcon: Icon(Icons.storefront)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Store Address', prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(
                  labelText: 'Opening Hours', 
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'e.g., 9:00 AM - 7:00 PM',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Business Description'),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Categories'),
              const SizedBox(height: 8),
              MultiSelectDialogField(
                items: _allCategories.map((e) => MultiSelectItem(e, e)).toList(),
                initialValue: _selectedCategories,
                title: const Text("Select Categories"),
                selectedColor: AppTheme.primaryColor,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                buttonIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                buttonText: const Text("Product Categories", style: TextStyle(fontSize: 16)),
                onConfirm: (results) {
                  setState(() => _selectedCategories = List<String>.from(results));
                },
              ),
              const SizedBox(height: 40),
              Consumer<VendorProvider>(
                builder: (context, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: provider.isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.2),
    );
  }
}
