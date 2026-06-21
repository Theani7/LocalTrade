import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/review_provider.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).fetchProductReviews(widget.product['_id']);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List images = widget.product['images'] ?? [];
    final int stock = widget.product['stockQuantity'] ?? 0;
    final String status = widget.product['productStatus'] ?? 'Available';
    final bool isOutOfStock = status == 'OutOfStock' || stock <= 0;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isAdmin = user?['role'] == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360.0,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: CloudinaryHelper.getOptimizedUrl(images[index], width: 800),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.background),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.background,
                                child: const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.muted),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.muted),
                        ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 18 : 6,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.coral : AppColors.muted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0.0, -28.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            (widget.product['category'] ?? '').toString(),
                            style: const TextStyle(color: AppColors.coralDark, fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                        ),
                        _buildStatusBadge(status, stock),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Title
                    Text(
                      widget.product['title'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    // Rating
                    if (widget.product['ratingsQuantity'] != null && widget.product['ratingsQuantity'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.product['ratingsAverage']}',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.ink),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${widget.product['ratingsQuantity']} reviews)',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    // Price + stock
                    Row(
                      children: [
                        Text(
                          'Rs. ${widget.product['price']}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.coral),
                        ),
                        if (!isOutOfStock) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stock < 5 ? AppColors.warningLight : AppColors.divider,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$stock left',
                              style: TextStyle(
                                fontSize: 12,
                                color: stock < 5 ? AppColors.warningDark : AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 20),
                    // Description
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    const SizedBox(height: 10),
                    Text(
                      widget.product['description'] ?? 'No description provided.',
                      style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 20),
                    // Vendor
                    const Text('Sold by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        boxShadow: [
                          BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.coralLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.coralDark, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['vendorId']?['shopName'] ?? widget.product['vendorId']?['fullName'] ?? 'Local vendor',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.product['vendorId']?['phone'] ?? '',
                                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.muted.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 20),
                    // Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                        if (!isAdmin)
                          TextButton(
                            onPressed: () => _showReviewModal(context),
                            child: const Text('Write a review', style: TextStyle(fontSize: 13, color: AppColors.coral)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReviewsList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isAdmin
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          Text(
                            'Rs. ${widget.product['price']}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                Provider.of<CartProvider>(context, listen: false).addItem(
                                  widget.product['_id'],
                                  widget.product['title'],
                                  double.parse(widget.product['price'].toString()),
                                  widget.product['images'][0],
                                  widget.product['vendorId']['_id'] ?? widget.product['vendorId'],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: AppColors.ink,
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                        SizedBox(width: 10),
                                        Text('Added to cart', style: TextStyle(fontSize: 13, color: AppColors.surface)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock ? AppColors.divider : AppColors.coral,
                          foregroundColor: isOutOfStock ? AppColors.muted : AppColors.ink,
                          disabledBackgroundColor: AppColors.divider,
                          disabledForegroundColor: AppColors.muted,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out of stock' : 'Add to cart',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReviewsList() {
    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reviews.isEmpty) {
          return const ListSkeleton(itemCount: 3);
        }

        if (provider.reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Center(
              child: Text('No reviews yet. Be the first to review.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: provider.reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = provider.reviews[index];
            final date = DateTime.parse(review['createdAt']);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.coralLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (review['userId']?['fullName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.coralDark, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review['userId']?['fullName'] ?? 'Anonymous', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
                            Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review['rating'] ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.warning,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(review['reviewText'], style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewModal(BuildContext context) {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Write a review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Rate this product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = index + 1),
                        child: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<ReviewProvider>(
                    builder: (context, provider, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (reviewController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please write a review.')),
                                    );
                                    return;
                                  }
                                  final success = await provider.submitReview(
                                    widget.product['_id'],
                                    rating,
                                    reviewController.text.trim(),
                                  );
                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Review submitted'), backgroundColor: AppColors.success),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(provider.error ?? 'Failed to submit'), backgroundColor: AppColors.danger),
                                    );
                                  }
                                },
                          child: provider.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                              : const Text('Submit review'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, int stock) {
    Color bg, fg;
    String label;
    IconData icon;

    if (status == 'OutOfStock' || stock <= 0) {
      bg = AppColors.coralLight;
      fg = AppColors.coralDark;
      label = 'Out of stock';
      icon = Icons.cancel_rounded;
    } else if (stock < 5) {
      bg = AppColors.warningLight;
      fg = AppColors.warningDark;
      label = 'Low stock';
      icon = Icons.access_time_rounded;
    } else {
      bg = AppColors.successLight;
      fg = AppColors.successDark;
      label = 'In stock';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}
