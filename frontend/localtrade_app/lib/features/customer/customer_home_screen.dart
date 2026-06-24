import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cart_fly_animation.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loaders.dart';
import 'notification_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CustomerHomeScreen — full-screen push route (splash entry, etc.)
// ═════════════════════════════════════════════════════════════════════════════
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      body: CustomerHomeBody(
        onNotificationTap: () => AuthGuard.requireAuthRoute(
          context,
          const NotificationScreen(),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CustomerHomeBody — reusable content widget (used by CustomerShell)
// ═════════════════════════════════════════════════════════════════════════════
class CustomerHomeBody extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final GlobalKey? cartIconKey;

  const CustomerHomeBody({
    super.key,
    this.onNotificationTap,
    this.cartIconKey,
  });

  @override
  State<CustomerHomeBody> createState() => CustomerHomeBodyState();
}

class CustomerHomeBodyState extends State<CustomerHomeBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  String? _selectedLocation;
  String? _selectedSort;
  bool _showAll = false;

  List<String> _categories = ['All'];

  final Map<String, String> _sortOptions = {
    'newest': 'Newest first',
    'price_low': 'Price: low to high',
    'price_high': 'Price: high to low',
    'availability': 'Availability',
  };

  /// Public method to set category from outside (e.g. cart empty state chips)
  void setCategory(String category) {
    if (_selectedCategory != category) {
      setState(() => _selectedCategory = category);
      _fetchProducts();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      catProvider.fetchActiveCategories().then((_) {
        if (mounted) {
          setState(() {
            _categories = ['All', ...catProvider.categoryNames];
          });
        }
      });
      _fetchProducts();
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(refresh: false);
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
    try {
      final authProvider = Provider.of<AuthProvider>(context);
      final userName = authProvider.user?['fullName']?.split(' ')[0] ?? 'Guest';

      return Column(
        children: [
          // ── Header ──
          _buildHeader(userName),
          const SizedBox(height: 14),

        // ── Search ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _fetchProducts(),
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Search products, categories...',
              hintStyle: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.muted, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 20, color: AppColors.muted),
                      onPressed: () {
                        _searchController.clear();
                        _fetchProducts();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide:
                    const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide:
                    const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(
                    color: AppColors.coral, width: 1.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Category chips ──
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _fetchProducts();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.coral
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.coral
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.ink
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

        const SizedBox(height: 12),

        // ── Filter bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_selectedLocation != null ||
                    _selectedSort != null ||
                    _showAll ||
                    _searchController.text.isNotEmpty ||
                    _selectedCategory != 'All')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _clearAllFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.coralLight,
                          borderRadius:
                              BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 14,
                                color: AppColors.coralDark),
                            SizedBox(width: 4),
                            Text('Clear',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        AppColors.coralDark)),
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
                  label: _selectedSort != null
                      ? _sortOptions[_selectedSort!]!
                      : 'Sort',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showAll
                          ? AppColors.coralLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: _showAll
                              ? AppColors.coralLight
                              : AppColors.divider),
                    ),
                    child: Text(
                      'Include unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _showAll
                            ? AppColors.coralDark
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Products grid (scrollable) ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _fetchProducts(),
            color: AppColors.coral,
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) => _buildProductList(provider),
            ),
          ),
        ),
      ],
    );
    } catch (e, stack) {
      debugPrint('CustomerHomeBody build error: $e\n$stack');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Build error: $e', style: const TextStyle(color: Colors.red, fontSize: 14)),
        ),
      );
    }
  }

  Widget _buildHeader(String userName) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $userName', style: AppTextStyles.bodyMuted),
                const SizedBox(height: 2),
                Text('Discover local products', style: AppTextStyles.screenTitle),
              ],
            ),
            Consumer<NotificationProvider>(
              builder: (context, notifProv, _) => GestureDetector(
                onTap: widget.onNotificationTap,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x0D2B2620), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 20, color: AppColors.ink),
                      if (notifProv.unreadCount > 0)
                        Positioned(
                          right: -2, top: -2,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                notifProv.unreadCount > 9 ? '9+' : '${notifProv.unreadCount}',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(ProductProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ProductCardSkeleton(),
        ),
      );
    }

    if (provider.error != null && provider.products.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
            ),
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: provider.error!,
              onAction: () => _fetchProducts(),
              actionLabel: 'Try again',
            ),
          ],
        ),
      );
    }

    if (provider.products.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
            ),
            EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              message: 'Try searching for something else or browse another category.',
              onAction: _clearAllFilters,
              actionLabel: 'View all products',
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
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
                final card = ProductCard(
                  product: provider.products[index],
                  onAddToCart: () {
                    AuthGuard.requireAuth(context,
                        onAuthenticated: () {
                      final p = provider.products[index];
                      final image = (p['images'] != null &&
                              p['images'].isNotEmpty)
                          ? p['images'][0]
                          : '';
                      final vendorId =
                          p['vendorId'] is Map
                              ? (p['vendorId']['_id'] ?? '')
                              : (p['vendorId'] ?? '');
                      Provider.of<CartProvider>(context,
                              listen: false)
                          .addItem(
                        p['_id'],
                        p['title'],
                        double.parse(p['price'].toString()),
                        image,
                        vendorId,
                        priceUnit: p['priceUnit'] ?? 'piece',
                      );
                      if (widget.cartIconKey != null) {
                        CartFlyAnimation.show(
                          sourceContext: context,
                          cartIconKey: widget.cartIconKey!,
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.ink,
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 18),
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
                );

                return StaggeredListItem(
                  index: index,
                  totalCount: provider.products.length,
                  child: card,
                );
              },
              childCount: provider.products.length,
            ),
          ),
        ),
        if (provider.isFetchingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.coral),
                ),
              ),
            ),
          ),
        if (!provider.hasMore && provider.products.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('You have reached the end',
                    style: AppTextStyles.caption),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.coralLight : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color:
                  isSelected ? AppColors.coralLight : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.check_rounded
                  : Icons.tune_rounded,
              size: 14,
              color:
                  isSelected ? AppColors.coralDark : AppColors.muted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isSelected ? AppColors.coralDark : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationFilter() {
    final controller =
        TextEditingController(text: _selectedLocation);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by location',
                    style: AppTextStyles.sectionHeading),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Enter city or area',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.muted)),
              onSubmitted: (val) {
                setState(() => _selectedLocation =
                    val.trim().isEmpty ? null : val.trim());
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedLocation =
                      controller.text.trim().isEmpty
                          ? null
                          : controller.text.trim());
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
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
                      fontWeight: _selectedSort == entry.key
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _selectedSort == entry.key
                          ? AppColors.coral
                          : AppColors.ink,
                    ),
                  ),
                  trailing: _selectedSort == entry.key
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.coral)
                      : null,
                  onTap: () {
                    setState(
                        () => _selectedSort = entry.key);
                    _fetchProducts();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

}
