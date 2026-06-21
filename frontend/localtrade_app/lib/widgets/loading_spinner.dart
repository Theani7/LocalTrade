import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final String? message;

  const LoadingSpinner({
    super.key,
    this.size = 32,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.coral,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
