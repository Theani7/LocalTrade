import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'customer_orders_screen.dart';
import 'notification_screen.dart';
import 'customer_profile_screen.dart';
import '../auth/login_screen.dart';
import '../common/feedback_submission_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
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
    'Others'
  ];

  final Map<String, String> _sortOptions = {
    'newest': 'Newest First',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
    'availability': 'Availability',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
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
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        onRefresh: () async => _fetchProducts(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterBar()),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _buildProductGrid(),
            _buildLoadMoreIndicator(),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'All': return '🌎';
      case 'Vegetables': return '🥦';
      case 'Dairy': return '🥛';
      case 'Handicrafts': return '🏺';
      case 'Clothing': return '👕';
      case 'Local Goods': return '🌾';
      case 'Tailoring': return '✂️';
      case 'Others': return '📦';
      default: return '📦';
    }
  }

  Widget _buildSliverAppBar() {
    final user = Provider.of<AuthProvider>(context).user;
    
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: AppTheme.surfaceColor,
      title: const Text(
        'LocalTrade',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Hello, ${user?['fullName']?.split(' ')[0] ?? 'Guest'} 👋',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discover Local Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen())),
          icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.textPrimary),
        ),
        _buildNotificationBadge(),
        _buildCartBadge(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary),
        ),
        Consumer<NotificationProvider>(
          builder: (context, provider, _) => provider.unreadCount > 0 ? Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${provider.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ) : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildCartBadge() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimary),
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) => cart.itemCount > 0 ? Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${cart.itemCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ) : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.softShadow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _fetchProducts(),
          decoration: InputDecoration(
            hintText: 'Search products, categories, stores...',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 24),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _fetchProducts();
                  },
                )
              : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedLocation != null || _selectedSort != null || _showAll || _searchController.text.isNotEmpty || _selectedCategory != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        onPressed: _clearAllFilters,
                        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  _buildFilterChip(
                    label: _selectedLocation ?? 'Location',
                    isSelected: _selectedLocation != null,
                    onTap: _showLocationFilter,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedSort != null ? _sortOptions[_selectedSort!]! : 'Sort',
                    isSelected: _selectedSort != null,
                    onTap: _showSortFilter,
                    icon: Icons.sort,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Include Unavailable'),
                    selected: _showAll,
                    onSelected: (val) {
                      setState(() => _showAll = val);
                      _fetchProducts();
                    },
                    showCheckmark: false,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: _showAll ? Colors.white : AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap, required IconData icon}) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  void _showLocationFilter() {
    final controller = TextEditingController(text: _selectedLocation);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter city, area, or address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onSubmitted: (val) {
                setState(() => _selectedLocation = val.trim().isEmpty ? null : val.trim());
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedLocation = controller.text.trim().isEmpty ? null : controller.text.trim());
                  _fetchProducts();
                  Navigator.pop(context);
                },
                child: const Text('Apply Filter'),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._sortOptions.entries.map((entry) => ListTile(
              title: Text(entry.value, style: TextStyle(
                fontWeight: _selectedSort == entry.key ? FontWeight.bold : FontWeight.normal,
                color: _selectedSort == entry.key ? AppTheme.primaryColor : AppTheme.textPrimary,
              )),
              trailing: _selectedSort == entry.key ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
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

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final emoji = _getCategoryEmoji(category);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
                _fetchProducts();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                    : AppTheme.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.60, // Adjusted to prevent overflow with dynamic width
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSkeletonCard(),
                childCount: 6,
              ),
            ),
          );
        }

        if (provider.error != null && provider.products.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Oops!',
              message: provider.error!,
              onAction: () => _fetchProducts(),
              actionLabel: 'Try Again',
            ),
          );
        }

        if (provider.products.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No Products Found',
              message: 'Try searching for something else or browse another category.',
              onAction: _clearAllFilters,
              actionLabel: 'View All Products',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.60,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: provider.products[index]),
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
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!provider.hasMore && provider.products.isNotEmpty) {
           return SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 24),
               child: Center(child: Text('You\'ve reached the end! 🏁', style: TextStyle(color: Colors.grey[500]))),
             ),
           );
        }
        return const SliverToBoxAdapter(child: SizedBox(height: 32));
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, minimumSize: const Size(100, 45)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final int stock = product['stockQuantity'] ?? 0;
    final String status = product['productStatus'] ?? 'Available';
    final bool isOutOfStock = status == 'OutOfStock' || stock <= 0;
    final String image = (product['images'] != null && product['images'].isNotEmpty) ? product['images'][0] : '';
    final String vendorId = product['vendorId'] is Map ? (product['vendorId']['_id'] ?? '') : (product['vendorId'] ?? '');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03), width: 1.2),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: image.isNotEmpty
                          ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                          : const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        'Rs. ${product['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['category'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product['ratingsQuantity'] != null && product['ratingsQuantity'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${product['ratingsAverage']}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product['ratingsQuantity']})',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product['vendorName'] ?? product['vendorId']?['shopName'] ?? 'Local Vendor',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isOutOfStock)
                          GestureDetector(
                            onTap: () {
                              Provider.of<CartProvider>(context, listen: false).addItem(
                                product['_id'],
                                product['title'],
                                double.parse(product['price'].toString()),
                                image,
                                vendorId,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: AppTheme.primaryColor,
                                  content: Text('Added ${product['title']} to cart!'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
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
