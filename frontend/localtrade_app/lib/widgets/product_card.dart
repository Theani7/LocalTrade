import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cloudinary_helper.dart';
import '../features/customer/product_details_screen.dart';

final _priceFormat = NumberFormat('#,##0');

class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback? onAddToCart;
  final bool showCartButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.showCartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final int stock = product['stockQuantity'] ?? 0;
    final String status = product['productStatus'] ?? 'Available';
    final bool isOutOfStock = status == 'OutOfStock' || stock <= 0;
    final String image =
        (product['images'] != null && product['images'].isNotEmpty)
            ? product['images'][0]
            : '';
    final String category = (product['category'] ?? '').toString();
    final String title = product['title'] ?? '';
    final double price = (product['price'] ?? 0).toDouble();
    final double? originalPrice = product['originalPrice'] != null &&
            product['originalPrice'] > price
        ? (product['originalPrice'] ?? 0).toDouble()
        : null;
    final bool hasRating =
        product['ratingsQuantity'] != null && product['ratingsQuantity'] > 0;
    final double rating = (product['ratingsAverage'] ?? 0).toDouble();
    final int reviewCount = product['ratingsQuantity'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2B2620),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area — padded rounded rect ──
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Gray backdrop + centered image
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFFF2F2F2),
                        child: image.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      CloudinaryHelper.getOptimizedUrl(
                                    image,
                                    width: 400,
                                  ),
                                  fit: BoxFit.contain,
                                  memCacheWidth: 400,
                                  placeholder: (_, __) => const Center(
                                    child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 36,
                                        color: AppColors.divider),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      const Center(
                                    child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 36,
                                        color: AppColors.divider),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 36,
                                    color: AppColors.divider),
                              ),
                      ),
                      // Category badge
                      if (category.isNotEmpty)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.ink
                                          .withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
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
                          ),
                        ),
                      // Out of stock overlay
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            color:
                                AppColors.ink.withValues(alpha: 0.55),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius:
                                      BorderRadius.circular(6),
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
              ),
            ),

            // ── Info area ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: badge + heart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category or vendor tag
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.coralDark,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      // Wishlist heart
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 22,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Rating row
                  if (hasRating)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Price + Buy Now
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            if (originalPrice != null)
                              Text(
                                'Rs. ${_priceFormat.format(originalPrice.toInt())}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  decoration:
                                      TextDecoration.lineThrough,
                                  decorationColor: AppColors.muted,
                                ),
                              ),
                            Text(
                              'Rs. ${_priceFormat.format(price.toInt())}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.coral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showCartButton &&
                          !isOutOfStock &&
                          onAddToCart != null)
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
