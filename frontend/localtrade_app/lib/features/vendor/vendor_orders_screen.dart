import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  String _activeFilter = 'All';

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

          final filtered = _activeFilter == 'All'
              ? orderProvider.vendorOrders
              : orderProvider.vendorOrders
                  .where((o) => o['orderStatus'] == _activeFilter)
                  .toList();

          return Column(
            children: [
              // ── Filter chips ──────────────────────────────────
              _buildFilterChips(orderProvider.vendorOrders),
              // ── Order list ────────────────────────────────────
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return _buildOrderCard(order);
                          },
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
  // Filter chips — horizontal scrolling row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterChips(List allOrders) {
    int countForStatus(String status) {
      if (status == 'All') return allOrders.length;
      return allOrders.where((o) => o['orderStatus'] == status).length;
    }

    final chips = [
      ('All', AppColors.coral, AppColors.coralLight, AppColors.coralDark),
      ('Pending', AppColors.warningDark, AppColors.warningLight, AppColors.warningDark),
      ('Confirmed', AppColors.blueDark, AppColors.blueLight, AppColors.blueDark),
      ('Delivered', AppColors.successDark, AppColors.successLight, AppColors.successDark),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, activeFill, activeBg, activeText) = chips[index];
          final isActive = _activeFilter == label;
          final count = countForStatus(label);

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? activeBg : AppColors.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isActive ? activeBg : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    Icon(Icons.check_rounded, size: 14, color: activeText)
                  else
                    Icon(_chipIcon(label), size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? activeText : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeText.withValues(alpha: 0.12)
                          : AppColors.mutedLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive ? activeText : AppColors.muted,
                      ),
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

  IconData _chipIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_outlined;
      case 'Confirmed':
        return Icons.check_circle_outline_rounded;
      case 'Delivered':
        return Icons.local_shipping_outlined;
      default:
        return Icons.tune_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Order card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderCard(dynamic order) {
    final status = order['orderStatus'] ?? 'Pending';
    final isCancelled = status == 'Cancelled';
    final isPending = status == 'Pending';
    final customerName = order['customerId']?['fullName'] ?? 'Customer';
    final phone = order['customerId']?['phone'] ?? '';
    final address = _formatAddress(order['shippingAddress']);
    final totalAmount = order['totalAmount'] ?? 0;
    final products = order['products'] as List? ?? [];
    final notes = order['notes'];

    return Opacity(
      opacity: isCancelled ? 0.75 : 1.0,
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
                  '#${order['_id'].toString().substring(18).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isCancelled ? AppColors.muted : AppColors.muted,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),

            // ── Row 2: customer avatar + name ────────────────
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCancelled ? AppColors.muted : AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCancelled
                                ? AppColors.muted
                                : AppColors.muted,
                          ),
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
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isCancelled ? AppColors.muted : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: address.isEmpty
                      ? Text(
                          'No address provided',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCancelled
                                ? AppColors.muted
                                : AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCancelled
                                ? AppColors.muted
                                : AppColors.muted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Products list ────────────────────────────────
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            ...products.map((p) {
              final productData = p['product'];
              String title = 'Product';
              if (productData is Map) {
                title = productData['title'] ?? 'Product';
              } else if (productData is String) {
                title =
                    'Product #${productData.substring(productData.length - 6).toUpperCase()}';
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$title x ${p['quantity']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCancelled ? AppColors.muted : AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),

            // ── Notes ────────────────────────────────────────
            if (notes != null && notes.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Note: $notes',
                style: TextStyle(
                  fontSize: 12,
                  color: isCancelled ? AppColors.muted : AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Order total row ──────────────────────────────
            const SizedBox(height: 8),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
                    child: _buildRejectButton(order['_id']),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildConfirmButton(order['_id']),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Status badge — light fill + dark text + icon
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'Pending':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Pending';
        icon = Icons.schedule_outlined;
        break;
      case 'Confirmed':
        bgColor = AppColors.blueLight;
        textColor = AppColors.blueDark;
        label = 'Confirmed';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'Delivered':
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        label = 'Delivered';
        icon = Icons.local_shipping_outlined;
        break;
      case 'Cancelled':
        bgColor = AppColors.mutedLight;
        textColor = AppColors.muted;
        label = 'Cancelled';
        icon = Icons.close_rounded;
        break;
      default:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = status;
        icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Initials avatar — coral-light circle with coral-dark initial
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInitialsAvatar(String name) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.coralDark,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Action buttons — Reject (outline) + Confirm (coral)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRejectButton(String orderId) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: () => _updateStatus(orderId, 'Cancelled'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          'Reject',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(String orderId) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () => _updateStatus(orderId, 'Confirmed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          'Confirm order',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _updateStatus(String orderId, String status) {
    Provider.of<OrderProvider>(context, listen: false)
        .updateOrderStatus(orderId, status);
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
