import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_guard.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();

  // Editable address fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  bool _isEditingAddress = false;
  bool _addressLoaded = false;

  void _loadAddressFromUser(Map<String, dynamic>? user) {
    if (user == null) return;

    _nameController.text = user['fullName'] ?? '';
    _phoneController.text = user['phone'] ?? '';

    final addr = user['address'];
    if (addr is Map && (addr['city'] ?? '').toString().isNotEmpty) {
      _flatController.text = addr['flatHouse'] ?? '';
      _streetController.text = addr['street'] ?? '';
      _landmarkController.text = addr['landmark'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _zipController.text = addr['zipCode'] ?? '';
    }

    _addressLoaded = true;
  }

  bool _hasSavedAddress(Map<String, dynamic>? user) {
    if (user == null) return false;
    final addr = user['address'];
    if (addr is Map && (addr['city'] ?? '').toString().isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _handlePlaceOrder() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(_phoneController.text.trim())) {
      _showError('Phone number must contain only digits');
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showError('Please enter your city');
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _showError('Please enter your state');
      return;
    }
    if (_zipController.text.trim().isEmpty) {
      _showError('Please enter your zip code');
      return;
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(_zipController.text.trim())) {
      _showError('Zip code must be 4-6 digits');
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final itemsByVendor = cart.itemsByVendor;

    final shippingAddress = {
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'flatHouse': _flatController.text.trim(),
      'street': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zipCode': _zipController.text.trim(),
    };

    bool allSuccess = true;

    for (var entry in itemsByVendor.entries) {
      final vendorId = entry.key;
      final items = entry.value;
      final total = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

      final success = await orderProvider.placeOrder({
        'vendorId': vendorId,
        'items': items.map((i) => {
          'productId': i.id,
          'quantity': i.quantity,
          'price': i.price,
        }).toList(),
        'totalAmount': total,
        'shippingAddress': shippingAddress,
        'phone': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
      });

      if (!success) allSuccess = false;
    }

    if (allSuccess && mounted) {
      cart.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place orders'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 16),
              const Text('Login to checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text('Sign in to place your order', style: TextStyle(fontSize: 13, color: AppColors.muted)),
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

    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;
    final user = Provider.of<AuthProvider>(context).user;
    final hasAddress = _hasSavedAddress(user);

    // Load address controllers from user data (once or when user changes)
    if (!_addressLoaded || !_isEditingAddress) {
      _loadAddressFromUser(user);
    }

    // If address exists and we're not editing, show read-only
    final bool showAddressForm = _isEditingAddress || !hasAddress;
    final bool showNoAddressCard = !hasAddress && !_isEditingAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.gapLg),

                  // ── Delivery Address ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(icon: Icons.location_on_outlined, title: 'Delivery address'),
                      if (hasAddress && !_isEditingAddress)
                        TextButton.icon(
                          onPressed: () => setState(() => _isEditingAddress = true),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.coral),
                          label: const Text('Edit', style: TextStyle(fontSize: 13, color: AppColors.coral)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gapMd),

                  if (showNoAddressCard)
                    _buildNoAddressCard()
                  else if (showAddressForm)
                    _buildAddressForm()
                  else
                    _buildAddressDisplay(),

                  const SizedBox(height: AppSpacing.gapXl + 2),

                  // ── Additional Notes ──
                  _SectionHeader(icon: Icons.notes_rounded, title: 'Additional notes'),
                  const SizedBox(height: AppSpacing.gapMd),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. call before delivery...',
                        hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.muted, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.cardPaddingMd,
                          vertical: AppSpacing.cardPaddingMd,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.gapXl + 2),

                  // ── Order Summary ──
                  _SectionHeader(icon: Icons.receipt_long_outlined, title: 'Order summary'),
                  const SizedBox(height: AppSpacing.gapMd),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...items.values.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapSm),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.mutedLight,
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: AppColors.muted, size: 22))
                                      : const Icon(Icons.shopping_bag_outlined, color: AppColors.muted, size: 22),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.gapLg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text('${item.quantity} x Rs. ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Text('Rs. ${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                            ],
                          ),
                        )),
                        const SizedBox(height: AppSpacing.gapSm),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.gapSm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                              Text('Rs. ${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.gapMd),
                          child: Divider(color: AppColors.divider, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            Text('Rs. ${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.coral)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Bottom bar ──
          Container(
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.divider))),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPaddingH, AppSpacing.gapMd, AppSpacing.screenPaddingH, AppSpacing.gapLg),
                child: Consumer<OrderProvider>(
                  builder: (context, order, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.gapMd),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Order total', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              Text('Rs. ${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.buttonHeightPrimary,
                          child: ElevatedButton(
                            onPressed: (order.isLoading || _isEditingAddress || !hasAddress) ? null : _handlePlaceOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: AppColors.ink,
                              disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                              elevation: 0,
                            ),
                            child: order.isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                                : Text(
                                    !hasAddress ? 'Add address first' : (_isEditingAddress ? 'Save address first' : 'Place order'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 40, color: AppColors.muted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('No delivery address saved', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            'Add a delivery address in your profile before placing an order.',
            style: TextStyle(fontSize: 13, color: AppColors.muted.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen()));
              // After returning from profile, re-read user data
              setState(() {
                _addressLoaded = false;
              });
            },
            icon: const Icon(Icons.add_location_alt_outlined, size: 18, color: AppColors.coral),
            label: const Text('Add address in profile', style: TextStyle(fontSize: 13, color: AppColors.coral)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.coral),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(_nameController.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('+977 ${_phoneController.text}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.coral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatAddress(),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAddress() {
    final parts = <String>[
      if (_flatController.text.isNotEmpty) _flatController.text,
      if (_streetController.text.isNotEmpty) _streetController.text,
      if (_landmarkController.text.isNotEmpty) 'Landmark: ${_landmarkController.text}',
      if (_cityController.text.isNotEmpty) _cityController.text,
      if (_stateController.text.isNotEmpty) _stateController.text,
      if (_zipController.text.isNotEmpty) _zipController.text,
    ];
    return parts.join(', ');
  }

  Widget _buildAddressForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              if (_hasSavedAddress(Provider.of<AuthProvider>(context, listen: false).user))
                TextButton(
                  onPressed: () => setState(() => _isEditingAddress = false),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _field(controller: _flatController, label: 'Flat / House number', icon: Icons.home_outlined),
          const SizedBox(height: 10),
          _field(controller: _streetController, label: 'Street / Area', icon: Icons.route_outlined),
          const SizedBox(height: 10),
          _field(controller: _landmarkController, label: 'Landmark (optional)', icon: Icons.flag_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(controller: _cityController, label: 'City', icon: Icons.location_city_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _field(controller: _stateController, label: 'State', icon: Icons.map_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            controller: _zipController,
            label: 'Zip code',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.ink, fontSize: 14),
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPaddingMd, vertical: AppSpacing.cardPaddingMd),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.coral),
        const SizedBox(width: AppSpacing.gapSm),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }
}
