import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/utils/auth_guard.dart';
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
          title: const Text(
            'Cart',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 16),
              const Text('Login to view your cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text('Sign in to add items and checkout', style: TextStyle(fontSize: 13, color: AppColors.muted)),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    children: [
                      // Grouped by vendor
                      ...cart.itemsByVendor.entries.map((entry) {
                        final vendorName = entry.value.first.vendorName.isNotEmpty
                            ? entry.value.first.vendorName
                            : 'Vendor';
                        final vendorItems = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vendor header
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.storefront_rounded,
                                      size: 16, color: AppColors.coralDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    vendorName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${vendorItems.length} item${vendorItems.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: AppColors.divider, height: 1),
                            // Items
                            ...vendorItems.map((item) => _CartItemTile(
                                  item: item,
                                  cart: cart,
                                  onRemove: () => cart.removeItem(item.id),
                                )),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),

                      // Order summary section
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
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
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Delivery/Pickup row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.coralLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.store_rounded,
                                      size: 18, color: AppColors.coralDark),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pickup from vendor',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          'Items will be ready for pickup',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Note field
                            TextField(
                              controller: _noteController,
                              maxLines: 2,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.ink),
                              decoration: InputDecoration(
                                hintText: 'Add a note for the vendor (optional)',
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: AppColors.muted),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 36, color: AppColors.coral),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items to get started',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse products',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final cartItems = cart.items.values.toList();
    final totalQty = cartItems.fold<int>(0, (s, i) => s + i.quantity);
    final subtotal = cart.totalAmount;
    final deliveryFee = 0.0;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            // Subtotal row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($totalQty item${totalQty == 1 ? '' : 's'})',
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                Text(
                  'Rs. ${_priceFormat.format(subtotal.toInt())}',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.ink),
                ),
              ],
            ),
            // Delivery row
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
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
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink),
                ),
                Text(
                  'Rs. ${_priceFormat.format(total.toInt())}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Checkout',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
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
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: CloudinaryHelper.getOptimizedUrl(
                          item.imageUrl,
                          width: 200),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.divider),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.inventory_2_outlined,
                            color: AppColors.muted, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.divider,
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.muted, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + remove button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                if (item.vendorName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.vendorName,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 8),
                // Quantity + price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity controls
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.quantity > 1) {
                                cart.updateQuantity(
                                    item.id, item.quantity - 1);
                              } else {
                                onRemove();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                item.quantity > 1
                                    ? Icons.remove_rounded
                                    : Icons.delete_outline_rounded,
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
                            onTap: () => cart.updateQuantity(
                                item.id, item.quantity + 1),
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.add_rounded,
                                  size: 16, color: AppColors.coralDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Text(
                      'Rs. ${_priceFormat.format((item.price * item.quantity).toInt())}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
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
}
