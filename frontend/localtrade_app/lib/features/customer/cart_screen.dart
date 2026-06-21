import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();
    final totalQuantity =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Shopping Cart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            if (cartItems.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalQuantity',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.coralDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: cartItems.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Looks like you haven\'t added anything yet.',
              onAction: () => Navigator.pop(context),
              actionLabel: 'Browse products',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH,
                        vertical: AppSpacing.screenPaddingTop),
                    itemCount: cartItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSubtotalBar(totalQuantity, cart.totalAmount);
                      }
                      final item = cartItems[index - 1];
                      return _buildCartItem(context, item, cart);
                    },
                  ),
                ),
                _buildCheckoutBar(context, cart),
              ],
            ),
    );
  }

  Widget _buildSubtotalBar(int totalQuantity, double totalAmount) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gapSm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPaddingMd,
          vertical: AppSpacing.gapMd),
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
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 18, color: AppColors.muted),
          const SizedBox(width: AppSpacing.gapSm),
          Text(
            'Subtotal ($totalQuantity item${totalQuantity == 1 ? '' : 's'}):',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
          const Spacer(),
          Text(
            'Rs. ${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gapSm),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.background,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.inventory_2_outlined,
                          color: AppColors.muted, size: 28),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.vendorName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.vendorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gapLg),
          Row(
            children: [
              _buildQuantitySelector(cart, item),
              const Spacer(),
              _buildTextButton(
                label: 'Remove',
                color: AppColors.danger,
                onTap: () => cart.removeItem(item.id),
              ),
              const SizedBox(width: AppSpacing.gapLg),
              _buildTextButton(
                label: 'Save for later',
                color: AppColors.muted,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Save for later coming soon'),
                      backgroundColor: AppColors.ink,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(CartProvider cart, CartItem item) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(
            icon: Icons.remove,
            onTap: () {
              if (item.quantity > 1) {
                cart.updateQuantity(item.id, item.quantity - 1);
              } else {
                cart.removeItem(item.id);
              }
            },
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          _qtyButton(
            icon: Icons.add,
            onTap: () => cart.updateQuantity(item.id, item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.coralDark),
      ),
    );
  }

  Widget _buildTextButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH, AppSpacing.gapXl, AppSpacing.screenPaddingH, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeightPrimary,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: AppColors.ink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Text(
              'Proceed to checkout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
