import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/cart_fly_animation.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loaders.dart';
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
  final GlobalKey _cartIconKey = GlobalKey();
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
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      }
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
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentNavIndex == 0 ? _buildHomeBody() : const SizedBox(),
      bottomNavigationBar: AppBottomNav(
          currentIndex: _currentNavIndex,
          cartItemCount: cart.itemCount,
          cartIconKey: _cartIconKey,
          onTap: (i) {
            if (i == 0) {
              setState(() => _currentNavIndex = i);
            } else if (i == 1) {
              AuthGuard.requireAuthRoute(context, const CartScreen());
            } else if (i == 2) {
              AuthGuard.requireAuthRoute(context, const CustomerOrdersScreen());
            } else if (i == 3) {
              AuthGuard.requireAuthRoute(context, const CustomerProfileScreen());
            }
          },
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
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Discover local products',
                        style: AppTextStyles.screenTitle,
                      ),
                    ],
                  ),
                  _buildIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => AuthGuard.requireAuthRoute(context, const NotificationScreen()),
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
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
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

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Categories
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _fetchProducts();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.coral : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? AppColors.coral : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTextStyles.label.copyWith(
                            color: isSelected ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Filter bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                Text('Filter by location', style: AppTextStyles.sectionHeading),
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
            Text('Sort by', style: AppTextStyles.sectionHeading),
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
                (context, index) => const ProductCardSkeleton(),
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
              (context, index) {
                final reduceMotion = MediaQuery.of(context).disableAnimations;
                final card = ProductCard(
                  product: provider.products[index],
                  onAddToCart: () {
                    AuthGuard.requireAuth(context, onAuthenticated: () {
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
                      CartFlyAnimation.show(
                        sourceContext: context,
                        cartIconKey: _cartIconKey,
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
                    });
                  },
                );

                if (reduceMotion) return card;

                // Staggered entrance: each card fades in with 50ms offset
                return TweenAnimationWidget(
                  delay: index * 0.05,
                  duration: const Duration(milliseconds: 300),
                  builder: (context, anim) {
                    return Opacity(
                      opacity: anim,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - anim)),
                        child: card,
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
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('You have reached the end', style: AppTextStyles.caption),
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox(height: 32));
      },
    );
  }
}


