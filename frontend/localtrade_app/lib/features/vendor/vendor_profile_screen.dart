import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../providers/vendor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/change_password_screen.dart';
import '../common/logout_dialog.dart';

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
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _descriptionController;
  late TextEditingController _hoursController;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();
  List<String> _selectedCategories = [];
  final Set<String> _editingFields = {};
  bool _hasChanges = false;
  Map<String, dynamic> _savedValues = {};

  final List<String> _allCategories = [
    'Vegetables',
    'Dairy',
    'Handicrafts',
    'Clothing',
    'Local Goods',
    'Tailoring',
    'Groceries',
    'Bakery',
    'Meat',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<VendorProvider>(context, listen: false).profile;

    _fullNameController =
        TextEditingController(text: profile?['fullName'] ?? '');
    _shopNameController =
        TextEditingController(text: profile?['shopName'] ?? '');
    _phoneController =
        TextEditingController(text: profile?['phone'] ?? '');
    final rawAddr = profile?['address'];
    _streetController = TextEditingController(
        text: (rawAddr is Map) ? (rawAddr['street'] ?? '') : '');
    _cityController = TextEditingController(
        text: (rawAddr is Map) ? (rawAddr['city'] ?? '') : '');
    _stateController = TextEditingController(
        text: (rawAddr is Map) ? (rawAddr['state'] ?? '') : '');
    _zipController = TextEditingController(
        text: (rawAddr is Map) ? (rawAddr['zipCode'] ?? '') : '');
    _descriptionController =
        TextEditingController(text: profile?['businessDescription'] ?? '');
    _hoursController = TextEditingController(
        text: profile?['openingHours'] ?? '9:00 AM - 6:00 PM');

    if (profile?['categories'] != null) {
      _selectedCategories = List<String>.from(profile!['categories']);
    }

    _snapshotValues();
  }

  void _snapshotValues() {
    _savedValues = {
      'fullName': _fullNameController.text,
      'shopName': _shopNameController.text,
      'phone': _phoneController.text,
      'street': _streetController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zip': _zipController.text,
      'description': _descriptionController.text,
      'hours': _hoursController.text,
      'categories': List<String>.from(_selectedCategories),
      'imageFile': null,
    };
  }

  void _checkChanges() {
    final current = {
      'fullName': _fullNameController.text,
      'shopName': _shopNameController.text,
      'phone': _phoneController.text,
      'street': _streetController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zip': _zipController.text,
      'description': _descriptionController.text,
      'hours': _hoursController.text,
      'categories': _selectedCategories,
    };
    final hasFieldChanges = current.keys.any(
      (k) => current[k] is List
          ? !_listEquals(current[k] as List, _savedValues[k])
          : current[k] != _savedValues[k],
    );
    final changed = hasFieldChanges || _imageFile != null;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  bool _listEquals(List a, dynamic b) {
    if (b is! List) return true;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
      _checkChanges();
    }
  }

  void _toggleEdit(String field) {
    setState(() {
      final addressFields = {'street', 'city', 'state', 'zip'};
      if (addressFields.contains(field)) {
        if (_editingFields.contains('street')) {
          _editingFields.removeAll(addressFields);
        } else {
          _editingFields.addAll(addressFields);
        }
      } else {
        if (_editingFields.contains(field)) {
          _editingFields.remove(field);
        } else {
          _editingFields.add(field);
        }
      }
    });
    _checkChanges();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _zipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All address fields are required'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      setState(() => _editingFields.addAll({'street', 'city', 'state', 'zip'}));
      return;
    }

    final provider =
        Provider.of<VendorProvider>(context, listen: false);

    final Map<String, String> fields = {
      'fullName': _fullNameController.text.trim(),
      'shopName': _shopNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': jsonEncode({
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipController.text.trim(),
      }),
      'businessDescription': _descriptionController.text.trim(),
      'openingHours': _hoursController.text.trim(),
      'categories': json.encode(_selectedCategories),
    };

    final success = await provider.updateProfile(fields, image: _imageFile);

    if (mounted && success) {
      _snapshotValues();
      setState(() {
        _hasChanges = false;
        _imageFile = null;
        _imageBytes = null;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Profile updated successfully'
              : (provider.error ?? 'Update failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<VendorProvider>(context).profile;
    final approvalStatus =
        Provider.of<AuthProvider>(context).user?['vendorApprovalStatus'] ??
            'pending';
    final shopName = profile?['shopName'] ?? 'Your store';

    final canGoBack = Navigator.canPop(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_hasChanges) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Unsaved changes', style: AppTextStyles.sectionHeading),
            content: Text(
              'You have unsaved changes. Discard?',
              style: AppTextStyles.bodyMuted,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.bodyMuted),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Discard', style: AppTextStyles.buttonPrimary),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Form(
      key: _formKey,
      child: Column(
        children: [
          _buildHeader(canGoBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreIdentityCard(profile, approvalStatus, shopName),
                  const SizedBox(height: 14),
                  _buildSectionLabel('OWNER INFORMATION'),
                  _buildSectionCard([
                    _buildFieldRow(
                      field: 'fullName',
                      label: 'Full name',
                      required: true,
                      icon: Icons.person_outline_rounded,
                      iconBg: AppColors.coralLight,
                      iconColor: AppColors.coralDark,
                      controller: _fullNameController,
                    ),
                    _buildFieldRow(
                      field: 'phone',
                      label: 'Phone number',
                      required: true,
                      icon: Icons.phone_outlined,
                      iconBg: AppColors.blueLight,
                      iconColor: AppColors.blueDark,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionLabel('BUSINESS DETAILS'),
                  _buildSectionCard([
                    _buildFieldRow(
                      field: 'shopName',
                      label: 'Shop name',
                      required: true,
                      icon: Icons.storefront_rounded,
                      iconBg: AppColors.coralLight,
                      iconColor: AppColors.coralDark,
                      controller: _shopNameController,
                      placeholder: "e.g. Maya's Dairy, Hari Crafts",
                    ),
                    _buildFieldRow(
                      field: 'street',
                      label: 'Street / Area',
                      required: true,
                      icon: Icons.signpost_outlined,
                      iconBg: AppColors.blueLight,
                      iconColor: AppColors.blueDark,
                      controller: _streetController,
                    ),
                    _buildFieldRow(
                      field: 'city',
                      label: 'City',
                      required: true,
                      icon: Icons.location_city_outlined,
                      iconBg: AppColors.coralLight,
                      iconColor: AppColors.coralDark,
                      controller: _cityController,
                    ),
                    _buildAddressRowPair(),
                    _buildFieldRow(
                      field: 'hours',
                      label: 'Opening hours',
                      required: false,
                      icon: Icons.access_time_rounded,
                      iconBg: AppColors.coralLight,
                      iconColor: AppColors.coralDark,
                      controller: _hoursController,
                    ),
                    _buildDescriptionRow(),
                    _buildCategoriesRow(),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoBanner(),
                  const SizedBox(height: 16),
                  _buildChangePasswordSection(),
                  const SizedBox(height: 16),
                  _buildLogoutSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildStickySaveBar(),
        ],
      ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(bool canGoBack) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          if (canGoBack) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vendor profile', style: AppTextStyles.screenTitle),
                const SizedBox(height: 2),
                Text(
                  'How customers see your store',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Store identity card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStoreIdentityCard(
      Map<String, dynamic>? profile, String approvalStatus, String shopName) {
    final bool isApproved = approvalStatus == 'approved';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.coralLight,
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
                            fit: BoxFit.cover)
                        : (profile?['profileImage'] != null &&
                                (profile!['profileImage'] as String).isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(profile['profileImage']),
                                fit: BoxFit.cover)
                            : null,
                  ),
                  child: (_imageBytes == null &&
                          (profile?['profileImage'] == null ||
                              (profile?['profileImage'] as String).isEmpty))
                      ? const Icon(Icons.store_rounded,
                          size: 28, color: AppColors.coralDark)
                      : null,
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 11, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the icon to add a store photo',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved ? AppColors.successLight : AppColors.blueLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_outline_rounded
                            : Icons.access_time_rounded,
                        size: 11,
                        color: isApproved ? AppColors.successDark : AppColors.blueDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Approved' : 'Pending approval',
                        style: AppTextStyles.badge.copyWith(
                          color: isApproved ? AppColors.successDark : AppColors.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section helpers
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Address row pair (State + ZIP side by side)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAddressRowPair() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactField(
              field: 'state',
              label: 'State',
              required: true,
              icon: Icons.map_outlined,
              iconBg: AppColors.blueLight,
              iconColor: AppColors.blueDark,
              controller: _stateController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactField(
              field: 'zip',
              label: 'ZIP code',
              required: true,
              icon: Icons.pin_drop_outlined,
              iconBg: AppColors.coralLight,
              iconColor: AppColors.coralDark,
              controller: _zipController,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Compact field (for address pair)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompactField({
    required String field,
    required String label,
    required bool required,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final isEditing = _editingFields.contains(field);
    final hasValue = controller.text.isNotEmpty;

    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: AppTextStyles.label.copyWith(
                color: required ? AppColors.coralDark : AppColors.muted,
              ),
              children: required
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.coralDark)),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.coral, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _toggleEdit(field),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _toggleEdit(field),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: AppTextStyles.label.copyWith(
                color: required ? AppColors.coralDark : AppColors.muted,
              ),
              children: required
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.coralDark)),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasValue ? controller.text : label,
            style: AppTextStyles.body.copyWith(
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              color: hasValue ? AppColors.ink : AppColors.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Standard field row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFieldRow({
    required String field,
    required String label,
    required bool required,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    final isEditing = _editingFields.contains(field);
    final hasValue = controller.text.isNotEmpty;
    final isLast = field == 'hours';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
      child: isEditing
          ? _buildEditingField(
              controller: controller,
              label: label,
              required: required,
              icon: icon,
              iconBg: iconBg,
              iconColor: iconColor,
              keyboardType: keyboardType,
              onDone: () => _toggleEdit(field),
            )
          : GestureDetector(
              onTap: () => _toggleEdit(field),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 15, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: label,
                            style: AppTextStyles.label.copyWith(
                              color: required ? AppColors.coralDark : AppColors.muted,
                            ),
                            children: required
                                ? [
                                    const TextSpan(
                                      text: ' *',
                                      style: TextStyle(color: AppColors.coralDark),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasValue ? controller.text : (placeholder ?? ''),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                            color: hasValue ? AppColors.ink : AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, size: 14, color: AppColors.divider),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Editing field (inline text field with green check)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEditingField({
    required TextEditingController controller,
    required String label,
    required bool required,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onDone,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: label,
                  style: AppTextStyles.label.copyWith(
                    color: required ? AppColors.coralDark : AppColors.muted,
                  ),
                  children: required
                      ? [
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.coralDark),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 36,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: keyboardType,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onDone(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDone,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, size: 14, color: AppColors.successDark),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Description row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDescriptionRow() {
    const field = 'description';
    final isEditing = _editingFields.contains(field);
    final hasValue = _descriptionController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: isEditing
          ? _buildEditingDescription()
          : GestureDetector(
              onTap: () => _toggleEdit(field),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.description_outlined,
                        size: 15, color: AppColors.blueDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasValue
                              ? _descriptionController.text
                              : 'Tell customers what you sell and what makes your store special...',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                            color: hasValue ? AppColors.ink : AppColors.muted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.divider),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditingDescription() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.description_outlined,
              size: 15, color: AppColors.blueDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _descriptionController,
                autofocus: true,
                maxLines: 3,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.coral, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _toggleEdit('description'),
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded,
                size: 14, color: AppColors.successDark),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Categories row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoriesRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.tag, size: 15, color: AppColors.coralDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Categories',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.coralDark,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.coralDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._selectedCategories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.coralDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategories.remove(cat);
                                  });
                                  _checkChanges();
                                },
                                child: Icon(Icons.close_rounded,
                                    size: 12, color: AppColors.coralDark),
                              ),
                            ],
                          ),
                        )),
                    GestureDetector(
                      onTap: () => _showCategoryPickerDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 2),
                            Text(
                              'Add',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPickerDialog() {
    final available =
        _allCategories.where((c) => !_selectedCategories.contains(c)).toList();

    if (available.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add category', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 12),
            ...available.map((cat) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(cat, style: AppTextStyles.body),
                  trailing: const Icon(Icons.add_rounded,
                      color: AppColors.coral, size: 20),
                  onTap: () {
                    setState(() {
                      _selectedCategories.add(cat);
                    });
                    _checkChanges();
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Change password section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildChangePasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.blueDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change password', style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        'Update your password',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Logout section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLogoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.mutedLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, size: 20, color: AppColors.muted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logout', style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        'Sign out of your account',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    LogoutDialog.show(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Info banner + Save bar
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.blueDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Changes to your profile will be reviewed by the admin before going live to customers.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.blueDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickySaveBar() {
    if (!_hasChanges) return const SizedBox.shrink();
    return Consumer<VendorProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.ink, strokeWidth: 2))
                  : Text(
                      'Save changes',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
            ),
          ),
        );
      },
    );
  }
}
