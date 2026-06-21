import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<OrderProvider>(context, listen: false).fetchVendorOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading && orderProvider.vendorOrders.isEmpty) {
            return const OrderCardSkeleton();
          }

          if (orderProvider.vendorOrders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Orders from customers will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => orderProvider.fetchVendorOrders(),
            color: AppColors.coral,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.vendorOrders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.vendorOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order['_id'].toString().substring(18).toUpperCase()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                          ),
                          _buildStatusDropdown(order),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order['customerId']['fullName'] ?? 'Customer',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order['customerId']['phone'] ?? '',
                              style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order['shippingAddress'] ?? '',
                              style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 10),
                      ...((order['products'] as List).map((p) {
                        final productData = p['product'];
                        String title = 'Product';
                        if (productData is Map) {
                          title = productData['title'] ?? 'Product';
                        } else if (productData is String) {
                          title = 'Product #${productData.substring(productData.length - 6).toUpperCase()}';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${title} x ${p['quantity']}',
                            style: const TextStyle(fontSize: 13, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (order['notes'] != null && order['notes'].isNotEmpty)
                            Expanded(
                              child: Text(
                                'Note: ${order['notes']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text(
                            'Rs. ${order['totalAmount']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.coral),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDropdown(dynamic order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButton<String>(
        value: order['orderStatus'],
        underline: const SizedBox(),
        isDense: true,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        items: ['Pending', 'Confirmed', 'Delivered', 'Cancelled'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: _getStatusColor(value))),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null && newValue != order['orderStatus']) {
            Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(order['_id'], newValue);
          }
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warningDark;
      case 'Confirmed':
        return AppColors.blueDark;
      case 'Delivered':
        return AppColors.successDark;
      case 'Cancelled':
        return AppColors.coralDark;
      default:
        return AppColors.muted;
    }
  }
}
