import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'customer_orders_screen.dart';
import 'notification_screen.dart';
import 'customer_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;

  String _selectedCategory = 'All';
  String? _selectedLocation;
  String? _selectedSort;
  bool _showAll = false;

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Dairy',
    'Handicrafts',
    'Clothing',
    'Local Goods',
    'Tailoring',
    'Others',
  ];

  final Map<String, String> _sortOptions = {
    'newest': 'Newest first',
    'price_low': 'Price: low to high',
    'price_high': 'Price: high to low',
    'availability': 'Availability',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(refresh: false);
    }
  }

  void _fetchProducts({bool refresh = true}) {
    Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      search: _searchController.text,
      category: _selectedCategory,
      location: _selectedLocation,
      sort: _selectedSort,
      showAll: _showAll,
      refresh: refresh,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLocation = null;
      _selectedSort = null;
      _showAll = false;
      _searchController.clear();
    });
    Provider.of<ProductProvider>(context, listen: false).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentNavIndex == 0 ? _buildHomeBody() : const SizedBox(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (i) {
            if (i == 1) {
              // Search/discover - same screen
            } else if (i == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()));
            } else if (i == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen()));
            }
            setState(() => _currentNavIndex = i);
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.muted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    final user = Provider.of<AuthProvider>(context).user;
    final name = user?['fullName']?.split(' ')[0] ?? 'Guest';

    return RefreshIndicator(
      onRefresh: () async => _fetchProducts(),
      color: AppColors.coral,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Discover local products',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                      ),
                      const SizedBox(width: 8),
                      _buildCartButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchProducts(),
                style: const TextStyle(color: AppColors.ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search products, categories...',
                  hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            _fetchProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _fetchProducts();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.coral : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? AppColors.coral : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Filter bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedLocation != null || _selectedSort != null || _showAll || _searchController.text.isNotEmpty || _selectedCategory != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: _clearAllFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, size: 14, color: AppColors.coralDark),
                              SizedBox(width: 4),
                              Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.coralDark)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  _buildFilterChip(
                    label: _selectedLocation ?? 'Location',
                    isSelected: _selectedLocation != null,
                    onTap: _showLocationFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedSort != null ? _sortOptions[_selectedSort!]! : 'Sort',
                    isSelected: _selectedSort != null,
                    onTap: _showSortFilter,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _showAll = !_showAll);
                      _fetchProducts();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showAll ? AppColors.coralLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _showAll ? AppColors.coralLight : AppColors.divider),
                      ),
                      child: Text(
                        'Include unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _showAll ? AppColors.coralDark : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Products grid
          _buildProductGrid(),

          // Load more
          _buildLoadMoreIndicator(),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: AppColors.ink),
      ),
    );
  }

  Widget _buildCartButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.ink),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) => cart.itemCount > 0
                ? Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coralLight : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? AppColors.coralLight : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : Icons.tune_rounded,
              size: 14,
              color: isSelected ? AppColors.coralDark : AppColors.muted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.coralDark : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationFilter() {
    final controller = TextEditingController(text: _selectedLocation);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter city or area', prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.muted)),
              onSubmitted: (val) {
                setState(() => _selectedLocation = val.trim().isEmpty ? null : val.trim());
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedLocation = controller.text.trim().isEmpty ? null : controller.text.trim());
                  _fetchProducts();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 16),
            ..._sortOptions.entries.map((entry) => ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: _selectedSort == entry.key ? FontWeight.w500 : FontWeight.w400,
                      color: _selectedSort == entry.key ? AppColors.coral : AppColors.ink,
                    ),
                  ),
                  trailing: _selectedSort == entry.key ? const Icon(Icons.check_rounded, color: AppColors.coral) : null,
                  onTap: () {
                    setState(() => _selectedSort = entry.key);
                    _fetchProducts();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _ProductCardSkeleton(),
                childCount: 6,
              ),
            ),
          );
        }

        if (provider.error != null && provider.products.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: provider.error!,
              onAction: () => _fetchProducts(),
              actionLabel: 'Try again',
            ),
          );
        }

        if (provider.products.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              message: 'Try searching for something else or browse another category.',
              onAction: _clearAllFilters,
              actionLabel: 'View all products',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _AmazonProductCard(
                product: provider.products[index],
                onAddToCart: () {
                  final p = provider.products[index];
                  final image = (p['images'] != null && p['images'].isNotEmpty) ? p['images'][0] : '';
                  final vendorId = p['vendorId'] is Map ? (p['vendorId']['_id'] ?? '') : (p['vendorId'] ?? '');
                  Provider.of<CartProvider>(context, listen: false).addItem(
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
              ),
              childCount: provider.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isFetchingMore) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                ),
              ),
            ),
          );
        }
        if (!provider.hasMore && provider.products.isNotEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('You have reached the end', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox(height: 32));
      },
    );
  }
}

// Amazon-inspired product card
class _AmazonProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onAddToCart;

  const _AmazonProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final int stock = product['stockQuantity'] ?? 0;
    final String status = product['productStatus'] ?? 'Available';
    final bool isOutOfStock = status == 'OutOfStock' || stock <= 0;
    final String image = (product['images'] != null && product['images'].isNotEmpty) ? product['images'][0] : '';
    final String vendorName = product['vendorName'] ?? product['vendorId']?['shopName'] ?? '';
    final String category = (product['category'] ?? '').toString();
    final bool hasRating = product['ratingsQuantity'] != null && product['ratingsQuantity'] > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
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
            // Image area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: CloudinaryHelper.getOptimizedUrl(image, width: 400),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.background),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.background,
                                child: const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 32),
                              ),
                            )
                          : Container(
                              color: AppColors.background,
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 32),
                            ),
                    ),
                  ),
                  // Category tag
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.muted),
                        ),
                      ),
                    ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            // Info area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor name
                    if (vendorName.isNotEmpty)
                      Text(
                        vendorName,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
                          ...List.generate(5, (i) {
                            final rating = (product['ratingsAverage'] ?? 0).toDouble();
                            return Icon(
                              i < rating.round() ? Icons.star_rounded : (i < rating ? Icons.star_half_rounded : Icons.star_border_rounded),
                              size: 12,
                              color: AppColors.warning,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '(${product['ratingsQuantity']})',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Price + cart button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rs.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink),
                              ),
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
                              child: const Icon(Icons.add_shopping_cart_rounded, size: 18, color: AppColors.ink),
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

// Skeleton for Amazon-style card
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
                  Container(width: double.infinity, height: 10, color: AppColors.divider),
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
