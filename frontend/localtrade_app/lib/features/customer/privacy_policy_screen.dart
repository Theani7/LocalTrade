import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy Policy', style: AppTextStyles.screenTitle),
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
            // ── Header ─────────────────────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 24),

            // ── Last Updated ───────────────────────────────────────────────
            _buildLastUpdated(),
            const SizedBox(height: 24),

            // ── Sections ───────────────────────────────────────────────────
            _buildSection(
              title: '1. Information We Collect',
              icon: Icons.folder_outlined,
              content: '''We collect the following information when you use LocalTrade:

Account Information:
- Full name, email address, and phone number
- Delivery address (flat, street, city, state, zip code)
- Profile image (if uploaded)
- Role (customer, vendor, or admin)

Order Data:
- Products ordered, quantities, and prices
- Order status and delivery history
- Shipping address and delivery notes
- Payment method (currently Cash on Delivery)

Vendor Information (for vendors only):
- Shop name and business details
- Product listings (title, images, price, stock)
- Sales and analytics data

Usage Data:
- App interaction patterns and features used
- Device type, OS version, and app version
- IP address and approximate location for delivery''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '2. How We Use Your Information',
              icon: Icons.settings_outlined,
              content: '''We use your information to:

- Process and fulfill your orders
- Communicate order status and delivery updates
- Provide customer support and resolve issues
- Improve app features and user experience
- Send important service notifications (order updates, policy changes)
- Prevent fraud and ensure platform security

For vendors:
- Display your shop and products to customers
- Process orders and manage inventory
- Provide sales analytics and insights''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '3. Information Sharing',
              icon: Icons.group_outlined,
              content: '''We do NOT sell your personal information. We share data only:

With Vendors:
- Your name and delivery address (for order fulfillment)
- Order details (products, quantities, delivery notes)

With Service Providers:
- Cloud hosting providers (for secure data storage)
- Image hosting (Cloudinary, for product images)

Legal Requirements:
- When required by law or legal process
- To protect our rights, safety, or property
- In connection with a business transfer or merger''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '4. Data Security',
              icon: Icons.security_outlined,
              content: '''We implement industry-standard security measures:

- Encrypted data transmission (HTTPS/TLS)
- Secure password hashing (bcrypt)
- JWT-based authentication with token expiration
- Regular security audits and updates
- Role-based access control

While we strive to protect your data, no method of electronic storage is 100% secure. We cannot guarantee absolute security.''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '5. Data Retention',
              icon: Icons.calendar_today_outlined,
              content: '''We retain your information for as long as your account is active or as needed to provide services:

- Account data: Retained until account deletion
- Order history: Retained for 2 years for reference
- Usage data: Retained for 1 year for analytics
- Support communications: Retained for 1 year

You may request data deletion at any time by contacting support.''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '6. Your Rights',
              icon: Icons.how_to_reg_outlined,
              content: '''You have the right to:

- Access your personal data
- Correct inaccurate information
- Delete your account and data
- Opt out of non-essential communications
- Export your order history

To exercise these rights, contact our support team at support@localtrade.com''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '7. Cookies and Tracking',
              icon: Icons.cookie_outlined,
              content: '''We use minimal tracking:

- Authentication tokens (JWT) for session management
- Local storage for app preferences and cart data
- No third-party advertising trackers
- No cross-app tracking or behavioral advertising''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '8. Children\'s Privacy',
              icon: Icons.child_care_outlined,
              content: '''LocalTrade is not intended for children under 13. We do not knowingly collect data from children. If we discover we have collected data from a child, we will delete it immediately.''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '9. Changes to This Policy',
              icon: Icons.update_outlined,
              content: '''We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or via email. Continued use of LocalTrade after changes constitutes acceptance of the updated policy.''',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '10. Contact Us',
              icon: Icons.mail_outline_rounded,
              content: '''For questions about this Privacy Policy or your data:

Email: support@localtrade.com

We respond to all privacy-related inquiries within 48 hours.''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
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
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Privacy Matters',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'How we collect, use, and protect your data',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.blueDark.withValues(alpha: 0.7),
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

  // ── Last Updated ──────────────────────────────────────────────────────────
  Widget _buildLastUpdated() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(
            'Last updated: January 1, 2025',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.coralDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodyMuted.copyWith(height: 1.6, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
