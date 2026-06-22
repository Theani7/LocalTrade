import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';
import 'notification_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  late TextEditingController _flatController;
  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();

  bool _isEditingProfile = false;
  bool _isEditingAddress = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _fullNameController = TextEditingController(text: user?['fullName'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');

    final addr = user?['address'];
    _flatController = TextEditingController(text: addr is Map ? (addr['flatHouse'] ?? '') : '');
    _streetController = TextEditingController(text: addr is Map ? (addr['street'] ?? '') : '');
    _landmarkController = TextEditingController(text: addr is Map ? (addr['landmark'] ?? '') : '');
    _cityController = TextEditingController(text: addr is Map ? (addr['city'] ?? '') : '');
    _stateController = TextEditingController(text: addr is Map ? (addr['state'] ?? '') : '');
    _zipController = TextEditingController(text: addr is Map ? (addr['zipCode'] ?? '') : '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.updateProfile({
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, image: _imageFile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated' : (provider.error ?? 'Update failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) setState(() => _isEditingProfile = false);
    }
  }

  void _submitAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;

    final provider = Provider.of<AuthProvider>(context, listen: false);

    final address = {
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'flatHouse': _flatController.text.trim(),
      'street': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zipCode': _zipController.text.trim(),
    };

    final success = await provider.updateProfile({
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': jsonEncode(address),
    });

    if (success) {
      // Force re-fetch user from backend to ensure address is persisted
      await provider.validateToken();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Address saved' : (provider.error ?? 'Update failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) setState(() => _isEditingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline_rounded, size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 16),
              const Text('Login to view your profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text('Sign in to manage your account', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  AuthGuard.requireAuth(context, onAuthenticated: () {
                    if (mounted) setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: AppColors.ink),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final user = Provider.of<AuthProvider>(context).user;
    final name = user?['fullName'] ?? 'User';
    final email = user?['email'] ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(user, name, email, initials),
            _buildProfileEditForm(),
            _buildAddressEditForm(),
            const SizedBox(height: 24),
            _buildSectionLabel('Account Settings'),
            const SizedBox(height: 8),
            _buildSettingsGroup(user),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user, String name, String email, String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coralLight,
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : (user?['profileImage'] != null && (user!['profileImage'] as String).isNotEmpty)
                          ? DecorationImage(image: NetworkImage(user['profileImage']), fit: BoxFit.cover)
                          : null,
                ),
                child: (_imageBytes == null && (user?['profileImage'] == null || (user?['profileImage'] as String?)?.isEmpty == true))
                    ? Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.coral))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: -4,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5),
    );
  }

  Widget _buildSettingsGroup(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Name, phone',
            onTap: () => setState(() => _isEditingProfile = !_isEditingProfile),
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'View order history',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen())),
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage alerts',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Delivery Address',
            subtitle: _getAddressSummary(user),
            onTap: () => setState(() => _isEditingAddress = !_isEditingAddress),
          ),
        ],
      ),
    );
  }

  String _getAddressSummary(dynamic user) {
    final addr = user?['address'];
    if (addr is Map) {
      final parts = <String>[
        if ((addr['flatHouse'] ?? '').isNotEmpty) addr['flatHouse'],
        if ((addr['city'] ?? '').isNotEmpty) addr['city'],
        if ((addr['state'] ?? '').isNotEmpty) addr['state'],
      ];
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return 'No address set';
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // ── Personal Info Edit ──
  Widget _buildProfileEditForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isEditingProfile
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _card(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                            onPressed: () => setState(() => _isEditingProfile = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _field(controller: _fullNameController, label: 'Full name', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _field(controller: _phoneController, label: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      Consumer<AuthProvider>(
                        builder: (context, provider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : _submitProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.coral,
                                disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                                  : const Text('Save', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Address Edit ──
  Widget _buildAddressEditForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isEditingAddress
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _card(
                child: Form(
                  key: _addressFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                            onPressed: () => setState(() => _isEditingAddress = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _field(controller: _flatController, label: 'Flat / House number', icon: Icons.home_outlined),
                      const SizedBox(height: 12),
                      _field(controller: _streetController, label: 'Street / Area', icon: Icons.route_outlined),
                      const SizedBox(height: 12),
                      _field(controller: _landmarkController, label: 'Landmark (optional)', icon: Icons.flag_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(controller: _cityController, label: 'City', icon: Icons.location_city_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(controller: _stateController, label: 'State', icon: Icons.map_outlined)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _zipController,
                        label: 'Zip code',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Consumer<AuthProvider>(
                        builder: (context, provider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : _submitAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.coral,
                                disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                                  : const Text('Save Address', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
        label: const Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _field({
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
      inputFormatters: keyboardType == TextInputType.phone || keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CustomerHomeScreen()), (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
