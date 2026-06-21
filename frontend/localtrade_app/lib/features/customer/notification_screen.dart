import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
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

          if (provider.notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message: 'You\'re all caught up. We\'ll let you know when there\'s something new.',
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
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.divider,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                final bool isRead = notification['isRead'] ?? false;

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
                                      isRead ? FontWeight.w400 : FontWeight.w600,
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
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
              },
            ),
          );
        },
      ),
    );
  }

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
      default:
        return AppColors.muted;
    }
  }
}
