import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<OrderProvider>(context, listen: false).fetchVendorOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading && orderProvider.vendorOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.vendorOrders.isEmpty) {
            return const Center(child: Text('No orders received yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProvider.vendorOrders.length,
            itemBuilder: (context, index) {
              final order = orderProvider.vendorOrders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order['_id'].toString().substring(18)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusDropdown(order),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Customer: ${order['customerId']['fullName']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Phone: ${order['customerId']['phone']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Address: ${order['shippingAddress']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(order['products'] as List).map<Widget>((p) {
                        final productData = p['product'];
                        String title = 'Unknown Product';
                        
                        if (productData is Map) {
                          title = productData['title'] ?? 'Unknown Product';
                        } else if (productData is String) {
                          // Handle cases where ID is returned but not populated
                          title = 'Product ID: ${productData.substring(productData.length - 6).toUpperCase()}';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '- $title x ${p['quantity']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Text('Total: Rs. ${order['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (order['notes'] != null && order['notes'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Notes: ${order['notes']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusDropdown(dynamic order) {
    return DropdownButton<String>(
      value: order['orderStatus'],
      onChanged: (String? newValue) {
        if (newValue != null && newValue != order['orderStatus']) {
          Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(order['_id'], newValue);
        }
      },
      items: <String>['Pending', 'Confirmed', 'Delivered', 'Cancelled']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(fontSize: 12, color: _getStatusColor(value))),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
