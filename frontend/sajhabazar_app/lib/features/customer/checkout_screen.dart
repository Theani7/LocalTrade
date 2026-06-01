import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
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

  void _handlePlaceOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter delivery address'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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

      // Construct payload with 'items' key as primary expectation
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
        SnackBar(
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Order placed successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place orders'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                boxShadow: AppTheme.softShadow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Enter your full delivery address',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Additional Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                boxShadow: AppTheme.softShadow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'E.g. Call before delivery, Landmark etc.',
                  prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.secondaryColor),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 32),
            const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  ...cart.items.values.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Rs. ${item.price * item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                      Flexible(
                        child: Text(
                          'Rs. ${cart.totalAmount}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer<OrderProvider>(
            builder: (context, order, _) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: order.isLoading ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: order.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                  label: Text(
                    order.isLoading ? 'Processing...' : 'Confirm & Place Order',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
