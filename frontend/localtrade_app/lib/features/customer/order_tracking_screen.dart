import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/network/order_service.dart';
import '../../core/network/review_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/skeleton_loaders.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();
  dynamic _order;
  bool _isLoading = true;
  final Set<String> _reviewedProductIds = {};

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  void _fetchOrder() async {
    try {
      final result = await _orderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = result['data']['order'];
          _isLoading = false;
        });
        _checkReviewedProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _checkReviewedProducts() {
    if (_order == null) return;
    final products = _order['products'] as List? ?? [];
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userId = user?['_id'];
    if (userId == null) return;

    for (final p in products) {
      final product = p['product'];
      if (product is! Map) continue;
      final productId = product['_id']?.toString();
      if (productId == null) continue;

      _reviewService.getProductReviews(productId).then((data) {
        final reviews = data['data']['reviews'] as List? ?? [];
        final hasReviewed = reviews.any((r) {
          final rUserId = r['userId']?['_id'] ?? r['userId'];
          return rUserId?.toString() == userId;
        });
        if (hasReviewed && mounted) {
          setState(() => _reviewedProductIds.add(productId));
        }
      }).catchError((_) {});
    }
  }

  // ── ETA Logic ─────────────────────────────────────────────────────────────
  String _getEtaText() {
    final status = _order['orderStatus'];
    final dateStr = _order['createdAt'] ?? DateTime.now().toString();
    final orderDate = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();

    switch (status) {
      case 'Delivered':
        return 'Delivered';
      case 'Cancelled':
        return 'Cancelled';
      case 'Confirmed':
        final deliveryDate = orderDate.add(const Duration(days: 1));
        final remaining = deliveryDate.difference(now);
        if (remaining.isNegative || remaining.inHours < 1) {
          return 'Arriving today';
        } else if (remaining.inHours < 24) {
          return 'Arriving in ${remaining.inHours}h';
        } else {
          return 'Expected ${DateFormat('MMM d').format(deliveryDate)}';
        }
      case 'Pending':
      default:
        final deliveryDate = orderDate.add(const Duration(days: 2));
        final remaining = deliveryDate.difference(now);
        if (remaining.isNegative || remaining.inHours < 1) {
          return 'Arriving today';
        } else if (remaining.inHours < 24) {
          return 'Expected in ${remaining.inHours}h';
        } else {
          final days = remaining.inDays;
          return 'Expected in $days ${days == 1 ? 'day' : 'days'}';
        }
    }
  }

  Color _getEtaColor() {
    final status = _order['orderStatus'];
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      case 'Confirmed':
        return AppColors.blue;
      default:
        return AppColors.warning;
    }
  }

  IconData _getEtaIcon() {
    final status = _order['orderStatus'];
    switch (status) {
      case 'Delivered':
        return Icons.check_circle_outline_rounded;
      case 'Cancelled':
        return Icons.cancel_outlined;
      case 'Confirmed':
        return Icons.local_shipping_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  // ── Stock Info ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _getLowStockItems() {
    final products = _order['products'] as List? ?? [];
    final lowStock = <Map<String, dynamic>>[];
    for (final p in products) {
      final product = p['product'];
      if (product is Map) {
        final stock = product['stockQuantity'] ?? 0;
        final title = product['title'] ?? 'Product';
        if (stock <= 5 && stock > 0) {
          lowStock.add({'title': title, 'stock': stock});
        }
      }
    }
    return lowStock;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                  _buildEtaBanner(),
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

  // ── ETA Banner ────────────────────────────────────────────────────────────
  Widget _buildEtaBanner() {
    final etaColor = _getEtaColor();
    final status = _order['orderStatus'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: etaColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: etaColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_getEtaIcon(), size: 20, color: etaColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEtaText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: etaColor,
                  ),
                ),
                if (status == 'Pending' || status == 'Confirmed') ...[
                  const SizedBox(height: 2),
                  Text(
                    'We are preparing your order',
                    style: AppTextStyles.caption.copyWith(color: etaColor.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
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
    final reason = _order['cancellationReason'];
    final feedback = _order['cancellationFeedback'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (reason != null && reason.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(reason.toString(), style: AppTextStyles.bodyMuted),
                  if (feedback != null && feedback.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Feedback', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(feedback.toString(), style: AppTextStyles.bodyMuted),
                  ],
                ],
              ),
            ),
          ],
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
    final images = product['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? CloudinaryHelper.getOptimizedUrl(
            images[0],
            width: 96,
            height: 96,
          )
        : '';
    final quantity = p['quantity'] ?? 1;
    final unitPrice = p['price'] ?? 0;
    final priceUnit = p['priceUnit'] ?? 'piece';
    final unitLabel = _unitLabel(priceUnit);
    final size = p['size'] as String?;
    final sizeLabel = size != null && size.isNotEmpty ? ' Size: $size' : '';
    final lineTotal = unitPrice * quantity;
    final stock = product['stockQuantity'] ?? 0;

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
                      placeholder: (_, __) =>
                        const ShimmerSkeleton(height: 52, width: 52, radius: 8),
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
                      'Qty: $quantity${unitLabel.isNotEmpty ? ' $unitLabel' : ''}$sizeLabel',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x Rs. $unitPrice${unitLabel.isNotEmpty ? '/$unitLabel' : ''}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                if (stock > 0 && stock <= 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only $stock left in stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ],
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
    final canCancel = status == 'Pending';
    final isDelivered = status == 'Delivered';

    return Column(
      children: [
        if (isDelivered) ...[
          // Review CTA card
          _buildReviewCtaCard(),
          const SizedBox(height: 12),
          // Reorder button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleReorder,
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
        if (canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showCancelModal,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                'Cancel Order',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 13, color: AppColors.danger),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCtaCard() {
    final products = _order['products'] as List? ?? [];
    final reviewableProducts = products.where((p) {
      final product = p['product'];
      if (product is! Map) return false;
      final productId = (product['_id'] ?? product).toString();
      return !_reviewedProductIds.contains(productId);
    }).toList();

    // All products reviewed — hide the card
    if (reviewableProducts.isEmpty && products.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coralLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review_outlined,
                    size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate your purchase',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Help other customers by sharing your experience',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...products.map((p) {
            final product = p['product'];
            if (product is! Map) return const SizedBox.shrink();
            final title = product['title'] ?? 'Product';
            final productId = (product['_id'] ?? product).toString();
            final alreadyReviewed = _reviewedProductIds.contains(productId);

            if (alreadyReviewed) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: AppColors.successDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"$title" — reviewed',
                          style: AppTextStyles.label.copyWith(color: AppColors.successDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewModal(product, productId),
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: Text(
                    'Review "$title"',
                    style: AppTextStyles.label.copyWith(color: AppColors.coral),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Reorder ──────────────────────────────────────────────────────────────
  void _handleReorder() {
    if (_order == null) return;

    final products = _order['products'] as List? ?? [];
    if (products.isEmpty) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final reorderItems = <Map<String, dynamic>>[];
    final skippedItems = <String>[];

    for (final p in products) {
      final productData = p['product'];
      if (productData is! Map) continue;

      final productId = (productData['_id'] ?? '').toString();
      if (productId.isEmpty) continue;

      final stock = productData['stockQuantity'] ?? 0;
      final status = productData['productStatus'] ?? 'Available';

      if (stock <= 0 || status != 'Available') {
        skippedItems.add(productData['title'] ?? 'Item');
        continue;
      }

      final quantity = (p['quantity'] ?? 1) as int;
      final clampedQty = quantity > stock ? stock : quantity;
      final size = p['size'] as String?;

      reorderItems.add({
        'productId': productId,
        'title': productData['title'] ?? '',
        'price': p['price'] ?? productData['price'] ?? 0,
        'priceUnit': p['priceUnit'] ?? productData['priceUnit'] ?? 'piece',
        'imageUrl': (productData['images'] as List?)?.isNotEmpty == true
            ? productData['images'][0]
            : '',
        'vendorId': (_order['vendorId'] is Map
                ? _order['vendorId']['_id']
                : _order['vendorId'])
            ?.toString() ??
            '',
        'vendorName': (_order['vendorId'] is Map
                ? (_order['vendorId']['shopName'] ??
                    _order['vendorId']['fullName'])
                : '')
            ?.toString() ??
            '',
        'quantity': clampedQty,
        if (size != null && size.isNotEmpty) 'size': size,
      });
    }

    if (reorderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('None of the items are available for reorder'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    cart.addItems(reorderItems);

    if (mounted) {
      String message = '${reorderItems.length} item${reorderItems.length == 1 ? '' : 's'} added to cart';
      if (skippedItems.isNotEmpty) {
        message += ' (${skippedItems.length} unavailable)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: AppColors.coral,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    }
  }

  // ── Cancel Modal ──────────────────────────────────────────────────────────
  void _showCancelModal() {
    final lowStockItems = _getLowStockItems();
    String? selectedReason;
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text('Cancel Order?', style: AppTextStyles.screenTitle),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to cancel this order? This action cannot be undone.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 20),

                // Dissuasion: arriving soon
                _buildDissuasionCard(
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.blue,
                  title: 'Arriving in 2 days',
                  subtitle: 'Your order is already being prepared and will arrive soon.',
                ),
                const SizedBox(height: 10),

                // Dissuasion: low stock
                if (lowStockItems.isNotEmpty)
                  ...lowStockItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDissuasionCard(
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.warning,
                      title: 'Only ${item['stock']} left in stock',
                      subtitle: '"${item['title']}" is almost sold out. Cancelling means you might not get it again.',
                    ),
                  )),

                // Reason dropdown
                Text('Reason for cancelling', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      hint: Text('Select a reason', style: AppTextStyles.bodyMuted),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Changed my mind', child: Text('Changed my mind')),
                        DropdownMenuItem(value: 'Found a better price', child: Text('Found a better price')),
                        DropdownMenuItem(value: 'Ordered by mistake', child: Text('Ordered by mistake')),
                        DropdownMenuItem(value: 'Delivery too slow', child: Text('Delivery too slow')),
                        DropdownMenuItem(value: 'No longer needed', child: Text('No longer needed')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Feedback
                Text('Additional feedback (optional)', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tell us how we can improve...',
                    hintStyle: AppTextStyles.bodyMuted,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Keep Order', style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _cancelOrder(
                            reason: selectedReason,
                            feedback: feedbackController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Yes, Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDissuasionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder({String? reason, String? feedback}) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(
      _order['_id'],
      reason: reason,
      feedback: feedback,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchOrder(); // Refresh to show updated status
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to cancel order'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Review Modal ────────────────────────────────────────────────────────
  void _showReviewModal(dynamic product, String productId) {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Write a review',
                          style: AppTextStyles.sectionHeading,
                        ),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product name context
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              size: 18, color: AppColors.coralDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              product['title'] ?? 'Product',
                              style: AppTextStyles.label.copyWith(color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Star rating
                    Text('Your rating', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ratingLabel(rating),
                      style: AppTextStyles.caption.copyWith(color: AppColors.coralDark),
                    ),
                    const SizedBox(height: 20),

                    // Review text
                    Text('Your review', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      maxLength: 1000,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'What did you like or dislike?',
                        hintStyle: AppTextStyles.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    Consumer<ReviewProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (reviewController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Please write a review')),
                                      );
                                      return;
                                    }
                                    AuthGuard.requireAuth(context, onAuthenticated: () async {
                                      final success = await provider.submitReview(
                                        productId,
                                        rating,
                                        reviewController.text.trim(),
                                      );
                                      if (success && context.mounted) {
                                        setState(() => _reviewedProductIds.add(productId));
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Review submitted'),
                                              backgroundColor: AppColors.success),
                                        );
                                      } else if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(provider.error ?? 'Failed'),
                                              backgroundColor: AppColors.danger),
                                        );
                                      }
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: AppColors.ink,
                              disabledBackgroundColor: AppColors.divider,
                              disabledForegroundColor: AppColors.muted,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink))
                                : Text('Submit review',
                                    style: AppTextStyles.cardTitle,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very good';
      case 5: return 'Excellent';
      default: return '';
    }
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
