import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum SectionTone { warm, practical, neutral }

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final SectionTone tone;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone = SectionTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: _titleColor(),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }

  Color _titleColor() {
    switch (tone) {
      case SectionTone.warm:
        return AppColors.ink;
      case SectionTone.practical:
        return AppColors.ink;
      case SectionTone.neutral:
        return AppColors.ink;
    }
  }
}
