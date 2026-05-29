import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'admin_feedback_results_screen.dart';
import '../customer/customer_profile_screen.dart';
import '../auth/login_screen.dart';
import 'package:intl/intl.dart';

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
    await Future.wait([
      admin.fetchAnalytics(),
      admin.fetchUsers(),
      admin.fetchVendors(),
      admin.fetchProducts(),
      admin.fetchOrders(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackResultsScreen())),
            icon: const Icon(Icons.rate_review_rounded),
            tooltip: 'UAT Feedback Results',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen())),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'My Profile',
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: !isDesktop,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_rounded, size: 20)),
            Tab(text: 'Users', icon: Icon(Icons.people_rounded, size: 20)),
            Tab(text: 'Vendors', icon: Icon(Icons.storefront_rounded, size: 20)),
            Tab(text: 'Products', icon: Icon(Icons.inventory_2_rounded, size: 20)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long_rounded, size: 20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end your administrative session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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

// --- Analytics Tab ---
class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.analytics == null) return _buildSkeletonLoader();
        if (admin.analytics == null) {
          return EmptyState(
            icon: Icons.analytics_outlined,
            title: 'Insights Unavailable',
            message: 'Connect to the server to view live system analytics.',
            onAction: () => admin.fetchAnalytics(),
            actionLabel: 'Try Again',
          );
        }

        final stats = admin.analytics!['stats'];
        final dailyStats = admin.analytics!['dailyStats'] as List;
        final revenueByCategory = admin.analytics!['revenueByCategory'] as List;
        final recent = admin.analytics!['recentOrders'] as List;

        return RefreshIndicator(
          onRefresh: admin.fetchAnalytics,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Performance Snapshot'),
                const SizedBox(height: 16),
                _buildStatGrid(context, stats),
                const SizedBox(height: 32),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildRevenueChart(dailyStats)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildCategoryChart(revenueByCategory)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildRevenueChart(dailyStats),
                        const SizedBox(height: 24),
                        _buildCategoryChart(revenueByCategory),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                _buildHeader('Recent Transactions'),
                const SizedBox(height: 16),
                _buildRecentOrders(recent),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5),
    );
  }

  Widget _buildStatGrid(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        }
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            switch (index) {
              case 0: return _buildStatCard('Revenue', 'Rs. ${NumberFormat('#,##,###').format(stats['totalRevenue'])}', Colors.green.shade700, Icons.payments_rounded);
              case 1: return _buildStatCard('Orders', '${stats['totalOrders']}', Colors.blue.shade700, Icons.shopping_cart_rounded);
              case 2: return _buildStatCard('Users', '${stats['totalUsers']}', Colors.purple.shade700, Icons.group_rounded);
              case 3: return _buildStatCard('Products', '${stats['totalProducts']}', Colors.orange.shade700, Icons.category_rounded);
              default: return const SizedBox();
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List dailyStats) {
    if (dailyStats.isEmpty) return const SizedBox();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend (7 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyStats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(List categoryStats) {
    if (categoryStats.isEmpty) return const SizedBox();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: categoryStats.map((e) {
                  final index = categoryStats.indexOf(e);
                  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: (e['revenue'] as num).toDouble(),
                    title: e['_id'],
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List recent) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
      child: recent.isEmpty 
        ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No recent activity recorded.')))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final order = recent[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(
                  'Order #${order['_id'].toString().substring(18).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${order['customerId']['fullName']} ➔ ${order['vendorId']['fullName']}',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  'Rs. ${order['totalAmount']}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
            },
          ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(height: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          ],
        ),
      ),
    );
  }
}

// --- Common Base Tab with Search ---
abstract class AdminBaseTab extends StatefulWidget {
  const AdminBaseTab({super.key});
}

abstract class AdminBaseTabState<T extends AdminBaseTab> extends State<T> {
  final TextEditingController searchController = TextEditingController();
  String? selectedFilter;
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onSearch() => refresh();
  void refresh();
  
  Widget buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: TextField(
        controller: searchController,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: searchController.text.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { searchController.clear(); onSearch(); })
            : null,
          filled: true,
          fillColor: AppTheme.surfaceColor,
        ),
      ),
    );
  }
}

// --- Users Tab ---
class AdminUsersTab extends AdminBaseTab {
  const AdminUsersTab({super.key});
  @override
  AdminBaseTabState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends AdminBaseTabState<AdminUsersTab> {
  @override
  void initState() {
    super.initState();
    selectedFilter = 'All';
  }

  @override
  void refresh() {
    Provider.of<AdminProvider>(context, listen: false).fetchUsers(
      search: searchController.text,
      role: selectedFilter,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildSearchBar('Search users by name or email...'),
        _buildFilters(),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              if (admin.isLoading && admin.users.isEmpty) return const Center(child: CircularProgressIndicator());
              if (admin.users.isEmpty) return const EmptyState(icon: Icons.person_search_rounded, title: 'No Users Found', message: 'Try a different search term.');
              
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: admin.users.length,
                  itemBuilder: (context, index) {
                    final user = admin.users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(user['fullName'][0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user['fullName'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${user['email']}\n${user['role'].toString().toUpperCase()}', style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: Icon(
                          user['isActive'] == false ? Icons.block_rounded : Icons.check_circle_rounded,
                          color: user['isActive'] == false ? AppTheme.errorColor : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final roles = ['All', 'customer', 'vendor', 'admin'];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: roles.length,
        itemBuilder: (context, i) {
          final role = roles[i];
          final isSelected = selectedFilter == role;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedFilter = role);
                refresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))]
                    : AppTheme.softShadow,
                ),
                child: Center(
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Vendors Tab ---
class AdminVendorsTab extends AdminBaseTab {
  const AdminVendorsTab({super.key});
  @override
  AdminBaseTabState<AdminVendorsTab> createState() => _AdminVendorsTabState();
}

class _AdminVendorsTabState extends AdminBaseTabState<AdminVendorsTab> {
  @override
  void initState() {
    super.initState();
    selectedFilter = 'All';
  }

  @override
  void refresh() {
    Provider.of<AdminProvider>(context, listen: false).fetchVendors(
      search: searchController.text,
      status: selectedFilter,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildSearchBar('Search shop name or vendor...'),
        _buildFilters(),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              if (admin.isLoading && admin.vendors.isEmpty) return const Center(child: CircularProgressIndicator());
              if (admin.vendors.isEmpty) return const EmptyState(icon: Icons.store_rounded, title: 'No Vendors Found', message: 'No vendors match your current filter.');
              
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: admin.vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = admin.vendors[index];
                    final status = vendor['vendorApprovalStatus'];
                    
                    Color statusColor = Colors.orange;
                    if (status == 'approved') statusColor = Colors.green;
                    if (status == 'suspended') statusColor = Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.storefront_rounded, color: AppTheme.secondaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendor['shopName'] ?? vendor['fullName'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      vendor['fullName'],
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(status, statusColor),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  vendor['address'],
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              if (status != 'approved')
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => _confirmAction(context, admin, vendor, 'approved'),
                                ),
                              if (status == 'approved')
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.block_rounded, size: 18),
                                  label: const Text('Suspend'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                                  onPressed: () => _confirmAction(context, admin, vendor, 'suspended'),
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
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmAction(BuildContext context, AdminProvider admin, dynamic vendor, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${status[0].toUpperCase()}${status.substring(1)} Vendor?'),
        content: Text('Are you sure you want to $status "${vendor['shopName'] ?? vendor['fullName']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: status == 'approved' ? Colors.green : AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              final success = await admin.updateVendorStatus(vendor['_id'], status);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vendor successfully $status'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('Confirm $status'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final statuses = ['All', 'pending', 'approved', 'suspended'];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: statuses.length,
        itemBuilder: (context, i) {
          final status = statuses[i];
          final isSelected = selectedFilter == status;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedFilter = status);
                refresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))]
                    : AppTheme.softShadow,
                ),
                child: Center(
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Products Tab ---
class AdminProductsTab extends AdminBaseTab {
  const AdminProductsTab({super.key});
  @override
  AdminBaseTabState<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends AdminBaseTabState<AdminProductsTab> {
  @override
  void refresh() {
    Provider.of<AdminProvider>(context, listen: false).fetchProducts(
      search: searchController.text,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildSearchBar('Search products by title...'),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              if (admin.isLoading && admin.products.isEmpty) return const Center(child: CircularProgressIndicator());
              if (admin.products.isEmpty) return const EmptyState(icon: Icons.inventory_rounded, title: 'No Products', message: 'No matching products found.');
              
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: admin.products.length,
                  itemBuilder: (context, index) {
                    final product = admin.products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(product['images'][0], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                        ),
                        title: Text(
                          product['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Vendor: ${product['vendorId']['shopName'] ?? product['vendorId']['fullName']}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('Rs. ${product['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Orders Tab ---
class AdminOrdersTab extends AdminBaseTab {
  const AdminOrdersTab({super.key});
  @override
  AdminBaseTabState<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends AdminBaseTabState<AdminOrdersTab> {
  @override
  void initState() {
    super.initState();
    selectedFilter = 'All';
  }

  @override
  void refresh() {
    Provider.of<AdminProvider>(context, listen: false).fetchOrders(
      status: selectedFilter,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              if (admin.isLoading && admin.orders.isEmpty) return const Center(child: CircularProgressIndicator());
              if (admin.orders.isEmpty) return const EmptyState(icon: Icons.receipt_long_rounded, title: 'No Orders', message: 'No orders found for this status.');
              
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: admin.orders.length,
                  itemBuilder: (context, index) {
                    final order = admin.orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(
                          'Order #${order['_id'].toString().substring(18).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'To: ${order['customerId']['fullName']}\nStatus: ${order['orderStatus']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('Rs. ${order['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final statuses = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: statuses.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(statuses[i], style: const TextStyle(fontSize: 10)),
            selected: selectedFilter == statuses[i],
            onSelected: (val) { if (val) { setState(() => selectedFilter = statuses[i]); refresh(); } },
          ),
        ),
      ),
    );
  }
}
