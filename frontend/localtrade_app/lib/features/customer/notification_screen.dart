import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
import 'order_tracking_screen.dart';
import 'product_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTab = 0; // 0 = Important, 1 = Promotions

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthGuard.isAuthenticated(context)) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated(context)) {
      return _buildUnauthenticatedView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
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

          final currentList = _selectedTab == 0 ? important : promotions;
          final unread = currentList.where((n) => n['isRead'] != true).toList();
          final read = currentList.where((n) => n['isRead'] == true).toList();

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            color: AppColors.coral,
            backgroundColor: AppColors.surface,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification.metrics.pixels >=
                      scrollNotification.metrics.maxScrollExtent - 200 &&
                      provider.hasMore &&
                      !provider.isFetchingMore) {
                    provider.loadMoreNotifications();
                  }
                  return false;
                },
                child: _buildNotificationList(important, promotions, unread, read, provider),
              ),
          );
        },
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      title: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final unreadCount = provider.unreadCount;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Notifications', style: AppTextStyles.screenTitle),
              if (unreadCount > 0)
                Text(
                  '$unreadCount unread',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
            ],
          );
        },
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
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.coralDark,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Segmented Control ─────────────────────────────────────────
  Widget _buildSegmentedControl(
      List<dynamic> important, List<dynamic> promotions) {
    final importantUnread =
        important.where((n) => n['isRead'] != true).length;
    final promoUnread =
        promotions.where((n) => n['isRead'] != true).length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mutedLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentTab(
              label: 'Important',
              unreadCount: importantUnread,
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildSegmentTab(
              label: 'Promotions',
              unreadCount: promoUnread,
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required int unreadCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.muted,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.coralLight
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.coralDark
                        : AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Notification Card (unified for both read/unread) ──────────
  Widget _buildNotificationCard(
    dynamic notification,
    bool isRead,
    NotificationProvider provider,
  ) {
    final type = notification['type'] as String? ?? 'System';
    final border = _typeBorderColor(type, isRead);
    final action = _getActionInfo(notification);

    return GestureDetector(
      onTap: () {
        if (!isRead) provider.markAsRead(notification['_id']);
        if (action != null) _handleActionTap(action);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: border != null
              ? Border(
                  left: BorderSide(color: border, width: 3),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: isRead ? 0.03 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: isRead ? 0.7 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildTypeIcon(type, isRead),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + timestamp row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: isRead
                                  ? AppColors.muted
                                  : AppColors.ink,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRelativeTime(notification['createdAt']),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Message
                    Text(
                      notification['message'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isRead
                            ? AppColors.muted
                            : AppColors.muted,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Action chip
                    if (action != null) ...[
                      const SizedBox(height: 10),
                      _buildActionChip(action),
                    ],
                  ],
                ),
              ),
              // Unread dot
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type Icon ─────────────────────────────────────────────────
  Widget _buildTypeIcon(String type, bool isRead) {
    final config = _iconConfig(type);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.mutedLight
            : config.bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        size: 18,
        color: isRead
            ? AppColors.muted
            : config.iconColor,
      ),
    );
  }

  _IconConfig _iconConfig(String type) {
    switch (type) {
      case 'Order':
        return _IconConfig(
          icon: Icons.shopping_bag_outlined,
          bgColor: AppColors.coralLight,
          iconColor: AppColors.coralDark,
        );
      case 'Account':
        return _IconConfig(
          icon: Icons.check_circle_outline_rounded,
          bgColor: AppColors.blueLight,
          iconColor: AppColors.blueDark,
        );
      case 'System':
        return _IconConfig(
          icon: Icons.info_outline_rounded,
          bgColor: AppColors.blueLight,
          iconColor: AppColors.blueDark,
        );
      case 'Promotional':
        return _IconConfig(
          icon: Icons.notifications_outlined,
          bgColor: AppColors.mutedLight,
          iconColor: AppColors.muted,
        );
      default:
        return _IconConfig(
          icon: Icons.notifications_outlined,
          bgColor: AppColors.mutedLight,
          iconColor: AppColors.muted,
        );
    }
  }

  // ── Left border color by notification purpose ─────────────────
  Color? _typeBorderColor(String type, bool isRead) {
    if (isRead) return null;

    switch (type) {
      case 'Order':
        return AppColors.coral;
      case 'Account':
        return AppColors.success;
      case 'System':
        return AppColors.blue;
      case 'Promotional':
        return null;
      default:
        return null;
    }
  }

  // ── Action chip ──────────────────────────────────────────────
  Widget _buildActionChip(_ActionInfo action) {
    return GestureDetector(
      onTap: () => _handleActionTap(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.coralLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.coralDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.coralDark,
            ),
          ],
        ),
      ),
    );
  }

  void _handleActionTap(_ActionInfo action) {
    if (action.orderId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: action.orderId!),
        ),
      );
    } else if (action.productId != null) {
      _navigateToProduct(action.productId!);
    }
  }

  void _navigateToProduct(String productId) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.products.firstWhere(
      (p) => p['_id'] == productId,
      orElse: () => null,
    );
    if (product != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    }
  }

  // ── Action info from notification data ───────────────────────
  _ActionInfo? _getActionInfo(dynamic notification) {
    final data = notification['data'];
    if (data == null) return null;

    final type = notification['type'] as String? ?? '';
    final orderId = data is Map ? data['orderId'] : null;
    final vendorId = data is Map ? data['vendorId'] : null;
    final productId = data is Map ? data['productId'] : null;

    if (type == 'Order' && orderId != null) {
      return _ActionInfo(label: 'View order', orderId: orderId);
    }
    if (type == 'Promotional' && productId != null) {
      return _ActionInfo(label: 'View product', productId: productId);
    }
    if (type == 'Account' && vendorId != null) {
      return _ActionInfo(label: 'Review vendor', vendorId: vendorId);
    }
    return null;
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isPromotions = _selectedTab == 1;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: EmptyState(
        icon: isPromotions
            ? Icons.local_offer_outlined
            : Icons.notifications_off_outlined,
        title: isPromotions ? 'No promotions yet' : 'No notifications',
        message: isPromotions
            ? 'New product listings and offers from local vendors will appear here.'
            : 'You\'re all caught up. We\'ll let you know when there\'s something new.',
      ),
    );
  }

  // ── Unauthenticated View ─────────────────────────────────────
  Widget _buildUnauthenticatedView() {
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

  // ── Notification list ──────────────────────────────────────────
  Widget _buildNotificationList(
    List<dynamic> important,
    List<dynamic> promotions,
    List<dynamic> unread,
    List<dynamic> read,
    NotificationProvider provider,
  ) {
    final items = <Widget>[];
    items.add(const SizedBox(height: 8));
    items.add(_buildSegmentedControl(important, promotions));
    items.add(const SizedBox(height: 20));
    if (unread.isNotEmpty) {
      items.add(_buildSectionLabel('Unread'));
      items.add(const SizedBox(height: 8));
      items.addAll(unread.map((n) => _buildNotificationCard(n, false, provider)));
      items.add(const SizedBox(height: 16));
    }
    if (read.isNotEmpty) {
      items.add(_buildSectionLabel('Earlier'));
      items.add(const SizedBox(height: 8));
      items.addAll(read.map((n) => _buildNotificationCard(n, true, provider)));
    }
    if (unread.isEmpty && read.isEmpty) {
      items.add(_buildEmptyState());
    }
    if (provider.hasMore) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral)),
        ),
      ));
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _formatRelativeTime(String? dateStr) {
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

      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }
}

// ── Helper classes ─────────────────────────────────────────────
class _IconConfig {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _IconConfig({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class _ActionInfo {
  final String label;
  final String? orderId;
  final String? vendorId;
  final String? productId;

  const _ActionInfo({
    required this.label,
    this.orderId,
    this.vendorId,
    this.productId,
  });
}
