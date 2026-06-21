import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
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
    final vendorName =
        widget.vendor['shopName'] ?? widget.vendor['fullName'] ?? 'Vendor shop';
    final location = widget.vendor['address'] ?? '';
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
                      (context, index) => const _ProductCardSkeleton(),
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
                      return _AmazonProductCard(
                        product: product,
                        onAddToCart: () {
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

// ── Amazon-style product card ───────────────────────────────────────────
class _AmazonProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onAddToCart;

  const _AmazonProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final int stock = product['stockQuantity'] ?? 0;
    final String status = product['productStatus'] ?? 'Available';
    final bool isOutOfStock = status == 'OutOfStock' || stock <= 0;
    final String image =
        (product['images'] != null && product['images'].isNotEmpty)
            ? product['images'][0]
            : '';
    final String vendorName = product['vendorName'] ??
        product['vendorId']?['shopName'] ??
        '';
    final String category = (product['category'] ?? '').toString();
    final bool hasRating =
        product['ratingsQuantity'] != null && product['ratingsQuantity'] > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2B2620),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: CloudinaryHelper.getOptimizedUrl(
                                image,
                                width: 400,
                              ),
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: AppColors.background),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.background,
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.muted,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.background,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.muted,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  // Category tag
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info area ──
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor name
                    if (vendorName.isNotEmpty)
                      Text(
                        vendorName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (vendorName.isNotEmpty) const SizedBox(height: 2),

                    // Product name
                    Text(
                      product['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    if (hasRating)
                      Row(
                        children: [
                          Text(
                            '${product['ratingsAverage'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product['ratingsQuantity']})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Price + Add to cart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product['originalPrice'] != null &&
                                  product['originalPrice'] > product['price'])
                                Text(
                                  'Rs. ${product['originalPrice']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.muted,
                                  ),
                                ),
                              Row(
                                children: [
                                  const Text(
                                    'Rs.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${product['price']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isOutOfStock)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 18,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton card ───────────────────────────────────────────────────────
class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 60, height: 8, color: AppColors.divider),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 10,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 10, color: AppColors.divider),
                  const Spacer(),
                  Container(width: 40, height: 14, color: AppColors.divider),
                  const SizedBox(height: 2),
                  Container(width: 60, height: 18, color: AppColors.divider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
