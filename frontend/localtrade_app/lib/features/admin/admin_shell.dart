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
  final _dashboardKey = GlobalKey<AdminDashboardState>();

  void _switchDashboardTab(int topTabIndex) {
    _dashboardKey.currentState?.switchTab(topTabIndex);
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboard(key: _dashboardKey),
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
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    outlineIcon: Icons.dashboard_outlined,
                    filledIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  _buildNavItem(
                    index: 1,
                    outlineIcon: Icons.storefront_outlined,
                    filledIcon: Icons.storefront_rounded,
                    label: 'Vendors',
                    showBadge: true,
                  ),
                  _buildNavItem(
                    index: 2,
                    outlineIcon: Icons.receipt_outlined,
                    filledIcon: Icons.receipt_rounded,
                    label: 'Orders',
                  ),
                  _buildNavItem(
                    index: 3,
                    outlineIcon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    label: 'Profile',
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
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    bool showBadge = false,
  }) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          _switchDashboardTab(0);
        } else if (index == 1) {
          _switchDashboardTab(2);
        } else if (index == 2) {
          _switchDashboardTab(4);
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? filledIcon : outlineIcon,
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
            const SizedBox(height: 4),
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
