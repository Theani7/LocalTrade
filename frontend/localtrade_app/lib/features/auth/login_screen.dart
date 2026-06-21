import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../admin/admin_dashboard.dart';
import '../vendor/vendor_dashboard.dart';
import '../vendor/vendor_pending_screen.dart';
import '../customer/customer_home_screen.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final role = authProvider.user?['role'];
        final status = authProvider.user?['vendorApprovalStatus'];

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else if (role == 'vendor') {
          if (status == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorDashboard()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorPendingScreen()));
          }
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerHomeScreen()));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filled credentials'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Simple Logo Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/round.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // App Name
                    const Center(
                      child: Text(
                        'LocalTrade',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tagline
                    const Center(
                      child: Text(
                        'Empowering local businesses, directly.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Classic Clean Glassmorphic Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Classic Email Input
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.04),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!value.contains('@')) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              
                              // Classic Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.04),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              
                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Forgot Password? Please contact admin at support@LocalTrade.com'),
                                        backgroundColor: AppTheme.primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryLight,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Classic Action Button
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Minimal Quick Fill Shortcuts
                              _QuickFillSection(onFill: _quickFill),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Create Account Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickFillSection extends StatelessWidget {
  final Function(String email, String password) onFill;

  const _QuickFillSection({required this.onFill});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'QUICK FILL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _buildLink(context, 'Vendor', () => onFill('farm@example.com', 'password123')),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.2)),
            _buildLink(context, 'Customer', () => onFill('customer@example.com', 'password123')),
          ],
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildLink(BuildContext context, String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryLight,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
