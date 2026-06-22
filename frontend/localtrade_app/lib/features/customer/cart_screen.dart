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
import 'checkout_screen.dart';

final _priceFormat = NumberFormat('#,##0');

/// Converts text to sentence case: first letter capitalized, rest lowercase.
String _toSentenceCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

/// Returns up to 2-letter initials from a vendor name for the avatar circle.
String _vendorInitials(String name) {
  if (name.isEmpty) return '?';
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

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
                decoration: const BoxDecoration(
                  color: AppColors.coralLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 36,
                  color: AppColors.coralDark,
                ),
              ),
              const SizedBox(height: 16),
              Text('Login to view your cart', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              Text(
                'Sign in to add items and checkout',
                style: AppTextStyles.bodyMuted,
              ),
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
                      // Vendor group cards
                      ...cart.itemsByVendor.entries.map((entry) {
                        final rawName = entry.value.first.vendorName;
                        final vendorName =
                            rawName.isNotEmpty ? rawName : 'Local vendor';
                        final vendorItems = entry.value;
                        return _VendorGroupCard(
                          vendorName: vendorName,
                          items: vendorItems,
                          cart: cart,
                        );
                      }),

                      // Vendor note card
                      const SizedBox(height: 12),
                      _VendorNoteCard(noteController: _noteController),

                      // Extra space so bottom bar doesn't cover content
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
    const deliveryFee = 0.0;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtotal
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
            const SizedBox(height: 10),
            // Delivery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery', style: AppTextStyles.bodyMuted),
                Text(
                  deliveryFee == 0
                      ? 'Free'
                      : 'Rs. ${_priceFormat.format(deliveryFee.toInt())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        deliveryFee == 0 ? FontWeight.w500 : FontWeight.w400,
                    color:
                        deliveryFee == 0 ? AppColors.success : AppColors.ink,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            // Total — ink text, not coral
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

// ---------------------------------------------------------------------------
// Vendor group card
// ---------------------------------------------------------------------------
class _VendorGroupCard extends StatelessWidget {
  final String vendorName;
  final List<CartItem> items;
  final CartProvider cart;

  const _VendorGroupCard({
    required this.vendorName,
    required this.items,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2B2620), // 5% ink
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor header
          Row(
            children: [
              // Initials circle
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.coralLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _vendorInitials(vendorName),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coralDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pickup from vendor',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          // Items
          ...items.map(
            (item) => _CartItemTile(
              item: item,
              cart: cart,
              onRemove: () => cart.removeItem(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart item tile
// ---------------------------------------------------------------------------
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: CloudinaryHelper.getOptimizedUrl(
                        item.imageUrl,
                        width: 200,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: AppColors.divider),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.divider,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.muted,
                          size: 24,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.divider,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.muted,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (sentence case) + trash icon inline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _toSentenceCase(item.title),
                        style: AppTextStyles.cardTitle.copyWith(height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantity stepper + price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity stepper — coral-light pill, coral-dark icons
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
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
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: AppColors.coralDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
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

// ---------------------------------------------------------------------------
// Vendor note card — separate white card with muted label
// ---------------------------------------------------------------------------
class _VendorNoteCard extends StatelessWidget {
  final TextEditingController noteController;

  const _VendorNoteCard({required this.noteController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2B2620),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note for vendor', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'e.g. ripeness preference, allergies, special request',
              hintStyle: AppTextStyles.caption,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
