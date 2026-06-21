import 'package:flutter/material.dart';
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
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _addressController.text = user?['address'] ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handlePlaceOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final itemsByVendor = cart.itemsByVendor;

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
        'shippingAddress': _addressController.text,
        'phone': user?['phone'],
        'notes': _notesController.text,
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

                  // ── Delivery Address ──
                  _SectionHeader(icon: Icons.location_on_outlined, title: 'Delivery address'),
                  const SizedBox(height: AppSpacing.gapMd),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _addressController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your full delivery address',
                        hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 20),
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
                        hintText: 'e.g. call before delivery, landmarks...',
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
                        // ── Item rows ──
                        ...items.values.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapSm),
                          child: Row(
                            children: [
                              // Thumbnail
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

                              // Title + qty x price
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

                              // Line total
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

                        // ── Subtotal row ──
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

                        // ── Total row ──
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

                  // Extra bottom padding so content isn't hidden behind bottom bar
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
                        // Price display above button
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
                        // Place order button
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
