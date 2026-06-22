import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vendor_order_status_badge.dart';
import '../../widgets/skeleton_loaders.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  String _activeFilter = 'All';
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchVendorOrders();
    });
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

          final allOrders = orderProvider.vendorOrders;
          final filtered = _activeFilter == 'All'
              ? allOrders
              : allOrders
                  .where((o) => o['orderStatus'] == _activeFilter)
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────
              _buildHeader(allOrders.length),
              // ── Filter chips ───────────────────────────────
              _buildFilterChips(allOrders),
              // ── Order list ─────────────────────────────────
              Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => orderProvider.fetchVendorOrders(),
                      color: AppColors.coral,
                      child: filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No matching orders',
                                  message: 'Try a different filter.',
                                ),
                              ],
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent - 200 &&
                                    orderProvider.hasMore &&
                                    !orderProvider.isFetchingMore) {
                                  orderProvider.loadMoreVendorOrders();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: filtered.length + (orderProvider.hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == filtered.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.coral,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildOrderCard(filtered[index]);
                                },
                              ),
                            ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header — "Orders" + count + Filter button
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orders', style: AppTextStyles.screenTitle),
                const SizedBox(height: 2),
                Text(
                  '$totalCount orders total',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.ink),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filter chips — rounded rects, colored fill for active, light bg for inactive
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterChips(List allOrders) {
    int countForStatus(String status) {
      if (status == 'All') return allOrders.length;
      return allOrders.where((o) => o['orderStatus'] == status).length;
    }

    final chips = [
      ('All', AppColors.coral, AppColors.coralDark),
      ('Pending', AppColors.warningLight, AppColors.warningDark),
      ('Confirmed', AppColors.blueLight, AppColors.blueDark),
      ('Delivered', AppColors.successLight, AppColors.successDark),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, chipBg, chipText) = chips[index];
          final isActive = _activeFilter == label;
          final count = countForStatus(label);

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? chipBg : chipBg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$label ($count)',
                style: AppTextStyles.label.copyWith(
                  color: isActive ? chipText : chipText.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Order card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderCard(dynamic order) {
    final status = order['orderStatus'] ?? 'Pending';
    final isCancelled = status == 'Cancelled';
    final isPending = status == 'Pending';
    final isConfirmed = status == 'Confirmed';
    final customerName = order['customerId']?['fullName'] ?? 'Customer';
    final phone = order['customerId']?['phone'] ?? '';
    final address = _formatAddress(order['shippingAddress']);
    final totalAmount = order['totalAmount'] ?? 0;
    final products = order['products'] as List? ?? [];
    final notes = order['notes'];
    final orderIdStr = order['_id'].toString();
    final shortId = orderIdStr.length > 6
        ? orderIdStr.substring(orderIdStr.length - 6).toUpperCase()
        : orderIdStr.toUpperCase();

    return Opacity(
      opacity: isCancelled ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: order id + status badge ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$shortId',
                  style: AppTextStyles.label.copyWith(color: AppColors.muted),
                ),
                VendorOrderStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 2: customer avatar + name + phone ────────
            Row(
              children: [
                _buildInitialsAvatar(customerName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: isCancelled ? AppColors.muted : AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Row 3: address ───────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: address.isEmpty
                      ? Text(
                          'No address provided',
                          style: AppTextStyles.bodyMuted.copyWith(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          address,
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Products list ────────────────────────────────
            const Divider(color: AppColors.divider, height: 1),
            ...products.map((p) {
              final productData = p['product'];
              String title = 'Product';
              String? imageUrl;
              int qty = p['quantity'] ?? 1;
              int price = p['price'] ?? 0;

              if (productData is Map) {
                title = productData['title'] ?? 'Product';
                final images = productData['images'];
                if (images is List && images.isNotEmpty) {
                  imageUrl = images[0]?.toString();
                } else if (images is String && images.isNotEmpty) {
                  imageUrl = images;
                }
              } else if (productData is String) {
                title =
                    'Product #${productData.substring(productData.length - 6).toUpperCase()}';
              }

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    // Product image thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              CloudinaryHelper.getOptimizedUrl(
                                imageUrl,
                                width: 88,
                                height: 88,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.coralDark,
                                  size: 20,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.coralDark,
                                size: 20,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // Product title + qty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: isCancelled ? AppColors.muted : AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: $qty',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Text(
                      'Rs. $price',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: isCancelled ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Notes ────────────────────────────────────────
            if (notes != null && notes.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: $notes',
                style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Order total row ──────────────────────────────
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order total',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                ),
                Text(
                  'Rs. $totalAmount',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: isCancelled ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ],
            ),

            // ── Action buttons (pending only) ────────────────
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: _updatingOrderId != null
                            ? null
                            : () => _updateStatus(
                                order['_id'], 'Cancelled', context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.muted,
                          disabledForegroundColor: AppColors.muted
                              .withValues(alpha: 0.5),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: _updatingOrderId == order['_id']
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.muted,
                                ),
                              )
                            : Text(
                                'Reject',
                                style: AppTextStyles.label.copyWith(color: AppColors.ink),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _updatingOrderId != null
                            ? null
                            : () => _updateStatus(
                                order['_id'], 'Confirmed', context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          disabledBackgroundColor:
                              AppColors.coral.withValues(alpha: 0.5),
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: _updatingOrderId == order['_id']
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ink,
                                ),
                              )
                            : Text(
                                'Confirm order',
                                style: AppTextStyles.label.copyWith(color: AppColors.ink),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Action buttons (confirmed only) ──────────────
            if (isConfirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _updatingOrderId != null
                      ? null
                      : () => _updateStatus(
                          order['_id'], 'Delivered', context),
                  icon: _updatingOrderId == order['_id']
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ink,
                          ),
                        )
                      : const Icon(Icons.local_shipping_outlined, size: 18),
                  label: Text(
                    'Mark as delivered',
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successDark,
                    disabledBackgroundColor:
                        AppColors.successDark.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initials avatar — coral-light circle with coral-dark initial
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInitialsAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.coralLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.coralDark),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      String orderId, String status, BuildContext context) async {
    if (_updatingOrderId != null) return;

    setState(() => _updatingOrderId = orderId);

    final messenger = ScaffoldMessenger.of(context);
    final orderProvider =
        Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.updateOrderStatus(
      orderId,
      status,
    );

    if (!mounted) return;

    setState(() => _updatingOrderId = null);

    if (success) {
      String label;
      switch (status) {
        case 'Confirmed':
          label = 'confirmed';
          break;
        case 'Delivered':
          label = 'marked as delivered';
          break;
        case 'Cancelled':
          label = 'rejected';
          break;
        default:
          label = 'updated';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order $label successfully'),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final msg = orderProvider.error ?? 'Failed to update order';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════
  String _formatAddress(dynamic raw) {
    if (raw is Map) {
      final parts = <String>[
        if ((raw['flatHouse'] ?? '').isNotEmpty) raw['flatHouse'],
        if ((raw['street'] ?? '').isNotEmpty) raw['street'],
        if ((raw['city'] ?? '').isNotEmpty) raw['city'],
        if ((raw['state'] ?? '').isNotEmpty) raw['state'],
        if ((raw['zipCode'] ?? '').isNotEmpty) raw['zipCode'],
      ];
      return parts.join(', ');
    }
    return raw?.toString() ?? '';
  }
}
