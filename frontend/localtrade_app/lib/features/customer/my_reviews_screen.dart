import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/review_provider.dart';
import '../../widgets/skeleton_loaders.dart';
import 'product_details_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).fetchMyReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Reviews', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myReviews.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.screenPaddingH),
              child: ListSkeleton(itemCount: 4),
            );
          }

          if (provider.myReviews.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
            itemCount: provider.myReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = provider.myReviews[index];
              return _buildReviewCard(review);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined,
                  size: 32, color: AppColors.coral),
            ),
            const SizedBox(height: 20),
            Text(
              'No reviews yet',
              style: AppTextStyles.sectionHeading,
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews you write will appear here. Purchase a product and share your experience!',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final product = review['productId'];
    final productTitle = product is Map ? (product['title'] ?? 'Product') : 'Product';
    final productImages = product is Map ? (product['images'] as List? ?? []) : [];
    final date = DateTime.parse(review['createdAt']);
    final vendorReply = review['vendorReply'];
    final hasVendorReply = vendorReply != null &&
        vendorReply['text'] != null &&
        (vendorReply['text'] as String).isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (product is Map) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: productImages.isNotEmpty
                      ? Image.network(
                          productImages[0].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: AppColors.muted),
                        )
                      : const Icon(Icons.inventory_2_outlined,
                          size: 20, color: AppColors.muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productTitle,
                        style: AppTextStyles.label.copyWith(color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reviewed ${DateFormat('MMM d, yyyy').format(date)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.muted.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 12),

            // Stars + rating
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < review['rating']
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.warning,
                    size: 16,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  _ratingLabel(review['rating']),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.coralDark, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Review text
            Text(
              review['reviewText'] ?? '',
              style: AppTextStyles.body.copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Vendor reply indicator
            if (hasVendorReply) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 14, color: AppColors.coralDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Vendor replied',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.coralDark,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very good';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}
