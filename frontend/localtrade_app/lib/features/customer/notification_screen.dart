import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Notifications', style: AppTextStyles.screenTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: AppColors.coralLight, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_outlined,
                    size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 16),
              Text('Login to view notifications',
                  style: AppTextStyles.sectionHeading),
              const SizedBox(height: 8),
              Text('Sign in to see your updates', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 20),
              AppButton(
                label: 'Login',
                onPressed: () {
                  AuthGuard.requireAuth(context, onAuthenticated: () {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final importantCount = provider.notifications
                  .where((n) =>
                      n['isRead'] != true &&
                      n['type'] != 'Promotional')
                  .length;
              final promoCount = provider.notifications
                  .where((n) =>
                      n['isRead'] != true && n['type'] == 'Promotional')
                  .length;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                decoration: BoxDecoration(
                  color: AppColors.mutedLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.ink,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(child: _buildTabLabel('Important', importantCount)),
                    Tab(child: _buildTabLabel('Promotions', promoCount)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0 || provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await provider.markAllAsRead();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('All marked as read'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.coral,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const ListSkeleton(itemCount: 5);
          }

          final important = provider.notifications
              .where((n) => n['type'] != 'Promotional')
              .toList();
          final promotions = provider.notifications
              .where((n) => n['type'] == 'Promotional')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(important, provider, false),
              _buildNotificationList(promotions, provider, true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabLabel(String label, int unreadCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (unreadCount > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$unreadCount',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationList(
    List<dynamic> notifications,
    NotificationProvider provider,
    bool isPromotional,
  ) {
    if (notifications.isEmpty) {
      return EmptyState(
        icon: isPromotional
            ? Icons.local_offer_outlined
            : Icons.notifications_off_outlined,
        title: isPromotional ? 'No promotions yet' : 'No notifications',
        message: isPromotional
            ? 'New product listings and offers from local vendors will appear here.'
            : 'You\'re all caught up. We\'ll let you know when there\'s something new.',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchNotifications,
      color: AppColors.coral,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (context, index) {
          if (isPromotional) {
            return const SizedBox.shrink();
          }
          return const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.divider,
            indent: 72,
          );
        },
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final bool isRead = notification['isRead'] ?? false;

          if (isPromotional) {
            return _buildPromoCard(notification, isRead, provider);
          }

          return _buildImportantRow(notification, isRead, provider);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Important notification row (Order, System, Account)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildImportantRow(
    dynamic notification,
    bool isRead,
    NotificationProvider provider,
  ) {
    return InkWell(
      onTap: () {
        if (!isRead) provider.markAsRead(notification['_id']);
      },
      splashColor: AppColors.coralLight,
      highlightColor: AppColors.coralLight.withValues(alpha: 0.3),
      child: Container(
        color: isRead ? null : AppColors.coralLight.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification['type']),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isRead ? FontWeight.w400 : FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isRead ? AppColors.muted : AppColors.ink,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification['createdAt']),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Promotional notification card — "Grab this offer" style
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPromoCard(
    dynamic notification,
    bool isRead,
    NotificationProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isRead) provider.markAsRead(notification['_id']);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: AppColors.coralDark,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? 'New listing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w400
                                : FontWeight.w500,
                            color: AppColors.ink,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Grab this offer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(notification['createdAt']),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNotificationIcon(String? type) {
    final Color iconBgColor = _iconColor(type);
    final Color iconFgColor = _iconForegroundColor(type);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconBgColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _icon(type),
        size: 20,
        color: iconFgColor,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return DateFormat('MMM d, h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'Order':
        return Icons.shopping_bag_outlined;
      case 'Account':
        return Icons.person_outline_rounded;
      case 'Promotional':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'Order':
        return AppColors.coral;
      case 'Account':
        return AppColors.blue;
      case 'Promotional':
        return AppColors.success;
      default:
        return AppColors.muted;
    }
  }

  Color _iconForegroundColor(String? type) {
    switch (type) {
      case 'Order':
        return AppColors.coralDark;
      case 'Account':
        return AppColors.blueDark;
      case 'Promotional':
        return AppColors.successDark;
      default:
        return AppColors.muted;
    }
  }
}
