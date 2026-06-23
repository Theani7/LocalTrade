import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loaders.dart';

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
    final vendorName =
        widget.vendor['shopName'] ?? widget.vendor['fullName'] ?? 'Vendor shop';
    final rawAddress = widget.vendor['address'];
    String location = '';
    if (rawAddress is Map) {
      final parts = <String>[
        if ((rawAddress['street'] ?? '').isNotEmpty) rawAddress['street'],
        if ((rawAddress['city'] ?? '').isNotEmpty) rawAddress['city'],
        if ((rawAddress['state'] ?? '').isNotEmpty) rawAddress['state'],
      ];
      location = parts.join(', ');
    } else {
      location = rawAddress?.toString() ?? '';
    }
    final logoUrl = widget.vendor['shopLogo'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A2B2620),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Vendor avatar
                    logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: CachedNetworkImage(
                              imageUrl: CloudinaryHelper.getOptimizedUrl(
                                logoUrl,
                                width: 128,
                              ),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildAvatarPlaceholder(),
                              errorWidget: (context, url, error) =>
                                  _buildAvatarPlaceholder(),
                            ),
                          )
                        : _buildAvatarPlaceholder(),
                    const SizedBox(height: 10),
                    // Vendor name
                    Text(
                      vendorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Location
                    if (location.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Products header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.coralLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 15,
                      color: AppColors.coralDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Consumer<ProductProvider>(
                    builder: (context, provider, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mutedLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${provider.products.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Product grid ──────────────────────────────────────
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              // Loading skeleton
              if (provider.isLoading && provider.products.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductCardSkeleton(),
                      childCount: 6,
                    ),
                  ),
                );
              }

              // Empty state
              if (provider.products.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: AppColors.divider,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This vendor hasn\'t added any products.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Product grid
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = provider.products[index];
                      return ProductCard(
                        product: product,
                        onAddToCart: () {
                          AuthGuard.requireAuth(context, onAuthenticated: () {
                            final p = provider.products[index];
                            final image =
                                (p['images'] != null && p['images'].isNotEmpty)
                                    ? p['images'][0]
                                    : '';
                            final vendorId = p['vendorId'] is Map
                                ? (p['vendorId']['_id'] ?? '')
                                : (p['vendorId'] ?? '');
                            Provider.of<CartProvider>(context, listen: false)
                                .addItem(
                              p['_id'],
                              p['title'],
                              double.parse(p['price'].toString()),
                              image,
                              vendorId,
                              priceUnit: p['priceUnit'] ?? 'piece',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.ink,
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                      size: 18,
                                    ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Added to cart',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          });
                        },
                      );
                    },
                    childCount: provider.products.length,
                  ),
                ),
              );
            },
          ),

          // Bottom spacer
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.coralLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.storefront_rounded,
        size: 32,
        color: AppColors.coralDark,
      ),
    );
  }
}
