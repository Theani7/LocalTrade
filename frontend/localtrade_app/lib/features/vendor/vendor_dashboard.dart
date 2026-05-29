import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_helper.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_product_screen.dart';
import 'vendor_orders_screen.dart';
import '../customer/notification_screen.dart';
import '../common/feedback_submission_screen.dart';
import 'vendor_inventory_screen.dart';
import '../auth/login_screen.dart';

import 'vendor_profile_screen.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Seller Hub'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                icon: const Icon(Icons.notifications_none_outlined),
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) => provider.unreadCount > 0 ? Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ) : const SizedBox(),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackSubmissionScreen())),
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'UAT Feedback',
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long_outlined)),
            Tab(text: 'Inventory', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Profile', icon: Icon(Icons.person_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const VendorOverviewTab(),
          const VendorOrdersScreen(),
          const VendorInventoryScreen(),
          const VendorProfileScreen(),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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

class VendorOverviewTab extends StatelessWidget {
  const VendorOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return _buildSkeletonLoader();
        if (provider.error != null) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load data',
            message: provider.error!,
            onAction: () => provider.fetchAnalytics(),
            actionLabel: 'Retry',
          );
        }
        if (provider.analytics == null) return const Center(child: Text('No data available'));

        final stats = provider.analytics?['stats'] ?? {};
        final recentOrders = provider.analytics?['recentOrders'] as List? ?? [];

        // Safe parsing for revenue and stats
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sales Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _buildRevenueCard(totalRevenue),
                const SizedBox(height: 24),
                const Text('Order Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    // Lower aspect ratio to give cards more height on small phones, preventing text overlap
                    double childAspectRatio = constraints.maxWidth > 600 ? 1.6 : 1.15;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildStatCard('Pending', pending, const Color(0xFFF59E0B), Icons.hourglass_empty), // Using AppTheme Warning Color
                        _buildStatCard('Confirmed', confirmed, AppTheme.primaryLight, Icons.thumb_up_alt_outlined),
                        _buildStatCard('Delivered', delivered, AppTheme.successColor, Icons.local_shipping_outlined),
                        _buildStatCard('Total Products', products, AppTheme.primaryColor, Icons.inventory_2_outlined),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderMedium)),
                    child: const Center(child: Text('No recent orders yet', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                    ),
                    child: Column(
                      children: recentOrders.map((order) {
                        bool isLast = recentOrders.last == order;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
                              ),
                              title: Text(
                                'Order #${order['_id'].toString().substring(18).toUpperCase()}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  order['customerId']['fullName'] ?? 'Customer', 
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${order['totalAmount']}', 
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order['orderStatus'] ?? 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _getStatusColor(order['orderStatus']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, indent: 70, endIndent: 16, color: AppTheme.borderSubtle),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Revenue',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppTheme.successColor, size: 14),
                    const SizedBox(width: 4),
                    const Text('ALL TIME', style: TextStyle(color: AppTheme.successColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rs. ${revenue.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: List.generate(4, (index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            ),
          ],
        ),
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
       backgroundColor: AppTheme.backgroundColor,
       body: Consumer<ProductProvider>(
         builder: (context, productProvider, _) {
           if (productProvider.isLoading && productProvider.myProducts.isEmpty) {
             return ListView.builder(
               padding: const EdgeInsets.all(24),
               itemCount: 4,
               itemBuilder: (context, index) => Shimmer.fromColors(
                 baseColor: Colors.grey[300]!,
                 highlightColor: Colors.grey[100]!,
                 child: Container(height: 100, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
               ),
             );
           }
           
           if (productProvider.myProducts.isEmpty) {
             return EmptyState(
               icon: Icons.inventory_2_outlined,
               title: 'No Products Listed',
               message: 'Start selling by adding your first product.',
               onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
               actionLabel: 'Add Product',
             );
           }

           return RefreshIndicator(
             onRefresh: productProvider.fetchMyProducts,
             child: ListView.builder(
               padding: const EdgeInsets.all(24),
               itemCount: productProvider.myProducts.length,
               itemBuilder: (context, index) {
                 final product = productProvider.myProducts[index];
                 return Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   decoration: BoxDecoration(
                     color: AppTheme.surfaceColor,
                     borderRadius: BorderRadius.circular(20),
                     boxShadow: AppTheme.softShadow,
                     border: Border.all(color: Colors.black.withOpacity(0.05)),
                   ),
                   child: Padding(
                     padding: const EdgeInsets.all(12),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(
                           width: 70,
                           height: 70,
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(12),
                             color: Colors.grey[100],
                           ),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(12),
                             child: product['images'] != null && product['images'].isNotEmpty 
                             ? CachedNetworkImage(
                                 imageUrl: CloudinaryHelper.getOptimizedUrl(product['images'][0], width: 200),
                                 fit: BoxFit.cover,
                                 placeholder: (context, url) => Container(color: Colors.grey[200]),
                                 errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                               )
                             : const Icon(Icons.image, size: 30, color: Colors.grey),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 product['title'], 
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               const SizedBox(height: 4),
                               Text('Price: Rs. ${product['price']}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                               const SizedBox(height: 2),
                               Row(
                                 children: [
                                   Icon(
                                     Icons.inventory_2_outlined, 
                                     size: 12, 
                                     color: (product['stock'] ?? 0) < 5 ? AppTheme.errorColor : AppTheme.textSecondary
                                   ),
                                   const SizedBox(width: 4),
                                   Text(
                                     'Stock: ${product['stock'] ?? 0}', 
                                     style: TextStyle(
                                       fontSize: 12, 
                                       color: (product['stock'] ?? 0) < 5 ? AppTheme.errorColor : AppTheme.textSecondary,
                                       fontWeight: (product['stock'] ?? 0) < 5 ? FontWeight.bold : FontWeight.normal
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             IconButton(
                               icon: const Icon(Icons.edit_outlined, size: 20),
                               color: AppTheme.secondaryColor,
                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product))),
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(),
                             ),
                             const SizedBox(height: 8),
                             IconButton(
                               icon: const Icon(Icons.delete_outline, size: 20),
                               color: AppTheme.errorColor,
                               onPressed: () => _showDeleteDialog(context, product),
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 );
               },
             ),
           );
         },
       ),
       floatingActionButton: FloatingActionButton.extended(
         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
         backgroundColor: AppTheme.primaryColor,
         foregroundColor: Colors.white,
         elevation: 4,
         icon: const Icon(Icons.add),
         label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
       ),
     );
  }

  void _showDeleteDialog(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Product?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${product['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              final success = await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product['_id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Product removed successfully' : 'Failed to remove product'),
                    backgroundColor: success ? AppTheme.textPrimary : AppTheme.errorColor,
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

