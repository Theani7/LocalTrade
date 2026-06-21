import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
        title: const Text('Order Details'),
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
                  _buildTrackingCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildItemsCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildDeliveryCard(),
                  const SizedBox(height: AppSpacing.gapLg),
                  _buildPaymentCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackingCard() {
    final orderId = _order['_id'].toString();
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();
    final status = _order['orderStatus'];
    final isCancelled = status == 'Cancelled';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$shortId',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gapXl),
          if (isCancelled)
            _buildCancelledBanner()
          else
            _buildTimeline(status),
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
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
          SizedBox(width: AppSpacing.gapLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'This order has been cancelled.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      ('Pending', 'Order received'),
      ('Confirmed', 'Vendor confirmed'),
      ('Delivered', 'Delivered to you'),
    ];

    int currentIdx = steps.indexWhere((s) => s.$1 == currentStatus);
    if (currentIdx == -1) currentIdx = 0;

    return Column(
      children: List.generate(steps.length, (idx) {
        final (name, subtitle) = steps[idx];
        final isCompleted = idx <= currentIdx;
        final isCurrent = idx == currentIdx;
        final isLast = idx == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.coral : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppColors.coral : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
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
                    top: 3,
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

  Widget _buildItemsCard() {
    final products = _order['products'] as List;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.gapLg),
          ...products.map((p) => _buildItemRow(p)),
          const Divider(color: AppColors.divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              Text(
                'Rs. ${_order['totalAmount']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gapLg),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.background,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.divider,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.divider,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.gapLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${p['quantity']} x Rs. ${p['price']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${p['price'] * p['quantity']}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    final rawAddress = _order['shippingAddress'] ?? '';
    final notes = _order['notes'];

    // Parse structured address (new format) or legacy string
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
          const Text(
            'Delivery Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.gapLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.coral,
              ),
              const SizedBox(width: AppSpacing.gapLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayName.isNotEmpty)
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    if (displayAddress.isNotEmpty)
                      Text(
                        displayAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (notes != null && notes.toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gapXl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.gapLg),
                Expanded(
                  child: Text(
                    notes.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return _Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          Text(
            'Rs. ${_order['totalAmount']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
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
