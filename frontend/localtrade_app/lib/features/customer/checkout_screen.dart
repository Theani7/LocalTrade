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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery details
            const Text('Delivery address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter your full delivery address',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Additional notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. call before delivery, landmarks...',
                prefixIcon: Icon(Icons.note_outlined, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            const Text('Order summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  ...cart.items.values.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text('${item.quantity}x', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.coral)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.title, style: const TextStyle(fontSize: 14, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text('Rs. ${item.price * item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                      Text(
                        'Rs. ${cart.totalAmount}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: Consumer<OrderProvider>(
            builder: (context, order, _) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: order.isLoading ? null : _handlePlaceOrder,
                  child: order.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                      : const Text('Place order'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
