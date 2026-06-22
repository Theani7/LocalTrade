import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/app_button.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';
import 'notification_screen.dart';

String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

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
    _flatController = TextEditingController(
        text: addr is Map ? (addr['flatHouse'] ?? '') : '');
    _streetController =
        TextEditingController(text: addr is Map ? (addr['street'] ?? '') : '');
    _landmarkController = TextEditingController(
        text: addr is Map ? (addr['landmark'] ?? '') : '');
    _cityController =
        TextEditingController(text: addr is Map ? (addr['city'] ?? '') : '');
    _stateController =
        TextEditingController(text: addr is Map ? (addr['state'] ?? '') : '');
    _zipController =
        TextEditingController(text: addr is Map ? (addr['zipCode'] ?? '') : '');

    // Fetch orders for stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (orderProvider.orders.isEmpty) {
        orderProvider.fetchMyOrders();
      }
    });
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
          content: Text(success
              ? 'Profile updated'
              : (provider.error ?? 'Update failed')),
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
      await provider.validateToken();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Address saved' : (provider.error ?? 'Update failed')),
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
          title: Text('My Account', style: AppTextStyles.screenTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline_rounded,
                    size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 16),
              Text('Login to view your profile',
                  style: AppTextStyles.sectionHeading),
              const SizedBox(height: 8),
              Text('Sign in to manage your account',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: 20),
              AppButton(
                label: 'Login',
                onPressed: () {
                  AuthGuard.requireAuth(context, onAuthenticated: () {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    final user = Provider.of<AuthProvider>(context).user;
    final name = user?['fullName'] ?? 'User';
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? 'customer';
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';
    final hasAddress = user?['address'] is Map &&
        ((user!['address']['flatHouse'] ?? '').toString().isNotEmpty ||
            (user['address']['street'] ?? '').toString().isNotEmpty ||
            (user['address']['landmark'] ?? '').toString().isNotEmpty ||
            (user['address']['city'] ?? '').toString().isNotEmpty ||
            (user['address']['state'] ?? '').toString().isNotEmpty ||
            (user['address']['zipCode'] ?? '').toString().isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Account',
          style: AppTextStyles.screenTitle,
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
            // ── Profile card ──
            _buildProfileCard(user, name, email, initials, role),
            const SizedBox(height: 16),

            // ── Quick stats ──
            _buildQuickStats(),
            const SizedBox(height: 24),

            // ── Profile edit form (expandable) ──
            _buildProfileEditForm(),
            _buildAddressEditForm(),

            // ── Account Settings ──
            _buildSectionLabel('Account Settings'),
            const SizedBox(height: 8),
            _buildSettingsGroup(user, hasAddress),
            const SizedBox(height: 24),

            // ── Support ──
            _buildSectionLabel('Support'),
            const SizedBox(height: 8),
            _buildSupportGroup(),
            const SizedBox(height: 24),

            // ── Logout (neutral row) ──
            _buildLogoutRow(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile card — horizontal layout: avatar left, name+email+role right, edit far right
  // ---------------------------------------------------------------------------
  Widget _buildProfileCard(
      dynamic user, String name, String email, String initials, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar — centered initials
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coralLight,
                  image: _imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : (user?['profileImage'] != null &&
                              (user!['profileImage'] as String).isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(user['profileImage']),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: (_imageBytes == null &&
                        (user?['profileImage'] == null ||
                            (user?['profileImage'] as String?)?.isEmpty ==
                                true))
                    ? Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.coralDark,
                          ),
                        ),
                      )
                    : null,
              ),
              // Camera badge — ink icon on coral fill
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.ink, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name, email, role badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _toTitleCase(name),
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: AppTextStyles.label.copyWith(color: AppColors.blueDark, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Edit icon
          GestureDetector(
            onTap: () => setState(() => _isEditingProfile = !_isEditingProfile),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick stats row — total orders, pending orders, saved items (cart count)
  // ---------------------------------------------------------------------------
  Widget _buildQuickStats() {
    return Consumer2<OrderProvider, CartProvider>(
      builder: (context, orderProvider, cartProvider, _) {
        final orders = orderProvider.orders;
        final totalOrders = orders.length;
        final pendingOrders = orders.where((o) {
          final status = (o['orderStatus'] ?? '').toString().toLowerCase();
          return status == 'pending' ||
              status == 'confirmed' ||
              status == 'processing';
        }).length;
        final savedItems = cartProvider.items.length;

        return Row(
          children: [
            _buildStatCard(
              value: '$totalOrders',
              label: 'Total orders',
              icon: Icons.receipt_long_outlined,
              bgColor: AppColors.coralLight,
              iconColor: AppColors.coralDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              value: '$pendingOrders',
              label: 'Pending',
              icon: Icons.schedule_outlined,
              bgColor: AppColors.warningLight,
              iconColor: AppColors.warningDark,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              value: '$savedItems',
              label: 'In cart',
              icon: Icons.shopping_bag_outlined,
              bgColor: AppColors.blueLight,
              iconColor: AppColors.blueDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: AppTextStyles.price.copyWith(fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section label
  // ---------------------------------------------------------------------------
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(letterSpacing: 0.5),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings group — alternating icon backgrounds
  // ---------------------------------------------------------------------------
  Widget _buildSettingsGroup(dynamic user, bool hasAddress) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Name, phone',
            iconBg: AppColors.coralLight,
            iconColor: AppColors.coralDark,
            onTap: () => setState(() => _isEditingProfile = !_isEditingProfile),
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'View order history',
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blueDark,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CustomerOrdersScreen())),
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage alerts',
            iconBg: AppColors.coralLight,
            iconColor: AppColors.coralDark,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          const Divider(height: 1, indent: 52),
          _buildAddressTile(user, hasAddress),
        ],
      ),
    );
  }

  Widget _buildAddressTile(dynamic user, bool hasAddress) {
    final addrSummary = _getAddressSummary(user);
    final needsAttention = !hasAddress;

    return InkWell(
      onTap: () => setState(() => _isEditingAddress = !_isEditingAddress),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_on_outlined,
                  size: 20, color: AppColors.blueDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address',
                      style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (needsAttention) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.warningDark,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          addrSummary,
                          style: TextStyle(
                            fontSize: 12,
                            color: needsAttention
                                ? AppColors.warningDark
                                : AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  String _getAddressSummary(dynamic user) {
    final addr = user?['address'];
    if (addr is Map) {
      final parts = <String>[
        if ((addr['flatHouse'] ?? '').isNotEmpty) addr['flatHouse'],
        if ((addr['street'] ?? '').isNotEmpty) addr['street'],
        if ((addr['landmark'] ?? '').isNotEmpty) addr['landmark'],
        if ((addr['city'] ?? '').isNotEmpty) addr['city'],
        if ((addr['state'] ?? '').isNotEmpty) addr['state'],
        if ((addr['zipCode'] ?? '').isNotEmpty) addr['zipCode'],
      ];
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return 'No address set';
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
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
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Support group — Help & support, Privacy policy
  // ---------------------------------------------------------------------------
  Widget _buildSupportGroup() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help and support',
            subtitle: 'FAQs, contact us',
            iconBg: AppColors.coralLight,
            iconColor: AppColors.coralDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support page coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 52),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            subtitle: 'How we handle your data',
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blueDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy policy coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout row — neutral, not danger colored
  // ---------------------------------------------------------------------------
  Widget _buildLogoutRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: _buildSettingsTile(
        icon: Icons.logout_rounded,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        iconBg: AppColors.mutedLight,
        iconColor: AppColors.muted,
        onTap: () => _showLogoutDialog(context),
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
                          Text('Personal Information',
                              style: AppTextStyles.cardTitle),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: AppColors.muted),
                            onPressed: () =>
                                setState(() => _isEditingProfile = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _field(
                          controller: _fullNameController,
                          label: 'Full name',
                          icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _field(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      Consumer<AuthProvider>(
                        builder: (context, provider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  provider.isLoading ? null : _submitProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.coral,
                                disabledBackgroundColor:
                                    AppColors.coral.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.ink, strokeWidth: 2))
                                   : Text('Save',
                                       style: AppTextStyles.buttonPrimary),
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
                          Text('Delivery Address',
                              style: AppTextStyles.cardTitle),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: AppColors.muted),
                            onPressed: () =>
                                setState(() => _isEditingAddress = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _field(
                          controller: _flatController,
                          label: 'Flat / House number',
                          icon: Icons.home_outlined),
                      const SizedBox(height: 12),
                      _field(
                          controller: _streetController,
                          label: 'Street / Area',
                          icon: Icons.route_outlined),
                      const SizedBox(height: 12),
                      _field(
                          controller: _landmarkController,
                          label: 'Landmark (optional)',
                          icon: Icons.flag_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _field(
                                  controller: _cityController,
                                  label: 'City',
                                  icon: Icons.location_city_outlined)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _field(
                                  controller: _stateController,
                                  label: 'State',
                                  icon: Icons.map_outlined)),
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
                              onPressed:
                                  provider.isLoading ? null : _submitAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.coral,
                                disabledBackgroundColor:
                                    AppColors.coral.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.ink, strokeWidth: 2))
                                   : Text('Save Address',
                                       style: AppTextStyles.buttonPrimary),
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
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
      inputFormatters: keyboardType == TextInputType.phone ||
              keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout',
            style: AppTextStyles.sectionHeading),
        content: Text('Are you sure you want to log out?',
            style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: AppTextStyles.bodyMuted),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                  (route) => false);
            },
            child: Text('Logout',
                style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }
}
