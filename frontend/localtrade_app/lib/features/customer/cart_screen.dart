import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_header.dart';
import 'checkout_screen.dart';

final _priceFormat = NumberFormat('#,##0');

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AuthGuard.isAuthenticated(context);

    if (!isAuth) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Cart', style: AppTextStyles.screenTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.coralDark),
              ),
              const SizedBox(height: 16),
              Text('Login to view your cart', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              Text('Sign in to add items and checkout', style: AppTextStyles.bodyMuted),
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

    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();
    final totalQty = cartItems.fold<int>(0, (s, i) => s + i.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          cartItems.isEmpty ? 'Cart' : 'Cart ($totalQty)',
          style: AppTextStyles.screenTitle,
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      ...cart.itemsByVendor.entries.map((entry) {
                        final vendorName = entry.value.first.vendorName.isNotEmpty
                            ? entry.value.first.vendorName
                            : 'Vendor';
                        final vendorItems = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: SectionHeader(
                                title: vendorName,
                                subtitle: '${vendorItems.length} item${vendorItems.length == 1 ? '' : 's'}',
                                tone: SectionTone.warm,
                              ),
                            ),
                            const Divider(color: AppColors.divider, height: 1),
                            ...vendorItems.map((item) => _CartItemTile(
                                  item: item,
                                  cart: cart,
                                  onRemove: () => cart.removeItem(item.id),
                                )),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),

                      const SizedBox(height: 8),
                      _OrderSummaryCard(noteController: _noteController),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                _buildBottomBar(context, cart),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'Your cart is empty',
      message: 'Add items to get started',
      onAction: () => Navigator.pop(context),
      actionLabel: 'Browse products',
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final cartItems = cart.items.values.toList();
    final totalQty = cartItems.fold<int>(0, (s, i) => s + i.quantity);
    final subtotal = cart.totalAmount;
    final deliveryFee = 0.0;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($totalQty item${totalQty == 1 ? '' : 's'})',
                  style: AppTextStyles.bodyMuted,
                ),
                Text(
                  'Rs. ${_priceFormat.format(subtotal.toInt())}',
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery', style: AppTextStyles.bodyMuted),
                Text(
                  deliveryFee == 0 ? 'Free' : 'Rs. ${_priceFormat.format(deliveryFee.toInt())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: deliveryFee == 0 ? FontWeight.w500 : FontWeight.w400,
                    color: deliveryFee == 0 ? AppColors.success : AppColors.ink,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.cardTitle),
                Text(
                  'Rs. ${_priceFormat.format(total.toInt())}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Checkout',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final TextEditingController noteController;

  const _OrderSummaryCard({required this.noteController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order summary', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Row(
              children: [
                Icon(Icons.store_rounded, size: 18, color: AppColors.coralDark),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup from vendor',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                      Text(
                        'Items will be ready for pickup',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Add a note for the vendor (optional)',
              hintStyle: AppTextStyles.bodyMuted,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.cart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: CloudinaryHelper.getOptimizedUrl(item.imageUrl, width: 200),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.divider),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.divider,
                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.cardTitle.copyWith(height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
                    ),
                  ],
                ),
                if (item.vendorName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.vendorName, style: AppTextStyles.caption),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.quantity > 1) {
                                cart.updateQuantity(item.id, item.quantity - 1);
                              } else {
                                onRemove();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                item.quantity > 1 ? Icons.remove_rounded : Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.coralDark,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => cart.updateQuantity(item.id, item.quantity + 1),
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.add_rounded, size: 16, color: AppColors.coralDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${_priceFormat.format((item.price * item.quantity).toInt())}',
                      style: AppTextStyles.cardTitle,
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
}
