import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/status_badge.dart';
import '../customer/notification_screen.dart';
import '../auth/login_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
          // Notification bell
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
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
          const SizedBox(width: 8),
          // Logout
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Logout', style: AppTextStyles.sectionHeading),
        content: Text('Are you sure you want to log out?', style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMuted),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedLight,
              foregroundColor: AppColors.ink,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
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
                  childAspectRatio: 1.15,
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
                Row(
                  children: [
                    _buildExportChip(context, 'Overview', 'overview'),
                    const SizedBox(width: 8),
                    _buildExportChip(context, 'Orders', 'orders'),
                    const SizedBox(width: 8),
                    _buildExportChip(context, 'Products', 'products'),
                    const SizedBox(width: 8),
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
        if (csv != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label data exported (${csv.split('\n').length} rows)'),
              backgroundColor: AppColors.success,
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
    return PieChart(
      PieChartData(
        sections: revenueByCategory.map((cat) {
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
      final maxCount = dailyStats.fold<int>(0, (max, d) {
        final count = (d['count'] ?? 0) as int;
        return count > max ? count : max;
      });
      for (final day in dailyStats) {
        final count = (day['count'] ?? 0) as int;
        barHeights.add(maxCount > 0 ? count / maxCount : 0.3);
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
// Users Tab
// ═════════════════════════════════════════════════════════════════════════════
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String? _togglingUserId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.users.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.users.isEmpty) return const EmptyState(icon: Icons.people_outline_rounded, title: 'No users', message: 'No users registered yet.');

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Users', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.users.length} registered user${provider.users.length == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchUsers,
                color: AppColors.coral,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 62, endIndent: 14),
                  itemBuilder: (context, index) {
                    final user = provider.users[index];
                    final isAdmin = user['role'] == 'admin';
                    final isVendor = user['role'] == 'vendor';
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
                              color: isVendor ? AppColors.coralLight : AppColors.blueLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user['fullName'] ?? ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isVendor ? AppColors.coralDark : AppColors.blueDark,
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
                          // Role badge + actions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? AppColors.blueLight
                                      : isVendor
                                          ? AppColors.coralLight
                                          : AppColors.mutedLight,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  user['role'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isAdmin
                                        ? AppColors.blueDark
                                        : isVendor
                                            ? AppColors.coralDark
                                            : AppColors.muted,
                                  ),
                                ),
                              ),
                              if (!isAdmin) ...[
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
        title: Text(isActive ? 'Deactivate user' : 'Activate user'),
        content: Text(
          isActive
              ? 'Deactivate "${user['fullName']}"? They will not be able to log in.'
              : 'Activate "${user['fullName']}"? They will be able to log in again.',
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
              style: TextStyle(color: isActive ? AppColors.muted : AppColors.successDark),
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
class AdminVendorsTab extends StatelessWidget {
  const AdminVendorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.vendors.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.vendors.isEmpty) return const EmptyState(icon: Icons.storefront_outlined, title: 'No vendors', message: 'No vendors registered yet.');

        final pendingVendors = provider.vendors.where((v) => v['vendorApprovalStatus'] == 'pending').toList();
        final otherVendors = provider.vendors.where((v) => v['vendorApprovalStatus'] != 'pending').toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendors', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.vendors.length} registered vendor${provider.vendors.length == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchVendors,
                color: AppColors.coral,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Pending section
                    if (pendingVendors.isNotEmpty) ...[
                      Text('Pending approval', style: AppTextStyles.label.copyWith(color: AppColors.warningDark)),
                      const SizedBox(height: 8),
                      ...pendingVendors.map((vendor) => _buildPendingVendorCard(context, vendor, provider)),
                      const SizedBox(height: 16),
                    ],

                    // All vendors
                    if (otherVendors.isNotEmpty) ...[
                      Text('All vendors', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      ...otherVendors.map((vendor) => _buildApprovedVendorCard(context, vendor, provider)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
        title: const Text('Suspend vendor'),
        content: Text('Suspend "${vendor['shopName'] ?? vendor['fullName']}"? They will not be able to list or sell products.'),
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
            child: const Text('Suspend', style: TextStyle(color: AppColors.muted)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) return const ListSkeleton(itemCount: 5);
        if (provider.products.isEmpty) return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'No products listed yet.');

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Products', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.products.length} product${provider.products.length == 1 ? '' : 's'} listed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
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

                    return Container(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rs. ${product['price']}', style: AppTextStyles.label),
                              const SizedBox(height: 4),
                              _buildProductStatusChip(isAvailable),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: isDeleting ? null : () => _showDeleteDialog(context, product, provider),
                                child: isDeleting
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted))
                                    : const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.muted),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${product['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _deletingProductId = product['_id']);
              await provider.deleteProduct(product['_id']);
              if (mounted) setState(() => _deletingProductId = null);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
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

        final filteredOrders = _selectedFilter == 'All'
            ? provider.orders
            : provider.orders.where((o) => o['orderStatus'] == _selectedFilter).toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Orders', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.orders.length} order${provider.orders.length == 1 ? '' : 's'} placed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
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
