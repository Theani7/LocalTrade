import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../providers/product_provider.dart';
import '../../widgets/skeleton_loaders.dart';
import 'product_details_screen.dart';

class VendorShopScreen extends StatefulWidget {
  final dynamic vendor;
  const VendorShopScreen({super.key, required this.vendor});

  @override
  State<VendorShopScreen> createState() => _VendorShopScreenState();
}

class _VendorShopScreenState extends State<VendorShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(
        vendorId: widget.vendor['_id'],
        showAll: true,
        refresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorName = widget.vendor['shopName'] ?? widget.vendor['fullName'] ?? 'Vendor shop';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(vendorName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 16)),
              background: Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_rounded, size: 36, color: AppColors.coralDark),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.vendor['address'] ?? '',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.coral),
                  const SizedBox(width: 8),
                  const Text('Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const Spacer(),
                  Consumer<ProductProvider>(
                    builder: (context, provider, _) => Text(
                      '${provider.products.length} items',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductCardSkeleton(),
                      childCount: 6,
                    ),
                  ),
                );
              }

              if (provider.products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No products yet', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = provider.products[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product))),
                        child: Container(
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
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                                  child: CachedNetworkImage(
                                    imageUrl: CloudinaryHelper.getOptimizedUrl(product['images'][0], width: 300),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(color: AppColors.background),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.background,
                                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 28),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['title'],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs. ${product['price']}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.coral),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: provider.products.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
