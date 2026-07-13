import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';

import '../../widgets/skeleton_loaders.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/status_badge.dart';
import '../customer/notification_screen.dart';
import 'admin_product_detail_screen.dart';
import 'admin_vendor_detail_screen.dart';
import 'admin_categories_screen.dart';

class AdminStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tintColor;
  final Color iconColor;

  const AdminStatTile(
    this.icon,
    this.value,
    this.label,
    this.tintColor,
    this.iconColor, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tintColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 1),
                Text(label, style: TextStyle(fontSize: 10, color: AppColors.muted.withValues(alpha: 0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final void Function(int tabIndex)? onTabChanged;

  const AdminDashboard({super.key, this.onTabChanged});

  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
      }
    });
    Future.microtask(() => _refreshData());
  }

  void switchTab(int index) {
    _tabController.animateTo(index);
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
    return AppScaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AdminAnalyticsTab(),
                  AdminUsersTab(),
                  AdminVendorsTab(),
                  AdminProductsTab(),
                  AdminOrdersTab(),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin dashboard', style: AppTextStyles.screenTitle),
                const SizedBox(height: 2),
                Consumer<NotificationProvider>(
                  builder: (_, provider, __) {
                    final unread = provider.unreadCount;
                    if (unread > 0) {
                      return Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$unread unread',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.warningDark),
                          ),
                        ],
                      );
                    }
                    return Text('System overview', style: AppTextStyles.caption);
                  },
                ),
              ],
            ),
          ),
          // Categories button
          GestureDetector(
            onTap: () => Navigator.push(context, SlideFadePageRoute(builder: (_) => const AdminCategoriesScreen())),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.category_outlined, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          // Notification bell
          GestureDetector(
            onTap: () => Navigator.push(context, SlideFadePageRoute(builder: (_) => const NotificationScreen())),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Analytics Tab
// ═════════════════════════════════════════════════════════════════════════════
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
        final revenueByCategory = admin.analytics!['revenueByCategory'] as List? ?? [];
        final recent = admin.analytics!['recentOrders'] as List? ?? [];
        final dailyStats = admin.analytics!['dailyStats'] as List? ?? [];
        final userDailyStats = admin.analytics!['userDailyStats'] as List? ?? [];
        final productDailyStats = admin.analytics!['productDailyStats'] as List? ?? [];

        Map<String, dynamic> _getTrendData(List<dynamic> data, String valueKey) {
          if (data.isEmpty) return {'trend': 'No recent data', 'chart': <double>[]};
          final chartData = data.map((e) => (e[valueKey] ?? 0).toDouble()).toList().cast<double>();
          if (chartData.length < 2) return {'trend': '↑ +100%', 'chart': chartData};
          
          final current = chartData.last;
          final previous = chartData[chartData.length - 2];
          if (previous == 0) return {'trend': '↑ +100%', 'chart': chartData};
          
          final diff = current - previous;
          final pct = (diff / previous) * 100;
          return {
            'trend': '${pct >= 0 ? '↑ +' : '↓ '}${pct.toStringAsFixed(1)}% from yesterday',
            'chart': chartData
          };
        }

        final revInfo = _getTrendData(dailyStats, 'revenue');
        final ordersInfo = _getTrendData(dailyStats, 'count');
        final usersInfo = _getTrendData(userDailyStats, 'count');
        final productsInfo = _getTrendData(productDailyStats, 'count');

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
                // Pending approval banner
                Consumer<AdminProvider>(
                  builder: (_, adminProv, __) {
                    final pendingCount = adminProv.vendors
                        .where((v) => v['vendorApprovalStatus'] == 'pending')
                        .length;
                    if (pendingCount == 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warningDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$pendingCount vendor${pendingCount == 1 ? '' : 's'} pending approval',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warningDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Review applications to onboard new vendors',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.warningDark.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final dashboardState = context.findAncestorStateOfType<AdminDashboardState>();
                              dashboardState?.switchTab(2);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.ink),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Revenue card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
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
                            child: const Text('All time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.coralDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.ink),
                      ),
                      const SizedBox(height: 12),
                      // Mini bar chart
                      _MiniBarChart(dailyStats: dailyStats),
                      const SizedBox(height: 8),
                      Text(
                        'Revenue across all vendor categories',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stat cards
                Text('Platform statistics', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    FadeScaleIn(
                      child: _AdvancedStatCard(
                        title: 'Total Revenue',
                        value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        growthText: revInfo['trend'] as String,
                        contentColor: AppColors.blue,
                        chartData: revInfo['chart'] as List<double>,
                        isBarChart: false,
                      ),
                    ),
                    FadeScaleIn(
                      child: _AdvancedStatCard(
                        title: 'Active Users',
                        value: '${stats['totalUsers'] ?? 0}',
                        growthText: usersInfo['trend'] as String,
                        contentColor: AppColors.success,
                        chartData: usersInfo['chart'] as List<double>,
                        isBarChart: false,
                      ),
                    ),
                    FadeScaleIn(
                      child: _AdvancedStatCard(
                        title: 'Orders',
                        value: '${stats['totalOrders'] ?? 0}',
                        growthText: ordersInfo['trend'] as String,
                        contentColor: AppColors.warning,
                        chartData: ordersInfo['chart'] as List<double>,
                        isBarChart: true,
                      ),
                    ),
                    FadeScaleIn(
                      child: _AdvancedStatCard(
                        title: 'Total Products',
                        value: '${stats['totalProducts'] ?? 0}',
                        growthText: productsInfo['trend'] as String,
                        contentColor: AppColors.coral,
                        chartData: productsInfo['chart'] as List<double>,
                        isBarChart: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // NEW: Revenue Line Chart
                if (dailyStats.isNotEmpty) ...[
                  Text('Revenue Over Time (Last 7 Days)', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 10),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.only(right: 16, left: 4, top: 24, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: _RevenueLineChart(dailyStats: dailyStats),
                  ),
                  const SizedBox(height: 20),
                ],

                // Revenue by category chart
                if (revenueByCategory.isNotEmpty) ...[
                  Text('Revenue by category', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: _buildPieChart(revenueByCategory),
                  ),
                  const SizedBox(height: 20),
                ],

                // Daily Orders Bar Chart
                if (dailyStats.isNotEmpty) ...[
                  Text('Daily Orders (Last 7 Days)', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 10),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.only(right: 16, left: 4, top: 24, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: _DailyOrdersBarChart(dailyStats: dailyStats),
                  ),
                  const SizedBox(height: 20),
                ],

                // User Roles Pie Chart
                Text('User Demographics', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 10),
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
                  ),
                  child: _UserRolesPieChart(stats: stats),
                ),
                const SizedBox(height: 20),

                // Order Fulfillment Pie Chart
                Text('Order Fulfillment', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 10),
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
                  ),
                  child: _OrderFulfillmentPieChart(stats: stats),
                ),
                const SizedBox(height: 20),

                // Recent orders
                Text('Recent orders', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Center(child: Text('No recent orders', style: AppTextStyles.bodyMuted)),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
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
                                'Order #${(() { final id = order['_id'].toString(); return id.length > 6 ? id.substring(id.length - 6) : id; })().toUpperCase()}',
                                style: AppTextStyles.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                order['customerId']?['fullName'] ?? 'Customer',
                                style: AppTextStyles.caption,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${order['totalAmount']}',
                                    style: AppTextStyles.label,
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

                // Export section
                Text('Export data', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildExportChip(context, 'Overview', 'overview'),
                    _buildExportChip(context, 'Orders', 'orders'),
                    _buildExportChip(context, 'Products', 'products'),
                    _buildExportChip(context, 'Vendors', 'vendors'),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildExportChip(BuildContext context, String label, String type) {
    return GestureDetector(
      onTap: () async {
        final provider = Provider.of<AdminProvider>(context, listen: false);
        final csv = await provider.exportAnalytics(type: type);
        if (csv == null) return;
        try {
          final bytes = utf8.encode(csv);
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$type-${DateTime.now().toIso8601String()}.csv');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100));
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save/share: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  static Widget _buildPieChart(List<dynamic> revenueByCategory) {
    final colors = [AppColors.coral, AppColors.blue, AppColors.success, AppColors.warning, AppColors.muted];
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: revenueByCategory.map((cat) {
                final index = revenueByCategory.indexOf(cat);
                final value = (cat['total'] ?? 0).toDouble();
                return PieChartSectionData(
                  value: value,
                  title: '', // Hide title for cleaner look
                  color: colors[index % colors.length],
                  radius: 30, // Donut style
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: revenueByCategory.map((cat) {
              final index = revenueByCategory.indexOf(cat);
              final color = colors[index % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat['_id'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static BadgeStatus _mapStatus(String? status) {
    switch (status) {
      case 'Pending': return BadgeStatus.pending;
      case 'Confirmed': return BadgeStatus.confirmed;
      case 'Delivered': return BadgeStatus.delivered;
      case 'Cancelled': return BadgeStatus.rejected;
      default: return BadgeStatus.pending;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Mini Bar Chart (for revenue card)
// ═════════════════════════════════════════════════════════════════════════════
class _MiniBarChart extends StatelessWidget {
  final List<dynamic> dailyStats;

  const _MiniBarChart({this.dailyStats = const []});

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 40.0;

    // Build 7 bars from dailyStats (last 7 days)
    final List<double> barHeights = [];
    if (dailyStats.isNotEmpty) {
      final maxRevenue = dailyStats.fold<double>(0, (max, d) {
        final rev = (d['revenue'] ?? 0).toDouble();
        return rev > max ? rev : max;
      });
      for (final day in dailyStats) {
        final rev = (day['revenue'] ?? 0).toDouble();
        barHeights.add(maxRevenue > 0 ? rev / maxRevenue : 0.3);
      }
    }
    // Pad to 7 bars if fewer
    while (barHeights.length < 7) {
      barHeights.add(0.3);
    }
    final barCount = barHeights.length > 7 ? 7 : barHeights.length;

    return SizedBox(
      height: maxBarHeight + 4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: maxBarHeight * barHeights[index],
                decoration: BoxDecoration(
                  color: index == barCount - 1 ? AppColors.blue : AppColors.blueLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
// Revenue Line Chart
// ═════════════════════════════════════════════════════════════════════════════
class _RevenueLineChart extends StatelessWidget {
  final List<dynamic> dailyStats;

  const _RevenueLineChart({required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) return const Center(child: Text('No data'));

    final spots = <FlSpot>[];
    double maxRevenue = 0;
    
    for (int i = 0; i < dailyStats.length; i++) {
      final stat = dailyStats[i];
      final revenue = (stat['revenue'] ?? 0).toDouble();
      if (revenue > maxRevenue) maxRevenue = revenue;
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue > 0 ? (maxRevenue / 4 == 0 ? 1 : maxRevenue / 4) : 1,
          getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyStats.length) return const SizedBox.shrink();
                final dateStr = dailyStats[index]['_id'] as String? ?? '';
                final parts = dateStr.split('-');
                final label = parts.length == 3 ? '${parts[1]}/${parts[2]}' : dateStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.coral,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.coralLight.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Daily Orders Bar Chart
// ═════════════════════════════════════════════════════════════════════════════
class _DailyOrdersBarChart extends StatelessWidget {
  final List<dynamic> dailyStats;

  const _DailyOrdersBarChart({required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) return const Center(child: Text('No data'));

    final barGroups = <BarChartGroupData>[];
    double maxCount = 0;
    
    for (int i = 0; i < dailyStats.length; i++) {
      final stat = dailyStats[i];
      final count = (stat['count'] ?? 0).toDouble();
      if (count > maxCount) maxCount = count;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: AppColors.blue,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount > 0 ? maxCount + (maxCount * 0.2) : 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxCount > 0 ? (maxCount / 4 == 0 ? 1 : maxCount / 4) : 1,
          getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyStats.length) return const SizedBox.shrink();
                final dateStr = dailyStats[index]['_id'] as String? ?? '';
                final parts = dateStr.split('-');
                final label = parts.length == 3 ? '${parts[1]}/${parts[2]}' : dateStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Generic Doughnut Chart Builder
// ═════════════════════════════════════════════════════════════════════════════
class _DoughnutChartBuilder extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _DoughnutChartBuilder({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: data.map((item) {
                return PieChartSectionData(
                  value: item['value'] as double,
                  title: '',
                  color: item['color'] as Color,
                  radius: 30,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 35,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item['label']} (${(item['value'] as double).toInt()})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// User Roles Pie Chart
// ═════════════════════════════════════════════════════════════════════════════
class _UserRolesPieChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _UserRolesPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final customers = double.tryParse('${stats['totalCustomers']}') ?? 0.0;
    final approvedVendors = double.tryParse('${stats['approvedVendors']}') ?? 0.0;
    final pendingVendors = double.tryParse('${stats['pendingVendors']}') ?? 0.0;

    final data = [
      {'label': 'Customers', 'value': customers, 'color': AppColors.blue},
      {'label': 'Approved Vendors', 'value': approvedVendors, 'color': AppColors.success},
      {'label': 'Pending Vendors', 'value': pendingVendors, 'color': AppColors.warning},
    ].where((e) => (e['value'] as double) > 0).toList();

    if (data.isEmpty) return const Center(child: Text('No data'));

    return _DoughnutChartBuilder(data: data);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Order Fulfillment Pie Chart
// ═════════════════════════════════════════════════════════════════════════════
class _OrderFulfillmentPieChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _OrderFulfillmentPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completed = double.tryParse('${stats['completedOrders']}') ?? 0.0;
    final total = double.tryParse('${stats['totalOrders']}') ?? 0.0;
    final other = total > completed ? total - completed : 0.0;

    final data = [
      {'label': 'Delivered', 'value': completed, 'color': AppColors.success},
      {'label': 'In Progress/Cancelled', 'value': other, 'color': AppColors.coral},
    ].where((e) => (e['value'] as double) > 0).toList();

    if (data.isEmpty) return const Center(child: Text('No data'));

    return _DoughnutChartBuilder(data: data);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Advanced Stat Card (Image Match)
// ═════════════════════════════════════════════════════════════════════════════
class _AdvancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String growthText;
  final Color contentColor;
  final List<double> chartData;
  final bool isBarChart;

  const _AdvancedStatCard({
    required this.title,
    required this.value,
    required this.growthText,
    required this.contentColor,
    required this.chartData,
    this.isBarChart = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = growthText.contains('↓');
    final activeContentColor = isNegative ? AppColors.danger : contentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w400)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                growthText,
                style: TextStyle(
                  color: isNegative ? AppColors.danger : AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (chartData.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 10,
              width: 70,
              height: 35,
              child: isBarChart ? _buildBarChart(activeContentColor) : _buildLineChart(activeContentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(Color chartColor) {
    final maxVal = chartData.reduce((a, b) => a > b ? a : b);
    final spots = chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal > 0 ? maxVal * 1.2 : 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Color chartColor) {
    final maxVal = chartData.reduce((a, b) => a > b ? a : b);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxVal > 0 ? maxVal * 1.2 : 10,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                color: chartColor,
                width: 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Users Tab
// ═════════════════════════════════════════════════════════════════════════════
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String? _togglingUserId;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AdminProvider provider) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.fetchUsers(search: query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.users.isEmpty) return const ListSkeleton(itemCount: 5);

        final stats = provider.userStats;
        final total = stats?['totalUsers'] ?? provider.users.length;
        final active = stats?['activeUsers'] ?? 0;
        final inactive = stats?['inactiveUsers'] ?? 0;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Users', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$total registered customer${total == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stat tiles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.people_rounded, '$total', 'Total users', AppColors.blueLight, AppColors.blueDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.check_circle_outline_rounded, '$active', 'Active', AppColors.successLight, AppColors.successDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.block_rounded, '$inactive', 'Inactive', AppColors.mutedLight, AppColors.muted))),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => _onSearchChanged(q, provider),
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.muted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            provider.fetchUsers();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                  ),
                ),
              ),
            ),

            // List
            if (provider.users.isEmpty)
              const Expanded(child: EmptyState(icon: Icons.people_outline_rounded, title: 'No customers', message: 'No customers registered yet.'))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.fetchUsers,
                  color: AppColors.coral,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, endIndent: 14),
                    itemBuilder: (context, index) {
                      final user = provider.users[index];
                      final isActive = user['isActive'] != false;
                      final joinDate = user['createdAt'] != null ? _formatJoinDate(user['createdAt']) : '';
                      final isToggling = _togglingUserId == user['_id'];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.blueLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user['fullName'] ?? ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.blueDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name + email + join date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['fullName'] ?? '',
                                    style: AppTextStyles.cardTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user['email'] ?? '',
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (joinDate.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Joined $joinDate',
                                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Status + actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.successLight : AppColors.mutedLight,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        size: 10,
                                        color: isActive ? AppColors.successDark : AppColors.muted,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isActive ? AppColors.successDark : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: isToggling ? null : () => _toggleUserStatus(context, user, provider),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isActive ? null : AppColors.successLight,
                                      border: isActive ? Border.all(color: AppColors.divider) : null,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: isToggling
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted))
                                        : Text(
                                            isActive ? 'Deactivate' : 'Activate',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isActive ? AppColors.muted : AppColors.successDark,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _toggleUserStatus(BuildContext context, dynamic user, AdminProvider provider) {
    final isActive = user['isActive'] != false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(isActive ? 'Deactivate user' : 'Activate user', style: AppTextStyles.sectionHeading),
        content: Text(
          isActive
              ? 'Deactivate "${user['fullName']}"? They will not be able to log in.'
              : 'Activate "${user['fullName']}"? They will be able to log in again.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _togglingUserId = user['_id']);
              await provider.toggleUserStatus(user['_id']);
              if (mounted) setState(() => _togglingUserId = null);
            },
            child: Text(
              isActive ? 'Deactivate' : 'Activate',
              style: AppTextStyles.label.copyWith(color: isActive ? AppColors.muted : AppColors.successDark),
            ),
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _formatJoinDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays < 1) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
      return '${(diff.inDays / 365).floor()} years ago';
    } catch (_) {
      return '';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Vendors Tab
// ═════════════════════════════════════════════════════════════════════════════
class AdminVendorsTab extends StatefulWidget {
  const AdminVendorsTab({super.key});

  @override
  State<AdminVendorsTab> createState() => _AdminVendorsTabState();
}

class _AdminVendorsTabState extends State<AdminVendorsTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AdminProvider provider) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.fetchVendors(
        search: query.isEmpty ? null : query,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.vendors.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.vendors.isEmpty) return const EmptyState(icon: Icons.storefront_outlined, title: 'No vendors', message: 'No vendors registered yet.');

        final vStats = provider.vendorStats;
        final totalV = vStats?['totalVendors'] ?? provider.vendors.length;
        final approved = vStats?['approvedVendors'] ?? 0;
        final pending = vStats?['pendingVendors'] ?? 0;

        final pendingVendors = provider.vendors.where((v) => v['vendorApprovalStatus'] == 'pending').toList();

        final filteredList = _selectedStatus == 'All'
            ? provider.vendors.where((v) => v['vendorApprovalStatus'] != 'pending').toList()
            : provider.vendors.where((v) => v['vendorApprovalStatus'] == _selectedStatus.toLowerCase()).toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendors', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$totalV registered vendor${totalV == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stat tiles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.storefront_rounded, '$totalV', 'Total', AppColors.coralLight, AppColors.coralDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.check_circle_outline_rounded, '$approved', 'Approved', AppColors.successLight, AppColors.successDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.pending_outlined, '$pending', 'Pending', AppColors.warningLight, AppColors.warningDark))),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => _onSearchChanged(q, provider),
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search vendors...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.muted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            provider.fetchVendors(status: _selectedStatus == 'All' ? null : _selectedStatus);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                  ),
                ),
              ),
            ),

            // Status filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ['All', 'Pending', 'Approved', 'Suspended'].length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = ['All', 'Pending', 'Approved', 'Suspended'][index];
                  final isSelected = _selectedStatus == status;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = status);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.coral : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isSelected ? AppColors.coral : AppColors.divider),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchVendors,
                color: AppColors.coral,
                child: filteredList.isEmpty && (_selectedStatus == 'All' ? pendingVendors.isEmpty : true)
                    ? EmptyState(icon: Icons.storefront_outlined, title: 'No vendors', message: 'No $_selectedStatus vendors found.')
                    : _buildVendorListView(pendingVendors, filteredList, context, provider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVendorListView(
    List<dynamic> pendingVendors,
    List<dynamic> filteredList,
    BuildContext context,
    AdminProvider provider,
  ) {
    final items = <Widget>[];
    if ((_selectedStatus == 'All' || _selectedStatus == 'Pending') && pendingVendors.isNotEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Pending approval', style: AppTextStyles.label.copyWith(color: AppColors.warningDark)),
      ));
      items.add(const SizedBox(height: 8));
      items.addAll(pendingVendors.map((v) => _buildPendingVendorCard(context, v, provider)));
      items.add(const SizedBox(height: 16));
    }
    if (_selectedStatus != 'Pending' && filteredList.isNotEmpty) {
      if (_selectedStatus == 'All') {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('All vendors', style: AppTextStyles.label),
        ));
      }
      items.add(const SizedBox(height: 8));
      items.addAll(filteredList.map((v) => _buildApprovedVendorCard(context, v, provider)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildPendingVendorCard(BuildContext context, dynamic vendor, AdminProvider provider) {
    final appliedDate = vendor['createdAt'] != null ? _formatAppliedDate(vendor['createdAt']) : '';
    final categories = (vendor['categories'] as List?)?.join(', ') ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.warningLight, shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.warningDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor['shopName'] ?? vendor['fullName'] ?? '', style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      appliedDate.isNotEmpty ? 'Applied $appliedDate' : 'Awaiting review',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: categories.split(', ').map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.muted)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.updateVendorStatus(vendor['_id'], 'approved'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.updateVendorStatus(vendor['_id'], 'suspended'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('Reject', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedVendorCard(BuildContext context, dynamic vendor, AdminProvider provider) {
    final status = vendor['vendorApprovalStatus'];
    final isSuspended = status == 'suspended';
    final productCount = vendor['productCount'] ?? 0;

    return Opacity(
      opacity: isSuspended ? 0.75 : 1.0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            SlideFadePageRoute(
              builder: (_) => AdminVendorDetailScreen(vendorId: vendor['_id']),
            ),
          );
        },
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
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
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$productCount product${productCount == 1 ? '' : 's'} listed',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusChip(status),
                if (isSuspended) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => provider.updateVendorStatus(vendor['_id'], 'approved'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text('Reinstate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.successDark)),
                    ),
                  ),
                ] else if (status == 'approved') ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showSuspendDialog(context, vendor, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('Suspend', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    switch (status) {
      case 'approved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 12, color: AppColors.successDark),
              SizedBox(width: 4),
              Text('Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.successDark)),
            ],
          ),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: AppColors.warningDark),
              SizedBox(width: 4),
              Text('Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.warningDark)),
            ],
          ),
        );
      case 'suspended':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.mutedLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_rounded, size: 12, color: AppColors.muted),
              SizedBox(width: 4),
              Text('Suspended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static String _formatAppliedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays < 1) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
      return '${(diff.inDays / 365).floor()} years ago';
    } catch (_) {
      return '';
    }
  }

  void _showSuspendDialog(BuildContext context, dynamic vendor, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Suspend vendor', style: AppTextStyles.sectionHeading),
        content: Text('Suspend "${vendor['shopName'] ?? vendor['fullName']}"? They will not be able to list or sell products.', style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateVendorStatus(vendor['_id'], 'suspended');
            },
            child: Text('Suspend', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Products Tab
// ═════════════════════════════════════════════════════════════════════════════
class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  String? _deletingProductId;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AdminProvider provider) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.fetchProducts(search: query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.products.isEmpty) return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'No products listed yet.');

        final pStats = provider.productStats;
        final totalP = pStats?['totalProducts'] ?? provider.products.length;
        final available = pStats?['availableProducts'] ?? 0;
        final unavailable = pStats?['unavailableProducts'] ?? 0;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Products', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$totalP product${totalP == 1 ? '' : 's'} listed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stat tiles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.inventory_2_rounded, '$totalP', 'Total', AppColors.successLight, AppColors.successDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.check_circle_outline_rounded, '$available', 'Available', AppColors.blueLight, AppColors.blueDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.remove_circle_outline_rounded, '$unavailable', 'Unavailable', AppColors.mutedLight, AppColors.muted))),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => _onSearchChanged(q, provider),
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.muted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            provider.fetchProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchProducts,
                color: AppColors.coral,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 68, endIndent: 14),
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    final isAvailable = (product['stockQuantity'] ?? 0) > 0 && product['productStatus'] != 'unavailable';
                    final isDeleting = _deletingProductId == product['_id'];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        SlideFadePageRoute(builder: (_) => AdminProductDetailScreen(productId: product['_id'])),
                      ),
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: AppColors.background,
                              child: product['images'] != null && product['images'].isNotEmpty
                                  ? Image.network(product['images'][0], fit: BoxFit.cover)
                                  : const Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name + vendor
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'] ?? '',
                                  style: AppTextStyles.cardTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product['vendorId']?['shopName'] ?? product['vendorId']?['fullName'] ?? 'Vendor',
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price + status + delete
                          Flexible(
                            fit: FlexFit.loose,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Rs. ${product['price']}${(product['priceUnit'] ?? 'piece') != 'piece' ? '/${_unitLabel(product['priceUnit'] ?? 'piece')}' : ''}', style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    _buildProductStatusChip(isAvailable),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: isDeleting ? null : () => _showDeleteDialog(context, product, provider),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDeleting ? AppColors.mutedLight : AppColors.dangerLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isDeleting
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted))
                                         : const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductStatusChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.successLight : AppColors.mutedLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_rounded : Icons.close_rounded,
            size: 10,
            color: isAvailable ? AppColors.successDark : AppColors.muted,
          ),
          const SizedBox(width: 3),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isAvailable ? AppColors.successDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

void _showDeleteDialog(BuildContext context, dynamic product, AdminProvider provider) {
    final title = product['title'] ?? 'this product';
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: provider.checkProductDeletable(product['_id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Row(
                children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Checking...')],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final canDelete = data['data']?['canDelete'] ?? false;
          final reason = data['data']?['reason'] ?? '';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
            title: Text(canDelete ? 'Delete product' : 'Cannot delete product', style: AppTextStyles.sectionHeading),
            content: Text(
              canDelete
                  ? 'Delete "$title"? This action cannot be undone.'
                  : reason,
              style: AppTextStyles.bodyMuted,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
              ),
            ],
          );
        },
      ),
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
}

// ═════════════════════════════════════════════════════════════════════════════
// Orders Tab
// ═════════════════════════════════════════════════════════════════════════════
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  String _selectedFilter = 'All';
  static const _filters = ['All', 'Pending', 'Confirmed', 'Delivered', 'Rejected', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.orders.isEmpty) return const OrderCardSkeleton();
        if (provider.orders.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders', message: 'No orders placed yet.');

        final oStats = provider.orderStats;
        final totalO = oStats?['totalOrders'] ?? provider.orders.length;
        final pendingO = oStats?['pendingOrders'] ?? 0;
        final deliveredO = oStats?['deliveredOrders'] ?? 0;

        final filteredOrders = _selectedFilter == 'All'
            ? provider.orders
            : provider.orders.where((o) => o['orderStatus'] == _selectedFilter).toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Orders', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$totalO order${totalO == 1 ? '' : 's'} placed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stat tiles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.receipt_long_rounded, '$totalO', 'Total', AppColors.blueLight, AppColors.blueDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.pending_outlined, '$pendingO', 'Pending', AppColors.warningLight, AppColors.warningDark))),
                  const SizedBox(width: 8),
                  Expanded(child: FadeScaleIn(child: AdminStatTile(Icons.check_circle_outline_rounded, '$deliveredO', 'Delivered', AppColors.successLight, AppColors.successDark))),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isActive = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.coral : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isActive ? AppColors.coral : AppColors.divider),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchOrders,
                color: AppColors.coral,
                child: filteredOrders.isEmpty
                    ? Center(child: Text('No $_selectedFilter orders', style: AppTextStyles.bodyMuted))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${(() { final id = order['_id'].toString(); return id.length > 6 ? id.substring(id.length - 6) : id; })().toUpperCase()}',
                                      style: AppTextStyles.label.copyWith(color: AppColors.muted),
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
                                        order['customerId']?['fullName'] ?? 'Customer',
                                        style: AppTextStyles.cardTitle,
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
                                        order['vendorId']?['shopName'] ?? 'Vendor',
                                        style: AppTextStyles.bodyMuted,
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
                                      style: AppTextStyles.caption,
                                    ),
                                    Text(
                                      'Rs. ${order['totalAmount']}',
                                      style: AppTextStyles.price,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
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

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton
// ═════════════════════════════════════════════════════════════════════════════
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
          childAspectRatio: 1.15,
          children: List.generate(4, (_) => const StatCardSkeleton()),
        ),
      ],
    );
  }
}
