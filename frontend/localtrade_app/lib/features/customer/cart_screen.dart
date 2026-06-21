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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My cart'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Start browsing to add products.',
              onAction: () => Navigator.pop(context),
              actionLabel: 'Browse products',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: [
                            BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: Container(
                                width: 72,
                                height: 72,
                                color: AppColors.background,
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(item.imageUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 28),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rs. ${item.price}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.coral),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity + remove
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _qtyBtn(Icons.remove_rounded, () => cart.updateQuantity(item.id, item.quantity - 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                    ),
                                    _qtyBtn(Icons.add_rounded, () => cart.updateQuantity(item.id, item.quantity + 1)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => cart.removeItem(item.id),
                                  child: const Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                            Text(
                              'Rs. ${cart.totalAmount}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                            child: const Text('Proceed to checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.coralLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.coralDark),
      ),
    );
  }
}
