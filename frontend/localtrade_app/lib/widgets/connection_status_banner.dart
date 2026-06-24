import 'package:flutter/material.dart';
import '../core/services/connectivity_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: ConnectivityService().statusNotifier,
      builder: (context, status, _) {
        if (status == ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        final isConnecting = status == ConnectionStatus.connecting;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            bottom: 6,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: isConnecting ? AppColors.coralLight : AppColors.successLight,
            border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isConnecting ? Icons.wifi_find_rounded : Icons.check_circle_rounded,
                size: 14,
                color: isConnecting ? AppColors.coralDark : AppColors.successDark,
              ),
              const SizedBox(width: 6),
              Text(
                isConnecting ? 'Connecting...' : 'Connected',
                style: AppTextStyles.badge.copyWith(
                  color: isConnecting ? AppColors.coralDark : AppColors.successDark,
                  fontSize: 12,
                ),
              ),
              if (isConnecting)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.coralDark,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
