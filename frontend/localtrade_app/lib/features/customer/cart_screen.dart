import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/cloudinary_helper.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/app_animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/skeleton_loaders.dart';
import 'checkout_screen.dart';

final _priceFormat = NumberFormat('#,##0');

String _toSentenceCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

String _vendorInitials(String name) {
  if (name.isEmpty) return '?';
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

// ═════════════════════════════════════════════════════════════════════════════
// CartScreen — full-screen push route
// ═════════════════════════════════════════════════════════════════════════════
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Cart', style: AppTextStyles.screenTitle),
      ),
      body: CartBody(
        onBrowseProducts: () => Navigator.pop(context),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CartBody — reusable content widget (used by CustomerShell)
// ═════════════════════════════════════════════════════════════════════════════
class CartBody extends StatefulWidget {
  final VoidCallback? onBrowseProducts;
  final ValueChanged<String>? onCategoryTap;

  const CartBody({
    super.key,
    this.onBrowseProducts,
    this.onCategoryTap,
  });

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AuthGuard.isAuthenticated(context);

    if (!isAuth) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: AppColors.coralDark,
              ),
            ),
            const SizedBox(height: 16),
            Text('Login to view your cart', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(
              'Sign in to add items and checkout',
              style: AppTextStyles.bodyMuted,
            ),
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
      );
    }

    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();
    final totalQty = cartItems.fold<int>(0, (s, i) => s + (i.quantity > 0 ? i.quantity : 0));

    if (cartItems.isEmpty) {
      return _EmptyCartBody(
        onBrowseProducts: widget.onBrowseProducts,
        onCategoryTap: widget.onCategoryTap,
      );
    }

    return Column(
      children: [
        // Cart header with count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cart', style: AppTextStyles.screenTitle),
                    const SizedBox(height: 2),
                    Text(
                      '$totalQty item${totalQty == 1 ? '' : 's'} in your cart',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              ...cart.itemsByVendor.entries.map((entry) {
                final rawName = entry.value.first.vendorName;
                final vendorName =
                    rawName.isNotEmpty ? rawName : 'Local vendor';
                final vendorItems = entry.value;
                return _VendorGroupCard(
                  vendorName: vendorName,
                  items: vendorItems,
                  cart: cart,
                );
              }),
              const SizedBox(height: 12),
              _VendorNoteCard(noteController: _noteController),
              const SizedBox(height: 100),
            ],
          ),
        ),
        _buildBottomBar(context, cart),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final cartItems = cart.items.values.toList();
    final totalQty = cartItems.fold<int>(0, (s, i) => s + i.quantity);
    final subtotal = cart.totalAmount;
    const deliveryFee = 0.0;
    final total = subtotal + deliveryFee;

    return FadeSlideIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Subtotal ($totalQty item${totalQty == 1 ? '' : 's'})',
                      style: AppTextStyles.bodyMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Rs. ${_priceFormat.format(subtotal.toInt())}',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery', style: AppTextStyles.bodyMuted),
                  Text(
                    deliveryFee == 0
                        ? 'Free'
                        : 'Rs. ${_priceFormat.format(deliveryFee.toInt())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          deliveryFee == 0 ? FontWeight.w500 : FontWeight.w400,
                      color:
                          deliveryFee == 0 ? AppColors.success : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.divider, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.cardTitle),
                  Text(
                    'Rs. ${_priceFormat.format(total.toInt())}',
                    style: AppTextStyles.price,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Checkout',
                onPressed: () => Navigator.push(
                  context,
                  SlideFadePageRoute(builder: (_) => const CheckoutScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vendor group card
// ---------------------------------------------------------------------------
class _VendorGroupCard extends StatelessWidget {
  final String vendorName;
  final List<CartItem> items;
  final CartProvider cart;

  const _VendorGroupCard({
    required this.vendorName,
    required this.items,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2B2620),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.coralLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _vendorInitials(vendorName),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coralDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendorName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text('Pickup from vendor', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          ...items.map(
            (item) => _CartItemTile(
              key: ValueKey(item.id),
              item: item,
              cart: cart,
                      onRemove: () => cart.removeItem(item.id, size: item.size),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart item tile — animated quantity + animated removal
// ---------------------------------------------------------------------------
class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final CartProvider cart;
  final VoidCallback onRemove;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.cart,
    required this.onRemove,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _removeCtrl;
  late final Animation<double> _removeSlide;
  late final Animation<double> _removeSize;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _removeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _removeSlide = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _removeCtrl, curve: Curves.easeInOut),
    );
    _removeSize = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _removeCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _removeCtrl.dispose();
    super.dispose();
  }

  void _handleRemove() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      widget.onRemove();
      return;
    }
    setState(() => _isRemoving = true);
    _removeCtrl.forward().then((_) => widget.onRemove());
  }

  @override
  Widget build(BuildContext context) {
    if (_isRemoving) {
      return TickBuilder(
        listenable: _removeCtrl,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(_removeSlide.value * 100, 0),
            child: SizeTransition(
              sizeFactor: _removeSize,
              child: Opacity(
                opacity: 1.0 - _removeSlide.value,
                child: _buildContent(),
              ),
            ),
          );
        },
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: widget.item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: CloudinaryHelper.getOptimizedUrl(
                        widget.item.imageUrl,
                        width: 200,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ShimmerSkeleton(height: 64, width: 64, radius: 8),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.divider,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.muted,
                          size: 24,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.divider,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.muted,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _toSentenceCase(widget.item.title),
                        style:
                            AppTextStyles.cardTitle.copyWith(height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuantityStepper(
                      quantity: widget.item.quantity,
                      onIncrement: () => widget.cart.updateQuantity(
                          widget.item.id, widget.item.quantity + 1, size: widget.item.size),
                      onDecrement: () {
                        if (widget.item.quantity > 1) {
                          widget.cart.updateQuantity(
                              widget.item.id, widget.item.quantity - 1, size: widget.item.size);
                        } else {
                          _handleRemove();
                        }
                      },
                    ),
                    Text(
                      'Rs. ${_priceFormat.format((widget.item.price * widget.item.quantity).toInt())}',
                      style: AppTextStyles.cardTitle,
                    ),
                    if (widget.item.priceUnitLabel.isNotEmpty)
                      Text(
                        ' (${widget.item.quantity.toInt()} ${widget.item.priceUnitLabel})',
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated quantity stepper — number slides up/down with AnimatedSwitcher
// ---------------------------------------------------------------------------
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                quantity > 1
                    ? Icons.remove_rounded
                    : Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.coralDark,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) {
                final prevQty = (child.key as ValueKey<int>?)?.value ?? 0;
                final isNewGreater = quantity > prevQty;
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: isNewGreater
                          ? const Offset(0, 0.5)
                          : const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.coralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vendor note card
// ---------------------------------------------------------------------------
class _VendorNoteCard extends StatelessWidget {
  final TextEditingController noteController;

  const _VendorNoteCard({required this.noteController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2B2620),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note for vendor', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText:
                  'e.g. ripeness preference, allergies, special request',
              hintStyle: AppTextStyles.caption,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty cart body — illustration card, heading, CTA, category suggestions
// ---------------------------------------------------------------------------
class _EmptyCartBody extends StatelessWidget {
  final VoidCallback? onBrowseProducts;
  final ValueChanged<String>? onCategoryTap;

  const _EmptyCartBody({this.onBrowseProducts, this.onCategoryTap});

  static const _categoryIcons = {
    'Vegetables': '🥬',
    'Dairy': '🥛',
    'Handicrafts': '🎨',
    'Clothing': '👕',
    'Local Goods': '🌾',
    'Tailoring': '✂️',
    'Groceries': '🧺',
    'Bakery': '🍞',
    'Meat': '🥩',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Illustration card ──
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // White card
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x142B2620),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: AppColors.muted,
                    ),
                  ),
                  // Top-right chip: "0 items"
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '0 items',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.coralDark,
                        ),
                      ),
                    ),
                  ),
                  // Bottom-left chip: "Rs. 0"
                  Positioned(
                    left: -10,
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Rs. 0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Heading ──
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Subtext ──
            const Text(
              'Browse local vendors and add products you love',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── Primary CTA ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBrowseProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Browse products',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Category suggestions ──
            const Text(
              'Popular categories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: Provider.of<CategoryProvider>(context).categoryNames.take(6).map((name) {
                return GestureDetector(
                  onTap: () => onCategoryTap?.call(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D2B2620),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryIcons[name] ?? '📦',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
