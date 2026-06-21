import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/network/order_service.dart';
import '../../core/theme/app_theme.dart';

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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Order Details')),
      body: _isLoading
          ? _buildSkeletonLoader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tracking Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Order ID: #${_order['_id'].toString().substring(18).toUpperCase()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 32),
                        _buildTimeline(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Items Ordered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        ..._order['products'].map<Widget>((p) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(p['product']['images'][0]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['product']['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${p['quantity']} • Rs. ${p['price']}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${p['price'] * p['quantity']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        )).toList(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                              Flexible(
                                child: Text(
                                  'Rs. ${_order['totalAmount']}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _order['shippingAddress'],
                                style: const TextStyle(color: AppTheme.textPrimary, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                        if (_order['notes'] != null && _order['notes'].isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined, color: AppTheme.textSecondary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Note: ${_order['notes']}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ]
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('This order has been cancelled.', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryColor : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: isCurrent ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 4) : null,
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: idx < currentStep ? AppTheme.primaryColor : Colors.grey[200],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                      color: isCompleted ? AppTheme.textPrimary : Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusSubtitle(name),
                    style: TextStyle(fontSize: 12, color: isCurrent ? AppTheme.textSecondary : Colors.grey[400]),
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
      case 'Pending': return 'We have received your order.';
      case 'Confirmed': return 'The vendor has confirmed your order.';
      case 'Delivered': return 'Your order has been delivered.';
      default: return '';
    }
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
