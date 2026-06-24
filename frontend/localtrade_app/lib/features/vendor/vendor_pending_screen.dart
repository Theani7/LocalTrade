import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';
import '../common/logout_dialog.dart';

class VendorPendingScreen extends StatefulWidget {
  const VendorPendingScreen({super.key});

  @override
  State<VendorPendingScreen> createState() => _VendorPendingScreenState();
}

class _VendorPendingScreenState extends State<VendorPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final status = user?['vendorApprovalStatus'] ?? 'pending';
    final isSuspended = status == 'suspended';
    final shopName = user?['shopName'] ?? '';

    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Vendor status',
          style: AppTextStyles.screenTitle,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSuspended
                            ? AppColors.dangerLight
                            : AppColors.warningLight,
                      ),
                      child: Icon(
                        isSuspended ? Icons.block_rounded : Icons.hourglass_top_rounded,
                        size: 44,
                        color: isSuspended ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSuspended ? AppColors.dangerLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSuspended ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSuspended ? 'Suspended' : 'Pending review',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSuspended ? AppColors.dangerDark : AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isSuspended ? 'Account suspended' : 'Approval pending',
                style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                isSuspended
                    ? 'Your account has been suspended by the administrator. Please contact support for more information.'
                    : shopName.isNotEmpty
                        ? 'Your vendor account for "$shopName" is being reviewed by our team. You will be notified once it is approved.'
                        : 'Your vendor account is being reviewed by our team. You will be notified once it is approved.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
              ),

              const Spacer(flex: 1),

              // What happens next card
              if (!isSuspended)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens next',
                        style: AppTextStyles.label.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 14),
                      _StepRow(
                        icon: Icons.person_add_outlined,
                        label: 'Account created',
                        isComplete: true,
                      ),
                      const SizedBox(height: 12),
                      _StepRow(
                        icon: Icons.rate_review_outlined,
                        label: 'Team reviews your shop',
                        isComplete: false,
                        isCurrent: true,
                      ),
                      const SizedBox(height: 12),
                      _StepRow(
                        icon: Icons.storefront_outlined,
                        label: 'Start selling',
                        isComplete: false,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => LogoutDialog.show(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isComplete;
  final bool isCurrent;

  const _StepRow({
    required this.icon,
    required this.label,
    this.isComplete = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete
        ? AppColors.success
        : isCurrent
            ? AppColors.warning
            : AppColors.muted;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? AppColors.successLight
                : isCurrent
                    ? AppColors.warningLight
                    : AppColors.mutedLight,
          ),
          child: Icon(
            isComplete ? Icons.check_rounded : icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
              color: isComplete || isCurrent ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
