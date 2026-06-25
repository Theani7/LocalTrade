import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../core/utils/app_animations.dart';
import 'add_edit_product_screen.dart';

class VendorInventoryScreen extends StatefulWidget {
  const VendorInventoryScreen({super.key});

  @override
  State<VendorInventoryScreen> createState() => _VendorInventoryScreenState();
}

class _VendorInventoryScreenState extends State<VendorInventoryScreen> {
  String _activeFilter = 'All';
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchMyProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredProducts(List<dynamic> products) {
    var result = products;

    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_activeFilter != 'All') {
      result = result.where((p) {
        final int stock = p['stockQuantity'] ?? 0;
        final String status = p['productStatus'] ?? 'Available';
        switch (_activeFilter) {
          case 'Available':
            return status != 'OutOfStock' && status != 'Inactive' && stock > 0;
          case 'Low stock':
            return stock > 0 && stock < 5 && status != 'OutOfStock' && status != 'Inactive';
          case 'Unavailable':
            return status == 'OutOfStock' || status == 'Inactive' || stock <= 0;
          default:
            return true;
        }
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.myProducts.isEmpty) {
                    return const ListSkeleton(itemCount: 4);
                  }

                  if (provider.myProducts.isEmpty) {
                    return EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products yet',
                      message: 'Add products to start managing your inventory.',
                      onAction: () => Navigator.push(
                        context,
                        SlideFadePageRoute(builder: (_) => const AddEditProductScreen()),
                      ),
                      actionLabel: 'Add product',
                    );
                  }

                  final filtered = _filteredProducts(provider.myProducts);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No products match this filter',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchMyProducts,
                    color: AppColors.coral,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200 &&
                            provider.myHasMore &&
                            !provider.isFetchingMoreMyProducts) {
                          provider.loadMoreMyProducts();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        itemCount: filtered.length + 1 + (provider.myHasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return _buildTipBanner();
                          }
                          if (index == filtered.length + 1) {
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
                          return _buildProductCard(filtered[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _showSearch
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                          onPressed: () {
                            setState(() {
                              _showSearch = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventory', style: AppTextStyles.screenTitle),
                      const SizedBox(height: 2),
                      Consumer<ProductProvider>(
                        builder: (_, provider, __) {
                          final count = provider.myProducts.length;
                          return Text(
                            '$count product${count != 1 ? 's' : ''} listed',
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ],
                  ),
          ),
          if (!_showSearch) ...[
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.search_rounded,
              onTap: () => setState(() => _showSearch = true),
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.refresh_rounded,
              onTap: () => Provider.of<ProductProvider>(context, listen: false).fetchMyProducts(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('All', AppColors.coral, AppColors.ink),
      ('Available', AppColors.successLight, AppColors.successDark),
      ('Low stock', AppColors.warningLight, AppColors.warningDark),
      ('Unavailable', AppColors.mutedLight, AppColors.muted),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (label, bgColor, textColor) = filters[index];
            final isActive = _activeFilter == label;

            return GestureDetector(
              onTap: () => setState(() => _activeFilter = label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? bgColor : bgColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final int stock = product['stockQuantity'] ?? 0;
    final String status = product['productStatus'] ?? 'Available';
    final String image = (product['images'] != null && product['images'].isNotEmpty)
        ? product['images'][0]
        : '';
    final String category = product['category'] ?? '';
    final String title = product['title'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.mutedLight,
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                              const ShimmerSkeleton(height: 56, width: 56, radius: 12),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.muted,
                              size: 20,
                            ),
                          )
                        : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.cardTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildAvailabilityBadge(status, stock),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rs. ${product['price']}${(product['priceUnit'] ?? 'piece') != 'piece' ? '/${_unitLabel(product['priceUnit'] ?? 'piece')}' : ''}',
                        style: AppTextStyles.price.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (category.isNotEmpty) category, '$stock units in stock'].join(' \u00B7 '),
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '$stock units',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildCircularAction(
                      icon: Icons.remove_rounded,
                      onTap: () => _updateStock(product['_id'], stock - 1, status),
                      enabled: stock > 0,
                    ),
                    const SizedBox(width: 8),
                    _buildCircularAction(
                      icon: Icons.add_rounded,
                      onTap: () => _updateStock(product['_id'], stock + 1, status),
                    ),
                    const SizedBox(width: 8),
                    _buildEditButton(product),
                    const SizedBox(width: 8),
                    _buildDeleteButton(product),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(String status, int stock) {
    bool isAvailable = status != 'OutOfStock' && status != 'Inactive' && stock > 0;

    if (isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 10, color: AppColors.successDark),
            const SizedBox(width: 4),
            Text(
              'Available',
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                color: AppColors.successDark,
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String label;

    if (status == 'OutOfStock' || stock <= 0) {
      bgColor = AppColors.dangerLight;
      textColor = AppColors.dangerDark;
      label = 'Out of stock';
    } else {
      bgColor = AppColors.mutedLight;
      textColor = AppColors.muted;
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          fontSize: 10,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCircularAction({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.coralLight : AppColors.mutedLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.coralDark : AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildEditButton(dynamic product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlideFadePageRoute(
          builder: (_) => AddEditProductScreen(product: product),
        ),
      ),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.ink),
      ),
    );
  }

Widget _buildDeleteButton(dynamic product) {
    return GestureDetector(
      onTap: () => _showDeleteConfirmation(product),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.dangerDark),
      ),
    );
  }

  void _showDeleteConfirmation(dynamic product) {
    final title = product['title'] ?? 'this product';
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: Provider.of<ProductProvider>(context, listen: false).checkProductDeletable(product['_id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Row(
                children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Checking...')],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final canDelete = data['data']?['canDelete'] ?? false;
          final reason = data['data']?['reason'] ?? '';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
            title: Text(
              canDelete ? 'Delete product' : 'Cannot delete product',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            ),
            content: Text(
              canDelete
                  ? 'Are you sure you want to delete "$title"? This cannot be undone.'
                  : reason.isEmpty
                      ? 'This product cannot be deleted.'
                      : reason,
              style: AppTextStyles.bodyMuted,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
              ),
              if (canDelete)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final provider = Provider.of<ProductProvider>(context, listen: false);
                    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                    Navigator.pop(context);
                    final success = await provider.deleteProduct(product['_id']);
                    if (!mounted) return;
                    if (success) {
                      vendorProvider.fetchAnalytics();
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? '"$title" deleted'
                            : (provider.error ?? 'Failed to delete product')),
                        backgroundColor: success ? AppColors.success : AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      ),
                    );
                  },
                  child: const Text('Delete'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.coralDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mark products as unavailable when stock runs out so customers don\'t reserve items you can\'t fulfill.',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.coralDark,
                height: 1.5,
              ),
            ),
          ),
        ],
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

    final success = await Provider.of<ProductProvider>(context, listen: false)
        .updateProductStock(id, newStock, newStatus);

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
