import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/connection_status_banner.dart';
import 'admin_dashboard.dart';
import 'admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  int _activeNavIndex = 0;
  final _dashboardKey = GlobalKey<AdminDashboardState>();

  void _switchDashboardTab(int topTabIndex, int navIndex) {
    _dashboardKey.currentState?.switchTab(topTabIndex);
    setState(() {
      _selectedIndex = 0;
      _activeNavIndex = navIndex;
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
              child: _selectedIndex == 0
                  ? AdminDashboard(
                      key: _dashboardKey,
                      onTabChanged: (tabIndex) {
                        setState(() {
                          _selectedIndex = 0;
                          _activeNavIndex = tabIndex;
                        });
                      },
                    )
                  : const AdminProfileScreen(key: ValueKey('admin_profile')),
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
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                dashboardTab: 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.people_outlined,
                label: 'Users',
                dashboardTab: 1,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.storefront_outlined,
                label: 'Vendors',
                dashboardTab: 2,
                showBadge: true,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                dashboardTab: 3,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.receipt_outlined,
                label: 'Orders',
                dashboardTab: 4,
              ),
              _buildNavItem(
                index: 5,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                dashboardTab: -1,
              ),
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
    required int dashboardTab,
    bool showBadge = false,
  }) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (dashboardTab >= 0) {
          _switchDashboardTab(dashboardTab, index);
        } else {
          setState(() {
            _selectedIndex = 1;
            _activeNavIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.coralLight : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.coralDark : const Color(0xFFB9AF9A),
                ),
                if (showBadge)
                  Consumer<AdminProvider>(
                    builder: (_, admin, __) {
                      final pendingCount = admin.vendors
                          .where((v) => v['vendorApprovalStatus'] == 'pending')
                          .length;
                      if (pendingCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 2,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
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
        ],
      ),
    );
  }
}
