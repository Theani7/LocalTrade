import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';

class ChangePasswordScreen extends StatelessWidget {
  final bool forceMode;
  const ChangePasswordScreen({super.key, this.forceMode = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceMode,
      child: AppScaffold(
        backgroundColor: AppColors.background,
        appBar: forceMode ? null : AppBar(
          title: Text('Change password', style: AppTextStyles.screenTitle),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: true,
        ),
        body: ChangePasswordBody(forceMode: forceMode),
      ),
    );
  }
}

class ChangePasswordBody extends StatefulWidget {
  final bool forceMode;
  const ChangePasswordBody({super.key, this.forceMode = false});

  @override
  State<ChangePasswordBody> createState() => _ChangePasswordBodyState();
}

class _ChangePasswordBodyState extends State<ChangePasswordBody> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success;
    if (widget.forceMode) {
      success = await provider.forceChangePassword(
        _newPasswordController.text.trim(),
        _confirmPasswordController.text.trim(),
      );
    } else {
      success = await provider.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
        _confirmPasswordController.text.trim(),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Password changed successfully' : (provider.error ?? 'Failed to change password'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
    );
    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              widget.forceMode ? 'Set a new password' : 'Change your password',
              style: AppTextStyles.sectionHeading,
            ),
            const SizedBox(height: 4),
            Text(
              widget.forceMode
                  ? 'For security, you must set a new password before continuing'
                  : 'This action updates your login credentials',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.forceMode ? 'Create a new password' : 'Set a new password',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text('Choose a strong password for your account',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 20),
                  if (!widget.forceMode) ...[
                    _buildPasswordField('Current password', _currentPasswordController, _obscureCurrent, () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    }, null),
                    const SizedBox(height: 12),
                  ],
                  _buildPasswordField('New password', _newPasswordController, _obscureNew, () {
                    setState(() => _obscureNew = !_obscureNew);
                  }, (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) return 'At least 6 characters';
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirm new password', _confirmPasswordController, _obscureConfirm, () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  }, (value) {
                    if (value != null && value.isNotEmpty && value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    if (value != null && value.isNotEmpty && value.length < 6) return 'At least 6 characters';
                    return null;
                  }),
                  const SizedBox(height: 22),
                  Consumer<AuthProvider>(
                    builder: (context, provider, _) {
                      return ElevatedButton(
                        onPressed: provider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                            : Text('Update password', style: AppTextStyles.buttonPrimary),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Password must be at least 6 characters long',
                  style: AppTextStyles.caption),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback onToggle, String? Function(String?)? extraValidator) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400),
        floatingLabelStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.muted),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger, width: 1)),
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (extraValidator != null) {
          final result = extraValidator(value);
          if (result != null) return result;
        }
        return null;
      },
    );
  }
}
