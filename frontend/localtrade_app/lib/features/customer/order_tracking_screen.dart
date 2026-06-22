import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/network/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../widgets/skeleton_loaders.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  dynamic _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  void _fetchOrder() async {
    try {
      final result = await _orderService.getOrder(widget.orderId);
      setState(() {
        _order = result['data']['order'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Details', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const ListSkeleton(itemCount: 4)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.screenPaddingTop,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildTimelineCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildItemsCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildDeliveryCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildPaymentSummary(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Order Header ──────────────────────────────────────────────────────────
  Widget _buildOrderHeader() {
    final orderId = _order['_id'].toString();
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();
    final status = _order['orderStatus'];
    final dateStr = _order['createdAt'] ?? DateTime.now().toString();
    final date = DateTime.parse(dateStr).toLocal();
    final formattedDate = DateFormat('MMM d, yyyy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(status), size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$shortId',
                      style: AppTextStyles.cardTitle.copyWith(letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$formattedDate at $formattedTime',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline Card ─────────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    final status = _order['orderStatus'];
    final isCancelled = status == 'Cancelled';
    final dateStr = _order['createdAt'] ?? DateTime.now().toString();
    final orderDate = DateTime.parse(dateStr).toLocal();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Progress', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.gapLg),
          if (isCancelled)
            _buildCancelledBanner()
          else
            _buildTimeline(status, orderDate),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.gapLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: AppTextStyles.cardTitle.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 2),
                Text(
                  'This order has been cancelled.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus, DateTime orderDate) {
    final steps = [
      ('Pending', 'Order received', Icons.receipt_outlined),
      ('Confirmed', 'Vendor confirmed', Icons.storefront_outlined),
      ('Delivered', 'Delivered to you', Icons.check_circle_outline_rounded),
    ];

    int currentIdx = steps.indexWhere((s) => s.$1 == currentStatus);
    if (currentIdx == -1) currentIdx = 0;

    return Column(
      children: List.generate(steps.length, (idx) {
        final (name, subtitle, stepIcon) = steps[idx];
        final isCompleted = idx <= currentIdx;
        final isCurrent = idx == currentIdx;
        final isLast = idx == steps.length - 1;

        // Calculate relative time for each step
        String stepTime = '';
        if (isCompleted) {
          if (idx == 0) {
            stepTime = DateFormat('MMM d, h:mm a').format(orderDate);
          } else if (idx == 1 && _order['confirmedAt'] != null) {
            stepTime = DateFormat('MMM d, h:mm a').format(
              DateTime.parse(_order['confirmedAt']).toLocal(),
            );
          } else if (idx == 2 && _order['deliveredAt'] != null) {
            stepTime = DateFormat('MMM d, h:mm a').format(
              DateTime.parse(_order['deliveredAt']).toLocal(),
            );
          }
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.coral : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppColors.coral : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(stepIcon, size: 14, color: Colors.white)
                          : Icon(stepIcon, size: 14, color: AppColors.muted),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: idx < currentIdx ? AppColors.coral : AppColors.divider,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.gapLg),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: isLast ? 0 : AppSpacing.gapMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
                          color: isCompleted ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrent ? AppColors.muted : AppColors.muted.withValues(alpha: 0.5),
                        ),
                      ),
                      if (stepTime.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          stepTime,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Items Card ────────────────────────────────────────────────────────────
  Widget _buildItemsCard() {
    final products = _order['products'] as List;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items (${products.length})', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.gapLg),
          ...products.map((p) => _buildItemRow(p)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic p) {
    final product = p['product'];
    final imageUrl = (product['images'] as List).isNotEmpty
        ? CloudinaryHelper.getOptimizedUrl(
            product['images'][0],
            width: 96,
            height: 96,
          )
        : '';
    final quantity = p['quantity'] ?? 1;
    final unitPrice = p['price'] ?? 0;
    final lineTotal = unitPrice * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gapLg),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.background,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.image_outlined, size: 20, color: AppColors.muted),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.muted),
                      ),
                    )
                  : const Icon(Icons.image_outlined, size: 20, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.gapLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'] ?? 'Product',
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: $quantity',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x Rs. $unitPrice',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Rs. $lineTotal',
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  // ── Delivery Card ─────────────────────────────────────────────────────────
  Widget _buildDeliveryCard() {
    final rawAddress = _order['shippingAddress'] ?? '';
    final notes = _order['notes'];

    String displayName = '';
    String displayAddress = '';

    if (rawAddress is Map) {
      displayName = rawAddress['fullName'] ?? '';
      final parts = <String>[
        if ((rawAddress['flatHouse'] ?? '').isNotEmpty) rawAddress['flatHouse'],
        if ((rawAddress['street'] ?? '').isNotEmpty) rawAddress['street'],
        if ((rawAddress['landmark'] ?? '').isNotEmpty) 'Landmark: ${rawAddress['landmark']}',
        if ((rawAddress['city'] ?? '').isNotEmpty) rawAddress['city'],
        if ((rawAddress['state'] ?? '').isNotEmpty) rawAddress['state'],
        if ((rawAddress['zipCode'] ?? '').isNotEmpty) rawAddress['zipCode'],
      ];
      displayAddress = parts.join(', ');
    } else {
      displayAddress = rawAddress.toString();
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Details', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.gapLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.coralDark),
              ),
              const SizedBox(width: AppSpacing.gapLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayName.isNotEmpty)
                      Text(displayName, style: AppTextStyles.cardTitle.copyWith(height: 1.4)),
                    if (displayAddress.isNotEmpty)
                      Text(displayAddress, style: AppTextStyles.caption.copyWith(height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (notes != null && notes.toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gapLg),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.gapLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notes_rounded, size: 18, color: AppColors.blueDark),
                ),
                const SizedBox(width: AppSpacing.gapLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Notes', style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Text(
                        notes.toString(),
                        style: AppTextStyles.bodyMuted.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Payment Summary ───────────────────────────────────────────────────────
  Widget _buildPaymentSummary() {
    final products = _order['products'] as List;
    final totalAmount = _order['totalAmount'] ?? 0;

    // Calculate subtotal
    int subtotal = 0;
    for (final p in products) {
      final quantity = (p['quantity'] ?? 1) as int;
      final price = (p['price'] ?? 0) as int;
      subtotal += price * quantity;
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.gapLg),
          _buildPaymentRow('Subtotal', 'Rs. $subtotal'),
          const SizedBox(height: 8),
          _buildPaymentRow('Delivery', 'Free'),
          const SizedBox(height: 8),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.cardTitle),
              Text('Rs. $totalAmount', style: AppTextStyles.price),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMuted),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    final status = _order['orderStatus'];

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact vendor coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: Text('Contact Vendor', style: AppTextStyles.cardTitle.copyWith(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (status == 'Delivered') ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reorder coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text('Reorder', style: AppTextStyles.cardTitle.copyWith(fontSize: 13, color: AppColors.ink)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'Pending':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Pending';
        break;
      case 'Confirmed':
        bgColor = AppColors.blueLight;
        textColor = AppColors.blueDark;
        label = 'Confirmed';
        break;
      case 'Delivered':
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        label = 'Delivered';
        break;
      case 'Cancelled':
        bgColor = AppColors.coralLight;
        textColor = AppColors.coralDark;
        label = 'Cancelled';
        break;
      default:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Confirmed':
        return AppColors.blue;
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_rounded;
      case 'Confirmed':
        return Icons.check_rounded;
      case 'Delivered':
        return Icons.check_circle_outline_rounded;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
