import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_animations.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;
  final GlobalKey? cartIconKey;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
    this.cartIconKey,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
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
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = index == widget.currentIndex;

          return GestureDetector(
            onTap: () => widget.onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.coralLight : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isActive ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: 44,
                      height: 28,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Cart icon with bounce
                          if (index == 1 && widget.cartItemCount > 0)
                            TickBuilder(
                              listenable: _bounceCtrl,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: _bounceScale.value,
                                  child: Icon(
                                    isActive
                                        ? item.activeIcon
                                        : item.icon,
                                    size: 26,
                                    color: isActive
                                        ? AppColors.coralDark
                                        : AppColors.muted,
                                  ),
                                );
                              },
                            )
                          else
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 26,
                              color: isActive
                                  ? AppColors.coralDark
                                  : AppColors.muted,
                            ),
                          // Cart badge
                          if (index == 1 && widget.cartItemCount > 0)
                            Positioned(
                              right: -2,
                              top: -4,
                              child: Container(
                                key: widget.cartIconKey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: AppColors.coral,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Text(
                                  '${widget.cartItemCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w500 : FontWeight.w400,
                      color: isActive
                          ? AppColors.coralDark
                          : AppColors.muted,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
