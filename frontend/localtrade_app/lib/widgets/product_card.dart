import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cloudinary_helper.dart';
import '../core/utils/app_animations.dart';
import '../features/customer/product_details_screen.dart';

final _priceFormat = NumberFormat('#,##0');

String _sentenceCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

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
    final String description = product['description'] ?? '';
    final double price = (product['price'] ?? 0).toDouble();
    final double? originalPrice = product['originalPrice'] != null &&
            product['originalPrice'] > price
        ? (product['originalPrice'] ?? 0).toDouble()
        : null;
    final bool hasRating =
        product['ratingsQuantity'] != null && product['ratingsQuantity'] > 0;
    final double rating = (product['ratingsAverage'] ?? 0).toDouble();
    final int reviewCount = product['ratingsQuantity'] ?? 0;
    final String productId = product['_id'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlideFadePageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
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
            // ── Image area with Hero ──
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Hero(
                        tag: 'product-image-$productId',
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: CloudinaryHelper.getOptimizedUrl(
                                  image,
                                  width: 400,
                                ),
                                fit: BoxFit.cover,
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
                                  child: const Icon(Icons.inventory_2_outlined,
                                      size: 32, color: AppColors.divider),
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
                  // Category badge with dark scrim
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x59000000),
                            ],
                          ),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    _sentenceCase(title),
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
                  if (hasRating)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
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
                    ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                                'Rs. ${_priceFormat.format(originalPrice.toInt())}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.muted,
                                ),
                              ),
                            Text(
                              'Rs. ${_priceFormat.format(price.toInt())}',
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
                      if (showCartButton &&
                          !isOutOfStock &&
                          onAddToCart != null)
                        _CartButton(onTap: onAddToCart!),
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

/// Cart button with scale tap animation.
class _CartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CartButton({required this.onTap});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (!reduceMotion) _ctrl.forward(from: 0.0);
      },
      child: TickBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
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
          );
        },
      ),
    );
  }
}
