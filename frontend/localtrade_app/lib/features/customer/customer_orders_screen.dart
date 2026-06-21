import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/status_badge.dart';
import 'order_tracking_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<OrderProvider>(context, listen: false).fetchMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My orders'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const OrderCardSkeleton();
          }

          if (orderProvider.orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Place your first order to see it here.',
              onAction: () => Navigator.pop(context),
              actionLabel: 'Browse products',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => orderProvider.fetchMyOrders(),
            color: AppColors.coral,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                final orderId = order['_id']?.toString() ?? 'unknown';
                final displayId = orderId.length > 18 ? orderId.substring(18).toUpperCase() : orderId.toUpperCase();

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
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
                              '#$displayId',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                            ),
                            StatusBadge(status: _mapStatus(order['orderStatus'] ?? 'Pending')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.coralLight,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.coralDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['vendorId']?['shopName'] ?? order['vendorId']?['fullName'] ?? 'Local vendor',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(order['products'] as List?)?.length ?? 0} items  •  Rs. ${order['totalAmount'] ?? 0}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, yyyy').format(DateTime.parse(order['createdAt'] ?? DateTime.now().toString()).toLocal()),
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  BadgeStatus _mapStatus(String status) {
    switch (status) {
      case 'Pending':
        return BadgeStatus.pending;
      case 'Confirmed':
        return BadgeStatus.confirmed;
      case 'Delivered':
        return BadgeStatus.delivered;
      case 'Cancelled':
        return BadgeStatus.rejected;
      default:
        return BadgeStatus.pending;
    }
  }
}
