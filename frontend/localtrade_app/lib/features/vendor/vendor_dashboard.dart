import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vendor_order_status_badge.dart';
import '../../widgets/skeleton_loaders.dart';
import 'vendor_orders_screen.dart';
import 'vendor_inventory_screen.dart';
import 'vendor_profile_screen.dart';
import 'add_edit_product_screen.dart';
import '../customer/notification_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VendorOverviewTab(),
    VendorOrdersScreen(),
    VendorInventoryScreen(),
    VendorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).fetchAnalytics();
      Provider.of<VendorProvider>(context, listen: false).fetchProfile();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
        },
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.ink,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
          child: Row(
            children: [
              _buildNavItem(index: 0, icon: Icons.dashboard_outlined, label: 'Dashboard'),
              _buildNavItem(index: 1, icon: Icons.receipt_long_outlined, label: 'Orders'),
              const SizedBox(width: 56), // space for FAB
              _buildNavItem(index: 2, icon: Icons.inventory_2_outlined, label: 'Inventory'),
              _buildNavItem(index: 3, icon: Icons.person_outline_rounded, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.coralDark : const Color(0xFFB9AF9A),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? AppColors.coralDark : AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.coralDark : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Overview Tab
// ═════════════════════════════════════════════════════════════════════════════
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

        if (provider.analytics == null) {
          return Center(
            child: Text('No data available', style: AppTextStyles.bodyMuted),
          );
        }

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

        final pending = (stats['pendingOrders'] ?? 0).toString();
        final confirmed = (stats['confirmedOrders'] ?? 0).toString();
        final delivered = (stats['deliveredOrders'] ?? 0).toString();
        final products = (stats['totalProducts'] ?? 0).toString();

        final user = Provider.of<AuthProvider>(context).user;
        final storeName = user?['shopName'] ?? user?['fullName'] ?? 'Vendor';

        return RefreshIndicator(
          onRefresh: provider.fetchAnalytics,
          color: AppColors.coral,
          child: CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: AppTextStyles.bodyMuted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              storeName,
                              style: AppTextStyles.screenTitle.copyWith(fontSize: 19),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Consumer<NotificationProvider>(
                            builder: (context, notifProv, _) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.ink.withValues(alpha: 0.06),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.ink),
                                    ),
                                    if (notifProv.unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.coral,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            notifProv.unreadCount > 9 ? '9+' : '${notifProv.unreadCount}',
                                            style: AppTextStyles.badge.copyWith(
                                              color: Colors.white,
                                              fontSize: 9,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Revenue card ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildRevenueCard(totalRevenue, recentOrders.length),
                ),
              ),

              // ── Stat cards ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text('Order statistics', style: AppTextStyles.sectionHeading),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _VendorStatCard(
                        icon: Icons.schedule_outlined,
                        value: pending,
                        label: 'Pending',
                        bgColor: AppColors.warningLight,
                        iconColor: AppColors.warningDark,
                      ),
                      _VendorStatCard(
                        icon: Icons.check_circle_outline_rounded,
                        value: confirmed,
                        label: 'Confirmed',
                        bgColor: AppColors.blueLight,
                        iconColor: AppColors.blueDark,
                      ),
                      _VendorStatCard(
                        icon: Icons.local_shipping_outlined,
                        value: delivered,
                        label: 'Delivered',
                        bgColor: AppColors.successLight,
                        iconColor: AppColors.successDark,
                      ),
                      _VendorStatCard(
                        icon: Icons.inventory_2_outlined,
                        value: products,
                        label: 'Products',
                        bgColor: AppColors.coralLight,
                        iconColor: AppColors.coralDark,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent activity ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text('Recent activity', style: AppTextStyles.sectionHeading),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: recentOrders.isEmpty
                      ? _buildEmptyActivity()
                      : _buildActivityList(recentOrders),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  // ── Revenue Card ────────────────────────────────────────────────────────────
  Widget _buildRevenueCard(double totalRevenue, int orderCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total revenue', style: AppTextStyles.label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'All time',
                  style: AppTextStyles.badge.copyWith(color: AppColors.coralDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rs. ${totalRevenue.toStringAsFixed(0)}',
            style: AppTextStyles.price.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 14),
          // Mini bar chart
          _MiniBarChart(
            orderCount: orderCount,
            revenue: totalRevenue,
          ),
          const SizedBox(height: 10),
          Text(
            totalRevenue > 0
                ? '$orderCount completed orders'
                : 'No completed orders yet',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Activity List ───────────────────────────────────────────────────────────
  Widget _buildActivityList(List orders) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(orders.length, (index) {
          final order = orders[index];
          final isLast = index == orders.length - 1;
          return _buildActivityRow(order, isLast);
        }),
      ),
    );
  }

  Widget _buildActivityRow(dynamic order, bool isLast) {
    final orderId = order['_id']?.toString() ?? '';
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();
    final customerName = order['customerId']?['fullName'] ?? 'Customer';
    final amount = order['totalAmount'] ?? 0;
    final status = order['orderStatus'] ?? 'Pending';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.coralDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$shortId',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. $amount',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  VendorOrderStatusBadge(status: status, compact: true),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 62,
            endIndent: 14,
            color: AppColors.divider,
          ),
      ],
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.coralDark),
          ),
          const SizedBox(height: 12),
          Text('No recent orders', style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'Orders from customers will appear here',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Vendor Stat Card — no fixed height, design system colors
// ═════════════════════════════════════════════════════════════════════════════
class _VendorStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color bgColor;
  final Color iconColor;

  const _VendorStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.price.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Mini Bar Chart — electric blue bars for revenue card
// ═════════════════════════════════════════════════════════════════════════════
class _MiniBarChart extends StatelessWidget {
  final int orderCount;
  final double revenue;

  const _MiniBarChart({required this.orderCount, required this.revenue});

  @override
  Widget build(BuildContext context) {
    final barCount = 7;
    final bars = List.generate(barCount, (i) {
      if (revenue <= 0) return 0.0;
      // Fake distribution — more weight toward the right (recent)
      final base = (i + 1) / barCount;
      return (0.2 + base * 0.8).clamp(0.0, 1.0);
    });

    return SizedBox(
      height: 40,
      child: orderCount <= 0 || revenue <= 0
          ? Center(
              child: Text(
                'No data',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted.withValues(alpha: 0.6),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(barCount, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: 40 * bars[i],
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton Loader
// ═════════════════════════════════════════════════════════════════════════════
class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerSkeleton(height: 14, width: 100),
                    const SizedBox(height: 6),
                    const ShimmerSkeleton(height: 18, width: 160),
                  ],
                ),
              ),
              const ShimmerSkeleton(height: 36, width: 36, radius: 18),
              const SizedBox(width: 8),
              const ShimmerSkeleton(height: 36, width: 36, radius: 18),
            ],
          ),
          const SizedBox(height: 20),
          // Revenue skeleton
          const ShimmerSkeleton(height: 140, radius: 16),
          const SizedBox(height: 20),
          // Stat cards skeleton
          const ShimmerSkeleton(height: 16, width: 130),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: List.generate(4, (_) => const ShimmerSkeleton(height: 90, radius: 16)),
          ),
        ],
      ),
    );
  }
}
