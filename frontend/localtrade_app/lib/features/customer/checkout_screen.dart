import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'customer_orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user['fullName'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      // Try to pre-fill city/state from legacy address string
      final addr = user['address'] ?? '';
      if (addr.isNotEmpty && _cityController.text.isEmpty) {
        // Best-effort: just leave blank for now
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
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
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
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

                  // ── Recipient Info ──
                  _SectionHeader(icon: Icons.person_outline, title: 'Recipient'),
                  const SizedBox(height: AppSpacing.gapMd),
                  _field(controller: _nameController, label: 'Full name', icon: Icons.person_outline),
                  const SizedBox(height: 10),
                  _field(
                    controller: _phoneController,
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    prefix: '+977 ',
                  ),

                  const SizedBox(height: AppSpacing.gapXl + 2),

                  // ── Delivery Address ──
                  _SectionHeader(icon: Icons.location_on_outlined, title: 'Delivery address'),
                  const SizedBox(height: AppSpacing.gapMd),
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
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
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
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: AppColors.muted,
                                            size: 22,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: AppColors.muted,
                                          size: 22,
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.gapLg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantity} x Rs. ${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        )),

                        const SizedBox(height: AppSpacing.gapSm),

                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.gapSm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(fontSize: 13, color: AppColors.muted),
                              ),
                              Text(
                                'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              ),
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
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.coral,
                              ),
                            ),
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
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.gapMd,
                  AppSpacing.screenPaddingH,
                  AppSpacing.gapLg,
                ),
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
                              const Text(
                                'Order total',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.buttonHeightPrimary,
                          child: ElevatedButton(
                            onPressed: order.isLoading ? null : _handlePlaceOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: AppColors.ink,
                              disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              elevation: 0,
                            ),
                            child: order.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.ink,
                                    ),
                                  )
                                : const Text(
                                    'Place order',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefix,
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
        inputFormatters: prefix != null ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: AppColors.ink, fontSize: 14),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
