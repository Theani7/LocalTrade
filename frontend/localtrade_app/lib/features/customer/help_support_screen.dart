import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'support@localtrade.com',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Help and Support', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingTop,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact Card ───────────────────────────────────────────────
            _buildContactCard(context),
            const SizedBox(height: 24),

            // ── FAQs ───────────────────────────────────────────────────────
            _buildSectionLabel('Frequently Asked Questions'),
            const SizedBox(height: 10),
            _buildFaqSection(),
            const SizedBox(height: 24),

            // ── Quick Links ────────────────────────────────────────────────
            _buildSectionLabel('Quick Links'),
            const SizedBox(height: 10),
            _buildQuickLinks(context),
            const SizedBox(height: 24),

            // ── App Info ───────────────────────────────────────────────────
            _buildAppInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Contact Card ────────────────────────────────────────────────────────────
  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_outlined, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need help?',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Our support team is here for you',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.coralDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.coral, height: 1),
          const SizedBox(height: 14),
          // Email
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(_emailUri)) {
                await launchUrl(_emailUri);
              }
            },
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email_outlined, size: 18, color: AppColors.coralDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Us', style: AppTextStyles.label),
                      const SizedBox(height: 2),
                      Text(
                        'support@localtrade.com',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.coralDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Response time
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule_outlined, size: 18, color: AppColors.coralDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Response Time', style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(
                      'We reply within 24 hours',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.coralDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FAQs ───────────────────────────────────────────────────────────────────
  Widget _buildFaqSection() {
    final faqs = [
      _FaqItem(
        question: 'How do I track my order?',
        answer:
            'Go to My Orders from your profile. Tap on any order to see its real-time status, estimated delivery time, and full tracking details.',
      ),
      _FaqItem(
        question: 'How do I cancel an order?',
        answer:
            'Open the order from My Orders. If the order is still Pending, you will see a Cancel Order button at the bottom. Note: orders can only be cancelled before they are confirmed by the vendor.',
      ),
      _FaqItem(
        question: 'How do I become a vendor?',
        answer:
            'Register a new account and select "Vendor" as your role. Your account will be reviewed by our admin team. Once approved, you can start listing products.',
      ),
      _FaqItem(
        question: 'How do I reset my password?',
        answer:
            'On the login screen, tap "Forgot Password?" and enter your registered email. You will receive a password reset link within a few minutes.',
      ),
      _FaqItem(
        question: 'What payment methods are accepted?',
        answer:
            'We currently support Cash on Delivery (COD). Online payment options will be available soon.',
      ),
      _FaqItem(
        question: 'How do I update my delivery address?',
        answer:
            'Go to My Account > Delivery Address. You can edit your address at any time. Changes will apply to future orders.',
      ),
      _FaqItem(
        question: 'What if my product arrives damaged?',
        answer:
            'Contact our support team immediately with your order ID and photos of the damage. We will arrange a replacement or full refund.',
      ),
      _FaqItem(
        question: 'Is my personal data safe?',
        answer:
            'Yes. We use industry-standard encryption and never sell your data to third parties. Read our Privacy Policy for full details.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(faqs.length, (index) {
          final faq = faqs[index];
          return _buildFaqTile(faq, index < faqs.length - 1);
        }),
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq, bool showDivider) {
    return Builder(
      builder: (context) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.question_answer_outlined, size: 16, color: AppColors.blueDark),
        ),
        title: Text(
          faq.question,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
        ),
        iconColor: AppColors.muted,
        collapsedIconColor: AppColors.muted,
        children: [
          Text(
            faq.answer,
            style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Quick Links ────────────────────────────────────────────────────────────
  Widget _buildQuickLinks(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLinkTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Problem',
            subtitle: 'Found a bug? Let us know',
            iconBg: AppColors.warningLight,
            iconColor: AppColors.warningDark,
            onTap: () async {
              final Uri mailto = Uri(
                scheme: 'mailto',
                path: 'support@localtrade.com',
                query: 'subject=Bug Report - LocalTrade App',
              );
              if (await canLaunchUrl(mailto)) {
                await launchUrl(mailto);
              }
            },
          ),
          const Divider(height: 1, indent: 52),
          _buildLinkTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate the App',
            subtitle: 'Share your feedback on the store',
            iconBg: AppColors.coralLight,
            iconColor: AppColors.coralDark,
            onTap: () async {
              final Uri playStore = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.localtrade.app',
              );
              if (await canLaunchUrl(playStore)) {
                await launchUrl(playStore, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const Divider(height: 1, indent: 52),
          _buildLinkTile(
            icon: Icons.share_outlined,
            title: 'Share LocalTrade',
            subtitle: 'Invite friends and vendors',
            iconBg: AppColors.successLight,
            iconColor: AppColors.successDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // ── App Info ───────────────────────────────────────────────────────────────
  Widget _buildAppInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, size: 24, color: AppColors.coral),
          ),
          const SizedBox(height: 10),
          Text('LocalTrade', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(
            'Supporting local vendors in your community',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(letterSpacing: 0.5),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
