import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/app_button.dart';
import 'customer_orders_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();

    // Animated checkmark: scale in with spring bounce
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );

    // Confetti burst
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 2));

    // Start animations sequentially
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _checkCtrl.forward();
        _confettiCtrl.play();
      }
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.coral,
                AppColors.coralLight,
                AppColors.success,
                AppColors.blue,
                AppColors.warning,
              ],
              numberOfParticles: 30,
              gravity: 0.1,
              emissionFrequency: 0.05,
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark circle
                  if (reduceMotion)
                    _buildCheckCircle()
                  else
                    TickBuilder(
                      listenable: _checkCtrl,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _checkScale.value,
                          child: Opacity(
                            opacity: _checkScale.value.clamp(0.0, 1.0),
                            child: _buildCheckCircle(),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Order placed',
                    style: AppTextStyles.screenTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order has been placed successfully. The vendor will confirm shortly.',
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    label: 'View orders',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        SlideFadePageRoute(
                          builder: (_) => const CustomerOrdersScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Continue shopping',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCircle() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 52,
        color: AppColors.successDark,
      ),
    );
  }
}
