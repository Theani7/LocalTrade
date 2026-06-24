import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/update_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  final bool fromManualCheck;

  const UpdateDialog({
    super.key,
    required this.info,
    this.fromManualCheck = false,
  });

  static void show(BuildContext context, UpdateInfo info, {bool fromManualCheck = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info, fromManualCheck: fromManualCheck),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: info.hasUpdate ? AppColors.coralLight : AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                info.hasUpdate ? Icons.system_update_rounded : Icons.check_circle_outline_rounded,
                size: 28,
                color: info.hasUpdate ? AppColors.coralDark : AppColors.blueDark,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              info.hasUpdate ? 'Update available' : 'App is up to date',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Version info
            Text(
              fromManualCheck && !info.hasUpdate
                  ? 'You are on the latest version (v${info.currentVersion}).'
                  : info.hasUpdate
                      ? 'v${info.currentVersion} \u2192 v${info.latestVersion}'
                      : 'Version v${info.currentVersion}',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (info.hasUpdate && info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),

              // Release notes
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: AppTextStyles.caption.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Buttons
            if (info.hasUpdate)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(info.downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Update now', style: AppTextStyles.buttonPrimary),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  info.hasUpdate ? 'Later' : 'Close',
                  style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
