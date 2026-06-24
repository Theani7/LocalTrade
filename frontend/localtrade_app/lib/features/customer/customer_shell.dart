import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/connection_status_banner.dart';
import 'customer_home_screen.dart';
import 'cart_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';
import 'notification_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;
  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey<CustomerHomeBodyState> _homeKey = GlobalKey<CustomerHomeBodyState>();

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _onCategoryTap(String category) {
    _switchTab(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _homeKey.currentState;
      if (state != null) {
        state.setCategory(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: _currentIndex == 0
                ? CustomerHomeBody(
                    key: _homeKey,
                    onNotificationTap: () => AuthGuard.requireAuthRoute(
                      context,
                      const NotificationScreen(),
                    ),
                    cartIconKey: _cartIconKey,
                  )
                : _currentIndex == 1
                    ? CartBody(
                        onBrowseProducts: () => _switchTab(0),
                        onCategoryTap: _onCategoryTap,
                      )
                    : _currentIndex == 2
                        ? const CustomerOrdersBody()
                        : const CustomerProfileBody(),
          ),
        ],
      ),
      bottomNavigationBar: _CustomerBottomNav(
        currentIndex: _currentIndex,
        cartItemCount: cart.itemCount,
        cartIconKey: _cartIconKey,
        onTap: (i) {
          if (i == 0) {
            _switchTab(0);
          } else if (i == 1) {
            AuthGuard.requireAuth(context, onAuthenticated: () => _switchTab(1));
          } else if (i == 2) {
            AuthGuard.requireAuth(context, onAuthenticated: () => _switchTab(2));
          } else if (i == 3) {
            AuthGuard.requireAuth(context, onAuthenticated: () => _switchTab(3));
          }
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bottom Navigation — matches vendor dot-indicator pattern
// ═════════════════════════════════════════════════════════════════════════════
class _CustomerBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;
  final GlobalKey? cartIconKey;

  const _CustomerBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
    this.cartIconKey,
  });

  @override
  State<_CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<_CustomerBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;
  int _prevCartCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCartCount = widget.cartItemCount;
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _CustomerBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cartItemCount > _prevCartCount) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion) _bounceCtrl.forward(from: 0.0);
    }
    _prevCartCount = widget.cartItemCount;
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Cart'),
    _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Orders'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, 10, 6, MediaQuery.of(context).padding.bottom + 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == widget.currentIndex;

              return GestureDetector(
                onTap: () => widget.onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 32,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (index == 1 && widget.cartItemCount > 0)
                            TickBuilder(
                              listenable: _bounceCtrl,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: _bounceScale.value,
                                  child: Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: isActive ? AppColors.coralDark : const Color(0xFFB9AF9A),
                                  ),
                                );
                              },
                            )
                          else
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 22,
                              color: isActive ? AppColors.coralDark : const Color(0xFFB9AF9A),
                            ),
                          // Cart badge
                          if (index == 1 && widget.cartItemCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                key: widget.cartIconKey,
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.coral,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.cartItemCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        color: isActive ? AppColors.coralDark : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Dot indicator
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.coralDark : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
