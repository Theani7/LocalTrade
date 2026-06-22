import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import 'register_screen.dart';

/// A dedicated screen that lets the user pick between **Customer** and **Vendor**
/// before proceeding to the actual registration form. It mirrors the role cards
/// used in the original RegisterScreen but isolates the selection step, making it
/// reusable when navigating from the login bottom‑sheet.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

    // Navigate to the RegisterScreen for the selected role and bubble the result
    // back to the caller. Using a callback chain (then) avoids using BuildContext
    // across an async gap, satisfying the lint rule.
    void _navigate(BuildContext ctx, String role) {
      Navigator.of(ctx)
          .push<bool>(MaterialPageRoute(builder: (_) => RegisterScreen(initialRole: role)))
          .then((result) {
        if (result == true && Navigator.canPop(ctx)) {
          Navigator.of(ctx).pop(true);
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Register as',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigate(context, 'customer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_outline, color: AppColors.muted),
                                SizedBox(height: 4),
                                Text('Customer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.muted)),
                                SizedBox(height: 2),
                                Text('Browse and reserve from local vendors', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigate(context, 'vendor'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.storefront_outlined, color: AppColors.muted),
                                SizedBox(height: 4),
                                Text('Vendor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.muted)),
                                SizedBox(height: 2),
                                Text('List your products and receive orders', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Optional cancel button to go back without choosing
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlineNegative,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
