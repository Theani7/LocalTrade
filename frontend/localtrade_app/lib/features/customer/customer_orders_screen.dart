import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      }
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Your Orders', style: AppTextStyles.screenTitle),
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
              Text('Login to view orders', style: AppTextStyles.sectionHeading),
              const SizedBox(height: 8),
              Text('Sign in to see your order history', style: AppTextStyles.bodyMuted),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Orders', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
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
            backgroundColor: AppColors.surface,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.screenPaddingTop,
              ),
              itemCount: orderProvider.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                final orderId = order['_id']?.toString() ?? 'unknown';
                final shortId = orderId.length > 6
                    ? orderId.substring(orderId.length - 6).toUpperCase()
                    : orderId.toUpperCase();
                final products = (order['products'] as List?) ?? [];
                final status = order['orderStatus'] ?? 'Pending';
                final dateStr = order['createdAt'] ?? DateTime.now().toString();
                final date = DateTime.parse(dateStr).toLocal();
                final vendorName =
                    order['vendorId']?['shopName'] ??
                    order['vendorId']?['fullName'] ??
                    'Local vendor';
                final totalAmount = order['totalAmount'] ?? 0;

                // Get first product image for hero thumbnail
                String? heroImage;
                if (products.isNotEmpty) {
                  final firstProduct = products[0]['productId'];
                  if (firstProduct is Map &&
                      firstProduct['images'] != null &&
                      (firstProduct['images'] as List).isNotEmpty) {
                    heroImage = firstProduct['images'][0];
                  }
                }

                // Parse delivery address
                String? deliverySnippet;
                final addr = order['shippingAddress'];
                if (addr is Map) {
                  final city = addr['city'] ?? '';
                  final state = addr['state'] ?? '';
                  if (city.isNotEmpty || state.isNotEmpty) {
                    deliverySnippet = [city, state].where((s) => s.isNotEmpty).join(', ');
                  }
                }

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: orderId),
                    ),
                  ),
                  child: Container(
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
                        // Header: Order ID + status + time
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              // Order ID chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.mutedLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
          '#$shortId',
          style: AppTextStyles.label.copyWith(color: AppColors.muted),
        ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeAgo(date),
                                style: AppTextStyles.caption,
                              ),
                              const Spacer(),
                              _buildStatusBadge(status),
                            ],
                          ),
                        ),

                        // Product row with hero image
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // Hero product image
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.mutedLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  image: heroImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(heroImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: heroImage == null
                                    ? const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.muted)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Product info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorName,
                                      style: AppTextStyles.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${products.length} item${products.length == 1 ? '' : 's'}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              // Total + chevron
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. $totalAmount',
                                    style: AppTextStyles.cardTitle.copyWith(color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Delivery address snippet
                        if (deliverySnippet != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    deliverySnippet,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          const SizedBox(height: 12),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'Pending':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        icon = Icons.schedule_rounded;
        label = 'Pending';
        break;
      case 'Confirmed':
        bgColor = AppColors.blueLight;
        textColor = AppColors.blueDark;
        icon = Icons.check_rounded;
        label = 'Confirmed';
        break;
      case 'Delivered':
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        icon = Icons.check_circle_outline_rounded;
        label = 'Delivered';
        break;
      case 'Cancelled':
        bgColor = AppColors.coralLight;
        textColor = AppColors.coralDark;
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      default:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        icon = Icons.schedule_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
