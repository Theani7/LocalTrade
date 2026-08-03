import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

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
    return AppScaffold(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.coral),
          const SizedBox(height: 24),
          Text(
            'Reset\nPassword',
            style: TextStyle(
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your email and we will send you\na 6-digit OTP to reset your password.',
            style: const TextStyle(fontSize: 16, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.ink, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, provider, _) => AppButton(
              label: 'Send OTP',
              isLoading: provider.isLoading,
              onPressed: provider.isLoading ? null : _submitEmail,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Back to login',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.coral),
              textAlign: TextAlign.center,
            ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.pin_outlined, size: 48, color: AppColors.blueDark),
          const SizedBox(height: 24),
          const Text(
            'Enter\nOTP',
            style: TextStyle(
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'A 6-digit OTP was sent to\n${_emailController.text.trim()}',
            style: const TextStyle(fontSize: 16, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink, fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: const TextStyle(fontSize: 32, letterSpacing: 8, color: AppColors.divider),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) return 'Enter the 6-digit OTP';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, provider, _) => AppButton(
              label: 'Verify OTP',
              isLoading: provider.isLoading,
              onPressed: provider.isLoading ? null : _submitOtp,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _submitEmail,
            child: const Text('Resend OTP',
              style: TextStyle(fontSize: 15, color: AppColors.coral, fontWeight: FontWeight.w600)),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.lock_open_rounded, size: 48, color: AppColors.successDark),
          const SizedBox(height: 24),
          const Text(
            'New\nPassword',
            style: TextStyle(
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose a new password for your account.',
            style: TextStyle(fontSize: 16, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppColors.ink, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'New password',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
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
            style: const TextStyle(color: AppColors.ink, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Confirm password',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, provider, _) => AppButton(
              label: 'Reset password',
              isLoading: provider.isLoading,
              onPressed: provider.isLoading ? null : _submitPassword,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildCard entirely
}
