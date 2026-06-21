import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    _fullNameController = TextEditingController(text: user?['fullName'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _addressController = TextEditingController(text: user?['address'] ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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

    final provider = Provider.of<AuthProvider>(context, listen: false);
    
    final Map<String, String> fields = {
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
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
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
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
                        image: _imageBytes != null 
                          ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                          : (user?['profileImage'] != null && user!['profileImage'].isNotEmpty)
                            ? DecorationImage(image: NetworkImage(user['profileImage']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_imageBytes == null && (user?['profileImage'] == null || user!['profileImage'].isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
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
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?['email'] ?? '',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'PERSONAL INFORMATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Default Delivery Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 40),
              Consumer<AuthProvider>(
                builder: (context, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submit,
                      child: provider.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                  label: const Text('Logout', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, minimumSize: const Size(100, 45)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
