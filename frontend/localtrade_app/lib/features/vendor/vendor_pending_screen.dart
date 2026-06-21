import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/login_screen.dart';

class VendorPendingScreen extends StatelessWidget {
  const VendorPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final status = user?['vendorApprovalStatus'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendor status'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 22),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == 'suspended' ? AppColors.dangerLight : AppColors.warningLight,
                ),
                child: Icon(
                  status == 'suspended' ? Icons.block_rounded : Icons.hourglass_top_rounded,
                  size: 56,
                  color: status == 'suspended' ? AppColors.danger : AppColors.warning,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                status == 'suspended' ? 'Account suspended' : 'Approval pending',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                status == 'suspended'
                    ? 'Your account has been suspended by the administrator. Please contact support for more information.'
                    : 'Your vendor account is currently being reviewed by our team. You will be notified once it is approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Logout button
              SizedBox(
                width: 200,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _handleLogout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
