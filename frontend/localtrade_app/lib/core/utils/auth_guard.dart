import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';

class AuthGuard {
  static bool isAuthenticated(BuildContext context) {
    return Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
  }

  /// If authenticated, calls [onAuthenticated] immediately.
  /// Otherwise shows a bottom-sheet login prompt. After successful login,
  /// calls [onAuthenticated] (user stays where they are).
  static void requireAuth(BuildContext context, {required VoidCallback onAuthenticated}) {
    if (isAuthenticated(context)) {
      onAuthenticated();
      return;
    }
    _showLoginPrompt(context, onAuthenticated);
  }

  /// If authenticated, pushes [destination]. Otherwise shows login prompt,
  /// then pushes [destination] after successful login.
  static void requireAuthRoute(BuildContext context, Widget destination) {
    if (isAuthenticated(context)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      return;
    }
    _showLoginPrompt(context, () {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      }
    });
  }

  static void _showLoginPrompt(BuildContext context, VoidCallback onLoginSuccess) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login required',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.muted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.muted,
                        ),
                        onPressed: () => setModalState(() => isPasswordVisible = !isPasswordVisible),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Login',
                    isLoading: isLoading,
                    onPressed: () async {
                      if (emailController.text.trim().isEmpty ||
                          passwordController.text.isEmpty) {
                        setModalState(() => error = 'Please fill in all fields');
                        return;
                      }
                      setModalState(() {
                        isLoading = true;
                        error = null;
                      });
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final success = await auth.login(
                        emailController.text.trim(),
                        passwordController.text,
                      );
                      if (!context.mounted) return;
                      if (success) {
                        Navigator.pop(context);
                        onLoginSuccess();
                      } else {
                        setModalState(() {
                          isLoading = false;
                          error = auth.error ?? 'Login failed';
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
