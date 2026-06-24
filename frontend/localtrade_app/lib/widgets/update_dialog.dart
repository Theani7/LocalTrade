import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../core/services/update_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class UpdateDialog extends StatefulWidget {
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
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _downloadPath;
  String? _error;

  UpdateService get _service => UpdateService();

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      final path = await _service.downloadApk(
        url: widget.info.downloadUrl,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = total > 0 ? received / total : 0;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadPath = path;
        _isDownloading = false;
        _downloadProgress = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Download failed: $e';
        _isDownloading = false;
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadPath == null) return;
    final result = await OpenFilex.open(
      _downloadPath!,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _error != null
                    ? AppColors.dangerLight
                    : _isDownloading
                        ? AppColors.blueLight
                        : _downloadPath != null
                            ? Colors.green.shade50
                            : widget.info.hasUpdate
                                ? AppColors.coralLight
                                : AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _error != null
                    ? Icons.error_outline_rounded
                    : _isDownloading
                        ? Icons.download_rounded
                        : _downloadPath != null
                            ? Icons.check_circle_outline_rounded
                            : widget.info.hasUpdate
                                ? Icons.system_update_rounded
                                : Icons.check_circle_outline_rounded,
                size: 28,
                color: _error != null
                    ? AppColors.danger
                    : _isDownloading
                        ? AppColors.blueDark
                        : _downloadPath != null
                            ? Colors.green
                            : widget.info.hasUpdate
                                ? AppColors.coralDark
                                : AppColors.blueDark,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _error != null
                  ? 'Download failed'
                  : _isDownloading
                      ? 'Downloading...'
                      : _downloadPath != null
                          ? 'Download complete'
                          : widget.info.hasUpdate
                              ? 'Update available'
                              : 'App is up to date',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Version info
            if (!_isDownloading && _downloadPath == null && _error == null)
              Text(
                widget.info.hasUpdate
                    ? 'v${widget.info.currentVersion} \u2192 v${widget.info.latestVersion}'
                    : widget.fromManualCheck && !widget.info.hasUpdate
                        ? 'You are on the latest version (v${widget.info.currentVersion}).'
                        : 'Version v${widget.info.currentVersion}',
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),

            // Download progress
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: AppColors.coralLight,
                color: AppColors.coral,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            // Release notes (only before download starts)
            if (widget.info.hasUpdate && !_isDownloading && _downloadPath == null && _error == null && widget.info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                    widget.info.releaseNotes,
                    style: AppTextStyles.caption.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Buttons
            if (_isDownloading)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.muted.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Downloading...', style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.muted)),
                ),
              )
            else if (_downloadPath != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _installApk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Install update', style: AppTextStyles.buttonPrimary),
                ),
              )
            else if (_error != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Retry', style: AppTextStyles.buttonPrimary),
                ),
              )
            else if (widget.info.hasUpdate)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Download & install', style: AppTextStyles.buttonPrimary),
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
                  _isDownloading ? 'Background' : (_downloadPath != null ? 'Close' : (widget.info.hasUpdate ? 'Later' : 'Close')),
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
