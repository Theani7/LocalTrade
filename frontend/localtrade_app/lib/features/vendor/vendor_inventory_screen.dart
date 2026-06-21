import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Provider.of<ProductProvider>(context, listen: false).fetchMyProducts(),
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEditProductScreen()),
        ),
        backgroundColor: AppColors.coral,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('Add product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myProducts.isEmpty) {
            return const ListSkeleton(itemCount: 4);
          }

          if (provider.myProducts.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Add products to start managing your inventory.',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
              actionLabel: 'Add product',
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchMyProducts,
            color: AppColors.coral,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myProducts.length,
              itemBuilder: (context, index) {
                final product = provider.myProducts[index];
                final int stock = product['stockQuantity'] ?? 0;
                final String status = product['productStatus'] ?? 'Available';
                final String image = (product['images'] != null && product['images'].isNotEmpty)
                    ? product['images'][0]
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              width: 64,
                              height: 64,
                              color: AppColors.background,
                              child: image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 20),
                                    )
                                  : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${product['price']}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.coral),
                                ),
                                const SizedBox(height: 6),
                                _buildStatusChip(status, stock),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text(
                                '$stock units',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _getStockColor(status, stock),
                                ),
                              ),
                            ],
                          ),
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
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, int stock) {
    Color bgColor;
    Color textColor;
    String label;

    if (status == 'OutOfStock' || stock <= 0) {
      bgColor = AppColors.dangerLight;
      textColor = AppColors.dangerDark;
      label = 'Out of stock';
    } else if (stock < 5) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warningDark;
      label = 'Low stock';
    } else if (status == 'Inactive') {
      bgColor = AppColors.mutedLight;
      textColor = AppColors.muted;
      label = 'Inactive';
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.successDark;
      label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
    );
  }

  Color _getStockColor(String status, int stock) {
    if (status == 'OutOfStock' || stock <= 0) return AppColors.danger;
    if (stock < 5) return AppColors.warning;
    return AppColors.ink;
  }

  Widget _buildStockAction({required IconData icon, required VoidCallback onTap, bool enabled = true, bool isPrimary = false}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.coral : (enabled ? AppColors.background : AppColors.surface),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isPrimary ? Colors.transparent : (enabled ? AppColors.divider : AppColors.surface),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : (enabled ? AppColors.muted : AppColors.divider),
        ),
      ),
    );
  }

  void _updateStock(String id, int newStock, String currentStatus) async {
    if (newStock < 0) return;

    String newStatus = currentStatus;
    if (newStock > 0 && currentStatus == 'OutOfStock') {
      newStatus = 'Available';
    } else if (newStock == 0) {
      newStatus = 'OutOfStock';
    }

    final success = await Provider.of<ProductProvider>(context, listen: false).updateProductStock(id, newStock, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Stock updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showManualEntry(dynamic product) {
    final controller = TextEditingController(text: product['stockQuantity'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Update stock: ${product['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Stock quantity',
            hintText: '0',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), borderSide: const BorderSide(color: AppColors.coral)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, minimumSize: const Size(80, 36)),
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
