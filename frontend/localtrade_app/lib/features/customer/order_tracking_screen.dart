import 'package:flutter/material.dart';
import '../../core/network/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order details'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _isLoading
          ? const ListSkeleton(itemCount: 4)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tracking timeline
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                            Text(
                              '#${_order['_id'].toString().substring(18).toUpperCase()}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTimeline(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items
                  const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ..._order['products'].map<Widget>((p) => Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.background,
                                  child: Image.network(p['product']['images'][0], fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['product']['title'],
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${p['quantity']}  •  Rs. ${p['price']}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs. ${p['price'] * p['quantity']}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.coral),
                              ),
                            ],
                          ),
                        )).toList(),
                        const Divider(color: AppColors.divider, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              Text(
                                'Rs. ${_order['totalAmount']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery details
                  const Text('Delivery details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.coral),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _order['shippingAddress'],
                                style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                        if (_order['notes'] != null && _order['notes'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_outlined, size: 18, color: AppColors.muted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _order['notes'],
                                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeline() {
    final status = _order['orderStatus'];
    final steps = ['Pending', 'Confirmed', 'Delivered'];

    if (status == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.coralLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.coralDark, size: 20),
            SizedBox(width: 10),
            Text('Order cancelled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.coralDark)),
          ],
        ),
      );
    }

    int currentStep = steps.indexOf(status);

    return Column(
      children: steps.asMap().entries.map((entry) {
        int idx = entry.key;
        String name = entry.value;
        bool isCompleted = idx <= currentStep;
        bool isCurrent = idx == currentStep;
        bool isLast = idx == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.coral : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 14, color: AppColors.ink)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: idx < currentStep ? AppColors.coral : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    _getStatusSubtitle(name),
                    style: TextStyle(fontSize: 12, color: isCurrent ? AppColors.muted : AppColors.muted.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getStatusSubtitle(String step) {
    switch (step) {
      case 'Pending':
        return 'We have received your order';
      case 'Confirmed':
        return 'The vendor has confirmed your order';
      case 'Delivered':
        return 'Your order has been delivered';
      default:
        return '';
    }
  }
}
