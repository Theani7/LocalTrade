import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/status_badge.dart';
import 'admin_feedback_results_screen.dart';
import '../customer/notification_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() => _refreshData());
  }

  Future<void> _refreshData() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final notification = Provider.of<NotificationProvider>(context, listen: false);
    await Future.wait([
      admin.fetchAnalytics(),
      admin.fetchUsers(),
      admin.fetchVendors(),
      admin.fetchProducts(),
      admin.fetchOrders(),
      notification.fetchNotifications(),
    ]);
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
        title: const Text('Admin dashboard'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                icon: const Icon(Icons.notifications_outlined, size: 22),
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) => provider.unreadCount > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${provider.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackResultsScreen())),
            icon: const Icon(Icons.rate_review_outlined, size: 22),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded, size: 22),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.coral,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.coral,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Users'),
            Tab(text: 'Vendors'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminAnalyticsTab(),
          AdminUsersTab(),
          AdminVendorsTab(),
          AdminProductsTab(),
          AdminOrdersTab(),
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
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ─── Analytics Tab ──────────────────────────────────────────────────────────
class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.analytics == null) {
          return const SingleChildScrollView(padding: EdgeInsets.all(16), child: _AdminAnalyticsSkeleton());
        }

        if (admin.analytics == null) {
          return EmptyState(
            icon: Icons.analytics_outlined,
            title: 'No analytics yet',
            message: 'Connect to the server to view live system analytics.',
            onAction: admin.fetchAnalytics,
            actionLabel: 'Retry',
          );
        }

        final stats = admin.analytics!['stats'];
        final dailyStats = admin.analytics!['dailyStats'] as List? ?? [];
        final revenueByCategory = admin.analytics!['revenueByCategory'] as List? ?? [];
        final recent = admin.analytics!['recentOrders'] as List? ?? [];

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

        return RefreshIndicator(
          onRefresh: admin.fetchAnalytics,
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
                    boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stat cards
                const Text('Platform statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(icon: Icons.people_rounded, value: '${stats['totalUsers'] ?? 0}', label: 'Users', tintColor: AppColors.blueLight, iconColor: AppColors.blueDark),
                    StatCard(icon: Icons.storefront_rounded, value: '${stats['totalVendors'] ?? 0}', label: 'Vendors', tintColor: AppColors.coralLight, iconColor: AppColors.coralDark),
                    StatCard(icon: Icons.inventory_2_rounded, value: '${stats['totalProducts'] ?? 0}', label: 'Products', tintColor: AppColors.successLight, iconColor: AppColors.successDark),
                    StatCard(icon: Icons.receipt_long_rounded, value: '${stats['totalOrders'] ?? 0}', label: 'Orders', tintColor: AppColors.warningLight, iconColor: AppColors.warningDark),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue by category chart
                if (revenueByCategory.isNotEmpty) ...[
                  const Text('Revenue by category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: PieChart(
                      PieChartData(
                        sections: revenueByCategory.map((cat) {
                          final colors = [AppColors.coral, AppColors.blue, AppColors.success, AppColors.warning, AppColors.muted];
                          final index = revenueByCategory.indexOf(cat);
                          return PieChartSectionData(
                            value: (cat['total'] ?? 0).toDouble(),
                            title: cat['_id'] ?? '',
                            color: colors[index % colors.length],
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Recent orders
                const Text('Recent orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                    child: const Center(child: Text('No recent orders', style: TextStyle(fontSize: 14, color: AppColors.muted))),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: recent.take(5).map((order) {
                        bool isLast = recent.take(5).last == order;
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
      case 'Pending': return BadgeStatus.pending;
      case 'Confirmed': return BadgeStatus.confirmed;
      case 'Delivered': return BadgeStatus.delivered;
      case 'Cancelled': return BadgeStatus.rejected;
      default: return BadgeStatus.pending;
    }
  }
}

// ─── Users Tab ──────────────────────────────────────────────────────────────
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.users.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.users.isEmpty) return const EmptyState(icon: Icons.people_outline_rounded, title: 'No users', message: 'No users registered yet.');

        return RefreshIndicator(
          onRefresh: provider.fetchUsers,
          color: AppColors.coral,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, size: 20, color: AppColors.coralDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['fullName'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user['email'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user['role'] == 'admin' ? AppColors.blueLight : AppColors.background,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        user['role'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: user['role'] == 'admin' ? AppColors.blueDark : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Vendors Tab ────────────────────────────────────────────────────────────
class AdminVendorsTab extends StatelessWidget {
  const AdminVendorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.vendors.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.vendors.isEmpty) return const EmptyState(icon: Icons.storefront_outlined, title: 'No vendors', message: 'No vendors registered yet.');

        return RefreshIndicator(
          onRefresh: provider.fetchVendors,
          color: AppColors.coral,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.vendors.length,
            itemBuilder: (context, index) {
              final vendor = provider.vendors[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                      child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.coralDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor['shopName'] ?? vendor['fullName'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vendor['vendorApprovalStatus'] ?? 'pending',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    _buildApprovalActions(context, vendor, provider),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildApprovalActions(BuildContext context, dynamic vendor, AdminProvider provider) {
    final status = vendor['vendorApprovalStatus'];

    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => provider.updateVendorStatus(vendor['_id'], 'approved'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(100)),
              child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.updateVendorStatus(vendor['_id'], 'rejected'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status == 'approved' ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: status == 'approved' ? AppColors.successDark : AppColors.dangerDark,
        ),
      ),
    );
  }
}

// ─── Products Tab ───────────────────────────────────────────────────────────
class AdminProductsTab extends StatelessWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.products.isEmpty) return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'No products listed yet.');

        return RefreshIndicator(
          onRefresh: provider.fetchProducts,
          color: AppColors.coral,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: AppColors.background,
                        child: product['images'] != null && product['images'].isNotEmpty
                            ? Image.network(product['images'][0], fit: BoxFit.cover)
                            : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['title'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${product['price']}  •  ${product['category'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Stock: ${product['stockQuantity'] ?? 0}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Orders Tab ─────────────────────────────────────────────────────────────
class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.orders.isEmpty) return const OrderCardSkeleton();
        if (provider.orders.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders', message: 'No orders placed yet.');

        return RefreshIndicator(
          onRefresh: provider.fetchOrders,
          color: AppColors.coral,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${order['_id'].toString().substring(18).toUpperCase()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                        ),
                        StatusBadge(status: _mapStatus(order['orderStatus'])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['customerId']['fullName'] ?? 'Customer',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 16, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['vendorId']['shopName'] ?? 'Vendor',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order['products']?.length ?? 0} items',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        Text(
                          'Rs. ${order['totalAmount']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.coral),
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
    );
  }

  BadgeStatus _mapStatus(String? status) {
    switch (status) {
      case 'Pending': return BadgeStatus.pending;
      case 'Confirmed': return BadgeStatus.confirmed;
      case 'Delivered': return BadgeStatus.delivered;
      case 'Cancelled': return BadgeStatus.rejected;
      default: return BadgeStatus.pending;
    }
  }
}

// ─── Skeleton ───────────────────────────────────────────────────────────────
class _AdminAnalyticsSkeleton extends StatelessWidget {
  const _AdminAnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
