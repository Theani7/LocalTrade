import 'package:flutter/material.dart';
import '../../core/network/admin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/skeleton_loaders.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final String productId;

  const AdminProductDetailScreen({super.key, required this.productId});

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _adminService.getProduct(widget.productId);
      setState(() { _product = result['data']['product']; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Product details', style: AppTextStyles.sectionHeading),
        centerTitle: false,
      ),
      body: _isLoading
          ? const ProductDetailSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodyMuted),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadProduct, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final product = _product!;
    final vendor = product['vendorId'] as Map<String, dynamic>?;
    final images = (product['images'] as List?) ?? [];
    final stock = product['stockQuantity'] ?? 0;
    final status = product['productStatus'] ?? 'Unknown';
    final price = product['price'] ?? 0;
    final originalPrice = product['originalPrice'];
    final rating = product['ratingsAverage'] ?? 0.0;
    final ratingCount = product['ratingsQuantity'] ?? 0;
    final createdAt = product['createdAt'];
    final updatedAt = product['updatedAt'];
    final category = product['category'] ?? '';
    final location = product['location'] ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product images
          if (images.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(images[index], fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.muted)),
            ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + category
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['title'] ?? '', style: AppTextStyles.screenTitle),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.blueLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.blueDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price card
                _buildCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price', style: AppTextStyles.label),
                        Row(
                          children: [
                            Text('Rs. $price', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink)),
                            if (originalPrice != null) ...[
                              const SizedBox(width: 8),
                              Text('Rs. $originalPrice', style: TextStyle(fontSize: 13, color: AppColors.muted, decoration: TextDecoration.lineThrough)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stock + Status card
                _buildCard(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInfoTile('Stock', '$stock units', stock > 0 ? AppColors.successDark : AppColors.danger)),
                        Container(width: 1, height: 30, color: AppColors.divider),
                        Expanded(child: _buildInfoTile('Status', status, _statusColor(status))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Rating card
                _buildCard(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                        const SizedBox(width: 6),
                        Text('($ratingCount ratings)', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description card
                _buildCard(
                  children: [
                    Text('Description', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Text(product['description'] ?? 'No description', style: AppTextStyles.bodyMuted),
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                if (location.isNotEmpty) ...[
                  _buildCard(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(location, style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Vendor info card
                if (vendor != null) ...[
                  Text('Vendor information', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 8),
                  _buildCard(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                            child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.coralDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vendor['shopName'] ?? vendor['fullName'] ?? '', style: AppTextStyles.cardTitle),
                                const SizedBox(height: 2),
                                Text(vendor['email'] ?? '', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (vendor['phone'] != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.phone_outlined, 'Phone', vendor['phone']),
                      ],
                      if (vendor['businessDescription'] != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.info_outline, 'About', vendor['businessDescription']),
                      ],
                      if (vendor['categories'] != null && (vendor['categories'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (vendor['categories'] as List).map<Widget>((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.coralLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(c.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.coralDark)),
                          )).toList(),
                        ),
                      ],
                      if (vendor['address'] != null) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.home_outlined, 'Address', _formatAddress(vendor['address'])),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Timestamps card
                _buildCard(
                  children: [
                    if (createdAt != null) _buildDetailRow(Icons.access_time_rounded, 'Created', _formatDate(createdAt)),
                    if (createdAt != null && updatedAt != null) const SizedBox(height: 6),
                    if (updatedAt != null) _buildDetailRow(Icons.update_rounded, 'Updated', _formatDate(updatedAt)),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppColors.muted.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available': return AppColors.successDark;
      case 'OutOfStock': return AppColors.danger;
      case 'Inactive': return AppColors.muted;
      default: return AppColors.muted;
    }
  }

  String _formatAddress(dynamic addr) {
    if (addr == null) return '';
    final parts = [addr['street'], addr['city'], addr['state'], addr['zipCode']].where((e) => e != null && e.toString().isNotEmpty).map((e) => e.toString());
    return parts.join(', ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays < 1) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
      return '${(diff.inDays / 365).floor()} years ago';
    } catch (_) {
      return dateStr;
    }
  }
}
