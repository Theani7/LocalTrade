import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_product_screen.dart';

class VendorInventoryScreen extends StatefulWidget {
  const VendorInventoryScreen({super.key});

  @override
  State<VendorInventoryScreen> createState() => _VendorInventoryScreenState();
}

class _VendorInventoryScreenState extends State<VendorInventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<ProductProvider>(context, listen: false).fetchMyProducts()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            onPressed: () => Provider.of<ProductProvider>(context, listen: false).fetchMyProducts(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditProductScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myProducts.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Products Yet',
              message: 'Add products to start managing your inventory.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMyProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myProducts.length,
              itemBuilder: (context, index) {
                final product = provider.myProducts[index];
                final int stock = product['stockQuantity'] ?? 0;
                final String status = product['productStatus'] ?? 'Available';
                
                return _buildInventoryCard(context, product, stock, status);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, dynamic product, int stock, String status) {
    bool isLowStock = stock > 0 && stock < 5;
    bool isOut = status == 'OutOfStock' || stock <= 0;
    final String image = (product['images'] != null && product['images'].isNotEmpty) ? product['images'][0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey[100],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 76,
                        height: 76,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary, letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${product['price']}',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(status, stock),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Stock', style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$stock Units',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w800,
                          color: isOut ? AppTheme.errorColor : (isLowStock ? Colors.orange : AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _buildStockAction(
                    icon: Icons.remove_rounded, 
                    onTap: () => _updateStock(product['_id'], stock - 1, status),
                    enabled: stock > 0,
                  ),
                  const SizedBox(width: 8),
                  _buildStockAction(
                    icon: Icons.add_rounded, 
                    onTap: () => _updateStock(product['_id'], stock + 1, status),
                  ),
                  const SizedBox(width: 8),
                  _buildStockAction(
                    icon: Icons.edit_outlined, 
                    onTap: () => _showManualEntry(product),
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, int stock) {
    Color color = Colors.green;
    String label = 'Available';

    if (status == 'OutOfStock' || stock <= 0) {
      color = AppTheme.errorColor;
      label = 'Out of Stock';
    } else if (stock < 5) {
      color = Colors.orange;
      label = 'Low Stock';
    } else if (status == 'Inactive') {
      color = Colors.grey;
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStockAction({required IconData icon, required VoidCallback onTap, bool enabled = true, bool isPrimary = false}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppTheme.primaryColor 
              : (enabled ? Colors.white : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary 
                ? Colors.transparent 
                : (enabled ? const Color(0xFFE2E8F0) : Colors.grey[200]!),
            width: 1.2,
          ),
          boxShadow: isPrimary 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(
          icon, 
          size: 18, 
          color: isPrimary 
              ? Colors.white 
              : (enabled ? AppTheme.primaryColor : Colors.grey[300]),
        ),
      ),
    );
  }

  void _updateStock(String id, int newStock, String currentStatus) async {
    if (newStock < 0) return;
    
    // Auto-status logic
    String newStatus = currentStatus;
    if (newStock > 0 && currentStatus == 'OutOfStock') {
      newStatus = 'Available';
    } else if (newStock == 0) {
      newStatus = 'OutOfStock';
    }

    final success = await Provider.of<ProductProvider>(context, listen: false).updateProductStock(id, newStock, newStatus);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showManualEntry(dynamic product) {
    final controller = TextEditingController(text: product['stockQuantity'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${product['title']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter Stock Quantity', hintText: '0'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final int? val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.pop(context);
                _updateStock(product['_id'], val, product['productStatus']);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
