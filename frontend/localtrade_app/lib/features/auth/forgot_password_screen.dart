import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0 = email, 1 = otp, 2 = new password

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  String? _tempToken;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final message = await provider.forgotPassword(_emailController.text.trim());

    if (!mounted) return;

    if (message != null) {
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Something went wrong'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  Future<void> _submitOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final tempToken = await provider.verifyOtp(_emailController.text.trim(), _otpController.text.trim());

    if (!mounted) return;

    if (tempToken != null) {
      _tempToken = tempToken;
      setState(() => _step = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP verified. Set your new password.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Invalid OTP'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  Future<void> _submitPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final message = await provider.resetPasswordWithOtp(_tempToken!, _passwordController.text);

    if (!mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to reset password'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot password'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  // ── Step 1: Email ─────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.coral),
          ),
          const SizedBox(height: 20),
          Text('Reset your password', style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we will send you\na 6-digit OTP to reset your password.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.ink, fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, provider, _) => AppButton(
                    label: 'Send OTP',
                    isLoading: provider.isLoading,
                    onPressed: provider.isLoading ? null : _submitEmail,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Back to login',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP ───────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.pin_outlined, size: 36, color: AppColors.blueDark),
          ),
          const SizedBox(height: 20),
          Text('Enter OTP', style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text(
            'A 6-digit OTP was sent to\n${_emailController.text.trim()}',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink, fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: '6-digit OTP',
                    hintText: '- - - - - -',
                    hintStyle: TextStyle(fontSize: 28, letterSpacing: 8, color: AppColors.divider),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) return 'Enter the 6-digit OTP';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, provider, _) => AppButton(
                    label: 'Verify OTP',
                    isLoading: provider.isLoading,
                    onPressed: provider.isLoading ? null : _submitOtp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _submitEmail,
            child: Text('Resend OTP',
              style: TextStyle(fontSize: 13, color: AppColors.coral, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Step 3: New Password ──────────────────────────────────────
  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.lock_open_rounded, size: 36, color: AppColors.successDark),
          ),
          const SizedBox(height: 20),
          Text('Set new password', style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text(
            'Choose a new password for your account.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.ink, fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.muted),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.ink, fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.muted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, provider, _) => AppButton(
                    label: 'Reset password',
                    isLoading: provider.isLoading,
                    onPressed: provider.isLoading ? null : _submitPassword,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
