import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../core/utils/app_animations.dart';
import 'order_tracking_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CustomerOrdersScreen — full-screen push route
// ═════════════════════════════════════════════════════════════════════════════
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Orders', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      body: const CustomerOrdersBody(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CustomerOrdersBody — reusable content widget (used by CustomerShell)
// ═════════════════════════════════════════════════════════════════════════════
class CustomerOrdersBody extends StatefulWidget {
  const CustomerOrdersBody({super.key});

  @override
  State<CustomerOrdersBody> createState() => _CustomerOrdersBodyState();
}

class _CustomerOrdersBodyState extends State<CustomerOrdersBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      }
    });
  }

  String _getEta(String status, DateTime orderDate) {
    switch (status) {
      case 'Pending':
        // ETA: 1-2 days from order
        final eta = orderDate.add(const Duration(days: 2));
        if (DateTime.now().isAfter(eta)) {
          return 'Arriving today';
        }
        final diff = eta.difference(DateTime.now());
        if (diff.inHours < 24) {
          return 'Expected in ${diff.inHours}h';
        }
        return 'Expected ${DateFormat('MMM d').format(eta)}';
      case 'Confirmed':
        // ETA: next day
        final eta = orderDate.add(const Duration(days: 1));
        if (DateTime.now().isAfter(eta)) {
          return 'Arriving today';
        }
        return 'Expected ${DateFormat('MMM d').format(eta)}';
      case 'Delivered':
        return 'Delivered';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  IconData _getEtaIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_rounded;
      case 'Confirmed':
        return Icons.storefront_outlined;
      case 'Delivered':
        return Icons.check_circle_outline_rounded;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color _getEtaColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated(context)) {
      return Center(
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
      );
    }

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final orderCount = orderProvider.orders.length;

        return Column(
          children: [
            // Orders header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Orders', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$orderCount order${orderCount == 1 ? '' : 's'} placed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orders list
            Expanded(
              child: _buildOrderList(context, orderProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderList(BuildContext context, OrderProvider orderProvider) {
    if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
      return const OrderCardSkeleton();
    }

    if (orderProvider.orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Place your first order to see it here.',
        onAction: () {},
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

                // Extract product names with units
                final productNames = <String>[];
                String? firstQtyUnit;
                for (final p in products) {
                  final productData = p['product'];
                  final title = productData is Map ? (productData['title'] ?? '') : '';
                  final qty = p['quantity'] ?? 1;
                  final pUnit = p['priceUnit'] ?? 'piece';
                  final uLabel = _unitLabel(pUnit);
                  if (title.isNotEmpty) productNames.add(title);
                  if (firstQtyUnit == null && qty > 0) {
                    firstQtyUnit = '${qty.toInt()}${uLabel.isNotEmpty ? ' $uLabel' : ''}';
                  }
                }

                // Get first product image
                String? heroImage;
                if (products.isNotEmpty) {
                  final firstProduct = products[0]['product'];
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

                final eta = _getEta(status, date);
                final etaColor = _getEtaColor(status);

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    SlideFadePageRoute(
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
                        // ── Header: Order ID + Status ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
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
                                DateFormat('MMM d, yyyy').format(date),
                                style: AppTextStyles.caption,
                              ),
                              const Spacer(),
                              _buildStatusBadge(status),
                            ],
                          ),
                        ),

                        // ── Product Row: Image + Names ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.mutedLight,
                                  child: heroImage != null
                                      ? CachedNetworkImage(
                                          imageUrl: CloudinaryHelper.getOptimizedUrl(heroImage, width: 112),
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.muted),
                                          errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.muted),
                                        )
                                      : const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.muted),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product names + vendor
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product names
                                    if (productNames.isNotEmpty)
                                      Text(
                                        productNames.length == 1
                                            ? productNames[0]
                                            : '${productNames[0]} +${products.length - 1} more',
                                        style: AppTextStyles.cardTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      Text(
                                        '${products.length} item${products.length == 1 ? '' : 's'}',
                                        style: AppTextStyles.cardTitle,
                                      ),
                                    const SizedBox(height: 4),
                                    // Vendor name
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront_outlined, size: 12, color: AppColors.muted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            vendorName,
                                            style: AppTextStyles.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (firstQtyUnit != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        firstQtyUnit,
                                        style: AppTextStyles.caption.copyWith(color: AppColors.coral),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Price
                              Text(
                                'Rs. $totalAmount',
                                style: AppTextStyles.cardTitle.copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
                        const SizedBox(height: 10),

                        // ── Footer: ETA + Delivery + Chevron ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Row(
                            children: [
                              // ETA with icon
                              Icon(_getEtaIcon(status), size: 14, color: etaColor),
                              const SizedBox(width: 4),
                              Text(
                                eta,
                                style: AppTextStyles.label.copyWith(color: etaColor),
                              ),
                              const SizedBox(width: 16),
                              // Delivery location
                              if (deliverySnippet != null) ...[
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
                              ] else
                                const Spacer(),
                              // Chevron
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  String _unitLabel(String unit) {
    switch (unit) {
      case 'kg': return 'kg';
      case '100g': return '100g';
      case 'liter': return 'L';
      case 'dozen': return 'dozen';
      case 'packet': return 'pkt';
      case 'bundle': return 'bundle';
      default: return '';
    }
  }
}
