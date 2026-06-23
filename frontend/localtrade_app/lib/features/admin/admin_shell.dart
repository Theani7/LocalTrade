import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboard(
            key: _dashboardKey,
            onTabChanged: (tabIndex) {
              setState(() {
                _selectedIndex = 0;
                _activeNavIndex = tabIndex;
              });
            },
          ),
          const AdminProfileScreen(),
        ],
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
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
            Center(
              child: Container(
                width: 100,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D0BE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
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
          Stack(
            clipBehavior: Clip.none,
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
                      right: -6,
                      top: -4,
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
    );
  }
}
