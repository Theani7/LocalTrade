import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/status_badge.dart';
import 'vendor_orders_screen.dart';
import 'vendor_inventory_screen.dart';
import 'vendor_profile_screen.dart';
import 'add_edit_product_screen.dart';
import '../customer/notification_screen.dart';
import '../common/feedback_submission_screen.dart';
import '../auth/login_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      Provider.of<VendorProvider>(context, listen: false).fetchAnalytics();
      Provider.of<VendorProvider>(context, listen: false).fetchProfile();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendor dashboard'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            icon: const Icon(Icons.notifications_outlined, size: 22),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackSubmissionScreen())),
            icon: const Icon(Icons.rate_review_outlined, size: 22),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded, size: 22),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.coral,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.coral,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Inventory'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VendorOverviewTab(),
          VendorOrdersScreen(),
          VendorInventoryScreen(),
          VendorProfileScreen(),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(100, 40)),
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

class VendorOverviewTab extends StatelessWidget {
  const VendorOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const _OverviewSkeleton();

        if (provider.error != null) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load data',
            message: provider.error!,
            onAction: () => provider.fetchAnalytics(),
            actionLabel: 'Retry',
          );
        }

        if (provider.analytics == null) return const Center(child: Text('No data available', style: TextStyle(color: AppColors.muted)));

        final stats = provider.analytics?['stats'] ?? {};
        final recentOrders = provider.analytics?['recentOrders'] as List? ?? [];

        double totalRevenue = 0.0;
        if (stats['totalRevenue'] != null) {
          if (stats['totalRevenue'] is int) {
            totalRevenue = (stats['totalRevenue'] as int).toDouble();
          } else if (stats['totalRevenue'] is double) {
            totalRevenue = stats['totalRevenue'] as double;
          } else {
            totalRevenue = double.tryParse(stats['totalRevenue'].toString()) ?? 0.0;
          }
        }

        String pending = (stats['pendingOrders'] ?? 0).toString();
        String confirmed = (stats['confirmedOrders'] ?? 0).toString();
        String delivered = (stats['deliveredOrders'] ?? 0).toString();
        String products = (stats['totalProducts'] ?? 0).toString();

        return RefreshIndicator(
          onRefresh: provider.fetchAnalytics,
          color: AppColors.coral,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(100)),
                            child: const Text('All time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.successDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stat cards
                const Text('Order statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(icon: Icons.access_time_rounded, value: pending, label: 'Pending', tintColor: AppColors.warningLight, iconColor: AppColors.warningDark),
                    StatCard(icon: Icons.check_circle_outline_rounded, value: confirmed, label: 'Confirmed', tintColor: AppColors.blueLight, iconColor: AppColors.blueDark),
                    StatCard(icon: Icons.local_shipping_outlined, value: delivered, label: 'Delivered', tintColor: AppColors.successLight, iconColor: AppColors.successDark),
                    StatCard(icon: Icons.inventory_2_outlined, value: products, label: 'Products', tintColor: AppColors.coralLight, iconColor: AppColors.coralDark),
                  ],
                ),
                const SizedBox(height: 20),

                // Recent activity
                const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 10),
                if (recentOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Center(child: Text('No recent orders', style: TextStyle(fontSize: 14, color: AppColors.muted))),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: recentOrders.map((order) {
                        bool isLast = recentOrders.last == order;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.coralDark),
                              ),
                              title: Text(
                                'Order #${order['_id'].toString().substring(18).toUpperCase()}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                order['customerId']['fullName'] ?? 'Customer',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${order['totalAmount']}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  StatusBadge(status: _mapStatus(order['orderStatus'])),
                                ],
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, indent: 64, endIndent: 14),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  BadgeStatus _mapStatus(String? status) {
    switch (status) {
      case 'Pending':
        return BadgeStatus.pending;
      case 'Confirmed':
        return BadgeStatus.confirmed;
      case 'Delivered':
        return BadgeStatus.delivered;
      case 'Cancelled':
        return BadgeStatus.rejected;
      default:
        return BadgeStatus.pending;
    }
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShimmerSkeleton(height: 100, radius: 16),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => const StatCardSkeleton()),
          ),
        ],
      ),
    );
  }
}

class VendorProductsTab extends StatefulWidget {
  const VendorProductsTab({super.key});

  @override
  State<VendorProductsTab> createState() => _VendorProductsTabState();
}

class _VendorProductsTabState extends State<VendorProductsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).fetchMyProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading && productProvider.myProducts.isEmpty) {
            return const ListSkeleton(itemCount: 4);
          }

          if (productProvider.myProducts.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Add your first product to start selling.',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
              actionLabel: 'Add product',
            );
          }

          return RefreshIndicator(
            onRefresh: productProvider.fetchMyProducts,
            color: AppColors.coral,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productProvider.myProducts.length,
              itemBuilder: (context, index) {
                final product = productProvider.myProducts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: AppColors.background,
                          child: product['images'] != null && product['images'].isNotEmpty
                              ? Image.network(product['images'][0], fit: BoxFit.cover)
                              : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${product['price']}  •  Stock: ${product['stock'] ?? 0}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product))),
                            child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.blue),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(context, product),
                            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('Delete product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
        content: Text('Delete "${product['title']}"? This cannot be undone.', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(100, 40)),
            onPressed: () async {
              final success = await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product['_id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Product deleted' : 'Failed to delete'),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
