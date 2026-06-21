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
    final String vendorName = product['vendorName'] ??
        product['vendorId']?['shopName'] ??
        '';
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
            // ── Image area with uniform padding ──
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // White backdrop + padded image
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: CloudinaryHelper.getOptimizedUrl(
                                  image,
                                  width: 400,
                                ),
                                fit: BoxFit.contain,
                                memCacheWidth: 400,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: Icon(Icons.inventory_2_outlined,
                                        size: 32, color: AppColors.divider),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                      color: AppColors.divider),
                                ),
                              )
                            : Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.inventory_2_outlined,
                                    size: 32, color: AppColors.divider),
                              ),
                      ),
                    ),
                  ),
                  // Category badge with backdrop blur + shadow
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.08),
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
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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

                    // Product title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Trust signal: rating + review count
                    if (hasRating)
                      Row(
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
                              size: 13, color: AppColors.warning),
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

                    const Spacer(),

                    // Price + Add to cart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (originalPrice != null)
                                Text(
                                  'Rs.${_priceFormat.format(originalPrice.toInt())}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.muted,
                                  ),
                                ),
                              Text(
                                'Rs.${_priceFormat.format(price.toInt())}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showCartButton && !isOutOfStock && onAddToCart != null)
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
                                  color: AppColors.ink),
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
