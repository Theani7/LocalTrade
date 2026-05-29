import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/theme/app_theme.dart';
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
    Future.microtask(() {
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

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
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
                              placeholder: (context, url) => Container(color: Colors.grey[100]),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image, size: 100, color: Colors.grey),
                        ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 45,
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
                              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.6),
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
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0.0, -32.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (widget.product['category'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                        _buildStatusBadge(status, stock),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.product['title'],
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.2, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 12),
                    
                    // Rating Overview
                    if (widget.product['ratingsQuantity'] != null && widget.product['ratingsQuantity'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.product['ratingsAverage']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${widget.product['ratingsQuantity']} reviews)',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                      
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Rs. ${widget.product['price']}',
                          style: const TextStyle(
                            fontSize: 28,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (!isOutOfStock) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stock < 5 ? AppTheme.errorColor.withOpacity(0.08) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$stock units left',
                              style: TextStyle(
                                fontSize: 12,
                                color: stock < 5 ? AppTheme.errorColor : AppTheme.textSecondary,
                                fontWeight: stock < 5 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isOutOfStock && stock < 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              'Low stock! Grab it before it\'s gone.',
                              style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    ),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product['description'] ?? 'No description provided.',
                      style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textSecondary),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    ),
                    const Text(
                      'Sold By',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.03)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['vendorId']?['shopName'] ?? widget.product['vendorId']?['fullName'] ?? 'Local Vendor',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary, letterSpacing: -0.3),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 13, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.product['vendorId']?['phone'] ?? 'No phone provided',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              foregroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                            onPressed: () {
                              final phone = widget.product['vendorId']?['phone'];
                              if (phone != null && phone.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Contact number: $phone (Copied to Clipboard)'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }, 
                          ),
                        ],
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    ),
                    
                    // --- Reviews Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Reviews',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.3),
                        ),
                        TextButton.icon(
                          onPressed: () => _showReviewModal(context),
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Write a Review'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReviewsList(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(color: AppTheme.textLight, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${widget.product['price']}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isOutOfStock ? null : AppTheme.primaryGradient,
                    color: isOutOfStock ? Colors.grey[300] : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isOutOfStock ? null : [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isOutOfStock ? null : () {
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
                          backgroundColor: AppTheme.textPrimary,
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Added to your cart', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    label: Text(
                      isOutOfStock ? 'OUT OF STOCK' : 'Add to Cart',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
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
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: provider.reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = provider.reviews[index];
            final date = DateTime.parse(review['createdAt']);
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (review['userId']?['fullName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review['userId']?['fullName'] ?? 'Anonymous User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review['rating'] ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review['reviewText'], style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewModal(BuildContext context) {
    int _rating = 5;
    final TextEditingController _reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      const Text('Write a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Rate this product', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () => setModalState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience with this product...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<ReviewProvider>(
                    builder: (context, provider, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : () async {
                            if (_reviewController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a review.')));
                              return;
                            }
                            
                            final success = await provider.submitReview(
                              widget.product['_id'],
                              _rating,
                              _reviewController.text.trim()
                            );
                            
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green));
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to submit review.'), backgroundColor: AppTheme.errorColor));
                            }
                          },
                          child: provider.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildStatusBadge(String status, int stock) {
    Color color = Colors.green;
    String label = 'In Stock';

    if (status == 'OutOfStock' || stock <= 0) {
      color = AppTheme.errorColor;
      label = 'Out of Stock';
    } else if (stock < 5) {
      color = Colors.orange;
      label = 'Low Stock';
    }

    return Row(
      children: [
        Icon(
          status == 'OutOfStock' || stock <= 0 ? Icons.cancel : Icons.check_circle,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
