import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:intl/intl.dart';

final _priceFormat = NumberFormat('#,##0');

String _sentenceCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _hasPurchased = false;
  bool _hasReviewed = false;
  String? _selectedSize;
  double _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false)
          .fetchProductReviews(widget.product['_id']);
      _checkPurchaseStatus();
      _checkIfReviewed();
    });
  }

  void _checkIfReviewed() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userId = user?['_id'];
    if (userId == null) return;

    // Wait for reviews to load, then check
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final reviews = Provider.of<ReviewProvider>(context, listen: false).reviews;
      final hasReviewed = reviews.any((r) {
        final rUserId = r['userId']?['_id'] ?? r['userId'];
        return rUserId?.toString() == userId;
      });
      if (mounted) setState(() => _hasReviewed = hasReviewed);
    });
  }

  void _checkPurchaseStatus() {
    if (!AuthGuard.isAuthenticated(context)) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productId = widget.product['_id'];

    if (orderProvider.orders.isEmpty) {
      orderProvider.fetchMyOrders().then((_) {
        _evaluatePurchase(orderProvider.orders, productId);
      });
    } else {
      _evaluatePurchase(orderProvider.orders, productId);
    }
  }

  void _evaluatePurchase(List<dynamic> orders, String productId) {
    final hasBought = orders.any((order) {
      final isDelivered = order['orderStatus'] == 'Delivered';
      final products = order['products'] as List? ?? [];
      final containsProduct = products.any(
          (p) => p['product'] == productId || p['product']?['_id'] == productId);
      return isDelivered && containsProduct;
    });
    if (mounted) setState(() => _hasPurchased = hasBought);
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
    final bool isLowStock = stock > 0 && stock < 5;
    final String category = (widget.product['category'] ?? '').toString();
    final List<String> productSizes = (widget.product['sizes'] as List?)?.cast<String>() ?? [];
    final bool requireSize = productSizes.isNotEmpty;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isAdmin = user?['role'] == 'admin';

    final double price =
        (widget.product['price'] ?? 0).toDouble();
    final String priceUnit = widget.product['priceUnit'] ?? 'piece';
    final String unitLabel = _unitLabel(priceUnit);
    final double? originalPrice =
        widget.product['originalPrice'] != null &&
                widget.product['originalPrice'] > price
            ? (widget.product['originalPrice'] ?? 0).toDouble()
            : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Image carousel
          SliverAppBar(
            expandedHeight: 380,
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
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? Hero(
                          tag: 'product-image-${widget.product['_id'] ?? ''}',
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (page) =>
                                setState(() => _currentPage = page),
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: CloudinaryHelper.getOptimizedUrl(
                                    images[index],
                                    width: 800),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const ShimmerSkeleton(height: 380, width: double.infinity),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.background,
                                  child: const Icon(Icons.inventory_2_outlined,
                                      size: 64, color: AppColors.muted),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Icon(Icons.inventory_2_outlined,
                              size: 80, color: AppColors.muted),
                        ),
                  // Page indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 48,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: isSelected ? 18 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.coral
                                  : AppColors.muted.withValues(alpha: 0.3),
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

          // Product info card
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0.0, -24.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.label.copyWith(color: AppColors.coralDark),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _sentenceCase(widget.product['title'] ?? ''),
                      style: AppTextStyles.screenTitle.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 8),

                    // Rating row
                    if (widget.product['ratingsQuantity'] != null &&
                        widget.product['ratingsQuantity'] > 0)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final rating = (widget.product['ratingsAverage'] ?? 0)
                                .toDouble();
                            return Icon(
                              i < rating.round()
                                  ? Icons.star_rounded
                                  : (i < rating
                                      ? Icons.star_half_rounded
                                      : Icons.star_border_rounded),
                              size: 16,
                              color: AppColors.warning,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.product['ratingsAverage']}',
                            style: AppTextStyles.label.copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.product['ratingsQuantity']} reviews)',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (originalPrice != null)
                              Text(
                                'Rs. ${_priceFormat.format(originalPrice.toInt())}',
                                style: AppTextStyles.bodyMuted.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.muted,
                                ),
                              ),
                            Text(
                              'Rs. ${_priceFormat.format(price.toInt())}${unitLabel.isNotEmpty ? '/$unitLabel' : ''}',
                              style: AppTextStyles.price.copyWith(fontSize: 26, height: 1.1),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (!isOutOfStock)
                          _buildStatusBadge(
                            isLowStock ? 'Low stock' : 'In stock',
                            isLowStock
                                ? AppColors.warningLight
                                : AppColors.successLight,
                            isLowStock
                                ? AppColors.warningDark
                                : AppColors.successDark,
                            isLowStock
                                ? Icons.access_time_rounded
                                : Icons.check_circle_outline_rounded,
                          )
                        else
                          _buildStatusBadge(
                              'Out of stock',
                              AppColors.coralLight,
                              AppColors.coralDark,
                              Icons.cancel_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock warning
                    if (!isOutOfStock && isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.warningDark),
                            const SizedBox(width: 8),
                            Text(
                              'Only $stock left - order soon',
                              style: AppTextStyles.label.copyWith(color: AppColors.warningDark),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),

                  // Size selector
                  if (requireSize) ...[
                    _buildSizeSelector(productSizes),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),
                  ],

                    // Description
                    Text(
                      'Description',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product['description'] ??
                          'No description provided.',
                      style: AppTextStyles.bodyMuted.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),

                    // Vendor
                    Text(
                      'Sold by',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 10),
                    _buildVendorCard(),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),

                    // Reviews header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: AppTextStyles.cardTitle,
                        ),
                        if (!isAdmin && _hasPurchased && !_hasReviewed)
                          TextButton(
                            onPressed: () => _showReviewModal(context),
                            child: Text('Write a review',
                                style: AppTextStyles.caption.copyWith(color: AppColors.coral)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quantity selector
                    Row(
                      children: [
                        Text('Qty',
                            style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final step = _isWeightUnit(priceUnit) ? 0.5 : 1;
                                  final newQty = _quantity - step;
                                  if (newQty >= step) {
                                    setState(() => _quantity = newQty);
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(Icons.remove_rounded,
                                      size: 16,
                                      color: _quantity > 1
                                          ? AppColors.coralDark
                                          : AppColors.muted),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  _quantity % 1 == 0 ? '${_quantity.toInt()}' : _quantity.toStringAsFixed(1),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.cardTitle,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final step = _isWeightUnit(priceUnit) ? 0.5 : 1;
                                  if (_quantity < stock) {
                                    setState(() => _quantity += step);
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(Icons.add_rounded,
                                      size: 16,
                                      color: AppColors.coralDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Price
                        Text(
                          'Rs. ${_priceFormat.format((price * _quantity).toInt())}',
                          style: AppTextStyles.price,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isOutOfStock ||
                                (requireSize && _selectedSize == null))
                            ? null
                            : () {
                                AuthGuard.requireAuth(context, onAuthenticated: () {
                                    Provider.of<CartProvider>(context,
                                          listen: false)
                                        .addItem(
                                      widget.product['_id'],
                                      widget.product['title'],
                                      double.parse(
                                          widget.product['price'].toString()),
                                      (widget.product['images'] != null && (widget.product['images'] as List).isNotEmpty)
                                          ? widget.product['images'][0]
                                          : '',
                                      (widget.product['vendorId'] is Map)
                                          ? (widget.product['vendorId']['_id'] ??
                                              widget.product['vendorId'])
                                          : (widget.product['vendorId'] ?? ''),
                                       priceUnit: widget.product['priceUnit'] ?? 'piece',
                                       size: _selectedSize,
                                     );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor: AppColors.ink,
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              color: AppColors.success,
                                              size: 18),
                                          SizedBox(width: 10),
                                          Text('Added to cart',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.surface)),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isOutOfStock ||
                                  (requireSize && _selectedSize == null))
                              ? AppColors.divider
                              : AppColors.coral,
                          foregroundColor: (isOutOfStock ||
                                  (requireSize && _selectedSize == null))
                              ? AppColors.muted
                              : AppColors.ink,
                          disabledBackgroundColor: AppColors.divider,
                          disabledForegroundColor: AppColors.muted,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.shopping_cart_outlined
                                  : Icons.shopping_cart_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOutOfStock
                                  ? 'Out of stock'
                                  : (requireSize && _selectedSize == null)
                                      ? 'Select a size'
                                      : 'Add to cart',
                              style: AppTextStyles.cardTitle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSizeSelector(List<String> availableSizes) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Size',
                  style: AppTextStyles.cardTitle,
                ),
                if (_selectedSize != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _selectedSize!,
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSizes.map((size) {
                final isSelected = _selectedSize == size;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSize = size);
                    setLocalState(() {});
                  },
                  child: Container(
                    width: 48,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ink : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(
      String label, Color bg, Color fg, IconData icon) {
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
          Text(label,
              style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }

  Widget _buildVendorCard() {
        final vendorData = widget.product['vendorId'];
    final vendorName = (vendorData is Map ? vendorData['shopName'] : null) ??
        (vendorData is Map ? vendorData['fullName'] : null) ??
        'Local vendor';
    final vendorPhone = vendorData is Map ? (vendorData['phone'] ?? '') : '';
    final vendorPhoto = vendorData is Map ? vendorData['photoUrl'] : null;
    final vendorInitial =
        vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'V';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Vendor avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: vendorPhoto != null && vendorPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: CloudinaryHelper.getOptimizedUrl(
                          vendorPhoto,
                          width: 100),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildInitialsAvatar(vendorInitial),
                      errorWidget: (_, __, ___) =>
                          _buildInitialsAvatar(vendorInitial),
                    )
                  : _buildInitialsAvatar(vendorInitial),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendorName,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (vendorPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vendorPhone,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.muted.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initial) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.coralLight,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.coralDark),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final currentUserId = user?['_id'];
    final isVendor = user?['role'] == 'vendor';

    // Check if current user is the vendor of this product
    final vendorData = widget.product['vendorId'];
    final productVendorId = vendorData is Map
        ? (vendorData['_id'] ?? vendorData)
        : vendorData;
    final isProductVendor = isVendor &&
        currentUserId != null &&
        productVendorId != null &&
        currentUserId.toString() == productVendorId.toString();

    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ReviewCardSkeleton(count: 3),
          );
        }

        if (provider.reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.coralLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rate_review_outlined,
                      size: 26, color: AppColors.coral),
                ),
                const SizedBox(height: 14),
                Text(
                  'No reviews yet',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Be the first to share your experience',
                  style: AppTextStyles.caption,
                ),
                if (_hasPurchased && !_hasReviewed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _showReviewModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coral,
                        side: const BorderSide(color: AppColors.coral),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Write a review',
                          style: AppTextStyles.label.copyWith(color: AppColors.coral)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: provider.reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final review = provider.reviews[index];
            final date = DateTime.parse(review['createdAt']);
            final reviewUserId = review['userId']?['_id'] ?? review['userId'];
            final isOwner = currentUserId != null && reviewUserId == currentUserId;
            final vendorReply = review['vendorReply'];
            final hasVendorReply = vendorReply != null &&
                vendorReply['text'] != null &&
                (vendorReply['text'] as String).isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
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
                            (review['userId']?['fullName'] ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.coralDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                review['userId']?['fullName'] ?? 'Anonymous',
                                style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            Text(DateFormat('MMM d, yyyy').format(date),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review['rating']
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 14,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(review['reviewText'] ?? '',
                      style: AppTextStyles.body.copyWith(height: 1.5)),

                  // Vendor reply
                  if (hasVendorReply) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  size: 14, color: AppColors.coralDark),
                              const SizedBox(width: 4),
                              Text(
                                'Vendor reply',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.coralDark,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('MMM d, yyyy').format(
                                    DateTime.parse(vendorReply['repliedAt'])),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vendorReply['text'],
                            style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Owner actions
                  if (isOwner) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildReviewAction(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: () => _showReviewModal(context,
                              editReview: review),
                        ),
                        const SizedBox(width: 12),
                        _buildReviewAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: AppColors.danger,
                          onTap: () => _confirmDeleteReview(review),
                        ),
                      ],
                    ),
                  ],

                  // Vendor reply button (for product vendor, only if no reply yet)
                  if (isProductVendor && !hasVendorReply) ...[
                    const SizedBox(height: 8),
                    _buildReviewAction(
                      icon: Icons.reply_rounded,
                      label: 'Reply as vendor',
                      color: AppColors.coralDark,
                      onTap: () => _showVendorReplyModal(review),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewAction({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c)),
        ],
      ),
    );
  }

  void _confirmDeleteReview(dynamic review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Delete review?', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. Your rating will be removed from the product average.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel', style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final provider = Provider.of<ReviewProvider>(context, listen: false);
                      final success = await provider.deleteReview(
                        review['_id'],
                        widget.product['_id'],
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Review deleted' : (provider.error ?? 'Failed')),
                            backgroundColor: success ? AppColors.success : AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewModal(BuildContext context, {dynamic editReview}) {
    int rating = editReview?['rating'] ?? 5;
    final TextEditingController reviewController = TextEditingController(
      text: editReview?['reviewText'] ?? '',
    );
    final isEditing = editReview != null;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit review' : 'Write a review',
                          style: AppTextStyles.sectionHeading,
                        ),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product name context
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              size: 18, color: AppColors.coralDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _sentenceCase(widget.product['title'] ?? ''),
                              style: AppTextStyles.label.copyWith(color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Star rating
                    Text('Your rating', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ratingLabel(rating),
                      style: AppTextStyles.caption.copyWith(color: AppColors.coralDark),
                    ),
                    const SizedBox(height: 20),

                    // Review text
                    Text('Your review', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      maxLength: 1000,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'What did you like or dislike?',
                        hintStyle: AppTextStyles.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    Consumer<ReviewProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (reviewController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Please write a review')),
                                      );
                                      return;
                                    }
                                    AuthGuard.requireAuth(context, onAuthenticated: () async {
                                      bool success;
                                      if (isEditing) {
                                        success = await provider.updateReview(
                                          editReview['_id'],
                                          widget.product['_id'],
                                          rating: rating,
                                          reviewText: reviewController.text.trim(),
                                        );
                                      } else {
                                        success = await provider.submitReview(
                                          widget.product['_id'],
                                          rating,
                                          reviewController.text.trim(),
                                        );
                                      }
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(isEditing
                                                  ? 'Review updated'
                                                  : 'Review submitted'),
                                              backgroundColor: AppColors.success),
                                        );
                                      } else if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(provider.error ?? 'Failed'),
                                              backgroundColor: AppColors.danger),
                                        );
                                      }
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: AppColors.ink,
                              disabledBackgroundColor: AppColors.divider,
                              disabledForegroundColor: AppColors.muted,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink))
                                : Text(
                                    isEditing ? 'Update review' : 'Submit review',
                                    style: AppTextStyles.cardTitle,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  void _showVendorReplyModal(dynamic review) {
    final TextEditingController replyController = TextEditingController();

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reply to review',
                            style: AppTextStyles.sectionHeading),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Original review preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < review['rating']
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: AppColors.warning,
                                  size: 12,
                                );
                              }),
                              const SizedBox(width: 6),
                              Text(
                                review['userId']?['fullName'] ?? 'Customer',
                                style: AppTextStyles.caption
                                    .copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review['reviewText'] ?? '',
                            style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Your reply', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: replyController,
                      maxLines: 3,
                      maxLength: 500,
                      style: AppTextStyles.body.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Thank the customer or address their feedback...',
                        hintStyle: AppTextStyles.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Consumer<ReviewProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (replyController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Please write a reply')),
                                      );
                                      return;
                                    }
                                    final success = await provider.addVendorReply(
                                      review['_id'],
                                      replyController.text.trim(),
                                    );
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                      // Refresh reviews
                                      provider.fetchProductReviews(widget.product['_id']);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Reply submitted'),
                                            backgroundColor: AppColors.success),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(provider.error ?? 'Failed'),
                                            backgroundColor: AppColors.danger),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: AppColors.ink,
                              disabledBackgroundColor: AppColors.divider,
                              disabledForegroundColor: AppColors.muted,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink))
                                : Text('Submit reply',
                                    style: AppTextStyles.cardTitle),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _unitLabel(String unit) {
    switch (unit) {
      case 'kg': return 'kg';
      case '100g': return '100g';
      case 'liter': return 'L';
      case 'dozen': return 'dozen';
      case 'packet': return 'pkt';
      case 'bundle': return 'bundle';
      default: return '';
    }
  }

  bool _isWeightUnit(String unit) => unit == 'kg' || unit == '100g' || unit == 'liter';
}
