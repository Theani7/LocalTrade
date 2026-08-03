import 'dart:ui';
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
import '../../widgets/app_scaffold.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/connection_status_banner.dart';
import '../../core/utils/app_animations.dart';
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
    return AppScaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: SizedBox(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(index: 0, icon: Icons.dashboard_outlined, label: 'Dashboard'),
                    _buildNavItem(index: 1, icon: Icons.receipt_long_outlined, label: 'Orders'),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadePageRoute(builder: (_) => const AddEditProductScreen()),
                        );
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coral.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, size: 28, color: AppColors.ink),
                      ),
                    ),
                    _buildNavItem(index: 2, icon: Icons.inventory_2_outlined, label: 'Inventory'),
                    _buildNavItem(index: 3, icon: Icons.person_outline_rounded, label: 'Profile'),
                  ],
                ),
              ),
            ),
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
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 56,
            height: 34,
            decoration: BoxDecoration(
              color: isActive ? AppColors.coralLight : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.coralDark : const Color(0xFFB9AF9A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w500,
              color: isActive ? AppColors.coralDark : AppColors.muted,
            ),
          ),
        ],
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
                                  SlideFadePageRoute(builder: (_) => const NotificationScreen()),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FadeScaleIn(child: _VendorStatCard(
                              icon: Icons.schedule_outlined,
                              value: pending,
                              label: 'Pending',
                              bgColor: AppColors.warningLight,
                              iconColor: AppColors.warningDark,
                            )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FadeScaleIn(child: _VendorStatCard(
                              icon: Icons.check_circle_outline_rounded,
                              value: confirmed,
                              label: 'Confirmed',
                              bgColor: AppColors.blueLight,
                              iconColor: AppColors.blueDark,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FadeScaleIn(child: _VendorStatCard(
                              icon: Icons.local_shipping_outlined,
                              value: delivered,
                              label: 'Delivered',
                              bgColor: AppColors.successLight,
                              iconColor: AppColors.successDark,
                            )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FadeScaleIn(child: _VendorStatCard(
                              icon: Icons.inventory_2_outlined,
                              value: products,
                              label: 'Products',
                              bgColor: AppColors.coralLight,
                              iconColor: AppColors.coralDark,
                            )),
                          ),
                        ],
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
