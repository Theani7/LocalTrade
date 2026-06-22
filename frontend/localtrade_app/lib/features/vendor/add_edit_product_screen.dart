import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AddEditProductScreen extends StatefulWidget {
  final dynamic product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;

  int _stockQuantity = 0;
  bool _availableForPickup = true;

  String _selectedCategory = 'Vegetables';
  final List<String> _categories = [
    'Vegetables',
    'Dairy',
    'Handicrafts',
    'Clothing',
    'Local Goods',
    'Tailoring',
    'Others',
  ];

  final List<dynamic> _selectedImages = [];
  final List<Uint8List?> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.product?['title'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.product?['description'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?['price']?.toString() ?? '',
    );
    _originalPriceController = TextEditingController(
      text: widget.product?['originalPrice']?.toString() ?? '',
    );

    if (widget.product != null) {
      _selectedCategory = widget.product['category'] ?? 'Vegetables';
      _stockQuantity = widget.product['stock'] ?? 0;
      _availableForPickup = widget.product['availableForPickup'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        _imageBytes.add(bytes);
      }
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _imageBytes.length) {
        _imageBytes.removeAt(index);
      }
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.product == null && _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final productData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': _priceController.text,
        'originalPrice': _originalPriceController.text.isEmpty
            ? null
            : _originalPriceController.text,
        'stock': _stockQuantity.toString(),
        'category': _selectedCategory,
        'availableForPickup': _availableForPickup,
      };

      bool success;
      if (widget.product == null) {
        success = await productProvider.addProduct(productData, _selectedImages);
      } else {
        success = await productProvider.updateProduct(
          widget.product['_id'],
          productData,
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product listed' : 'Product updated',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Action failed'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product == null ? 'Add product' : 'Edit product',
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: 2),
            Text(
              'Fill in the details below',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 28),

                    // ── Basic info ───────────────────────────────
                    _buildSectionLabel('BASIC INFO'),
                    const SizedBox(height: 10),
                    _buildBasicInfoCard(),
                    const SizedBox(height: 28),

                    // ── Pricing ──────────────────────────────────
                    _buildSectionLabel('PRICING'),
                    const SizedBox(height: 10),
                    _buildPricingCard(),
                    const SizedBox(height: 28),

                    // ── Stock ────────────────────────────────────
                    _buildSectionLabel('STOCK'),
                    const SizedBox(height: 10),
                    _buildStockCard(),
                    const SizedBox(height: 28),

                    // ── Tip banner ───────────────────────────────
                    _buildTipBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom bar ───────────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section label — uppercase muted text above white cards
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: AppColors.muted,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Image upload — 4-slot row with cover + additional slots
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Product photos',
              style: AppTextStyles.label.copyWith(
                color: AppColors.coralDark,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Required',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              // Cover slot — larger, coral-light circle
              GestureDetector(
                onTap: _pickImages,
                child: _buildCoverSlot(),
              ),
              const SizedBox(width: 10),
              // Additional slots — smaller
              ...List.generate(3, (index) {
                final imgIndex = index;
                if (imgIndex < _selectedImages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildFilledSlot(imgIndex),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildAdditionalSlot(index),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'First photo will be the cover image',
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCoverSlot() {
    if (_selectedImages.isNotEmpty) {
      return Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: _imageBytes.isNotEmpty && _imageBytes[0] != null
                  ? Image.memory(_imageBytes[0]!, fit: BoxFit.cover)
                  : Image.network(
                      _selectedImages[0].path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              onTap: () => _removeImage(0),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.coralDark.withValues(alpha: 0.25),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 22,
            color: AppColors.coralDark,
          ),
          SizedBox(height: 6),
          Text(
            'Add photo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.coralDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSlot(int index) {
    if (index < _selectedImages.length) {
      return _buildFilledSlot(index);
    }
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 60,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 20,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildFilledSlot(int index) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: index < _imageBytes.length && _imageBytes[index] != null
                ? Image.memory(_imageBytes[index]!, fit: BoxFit.cover)
                : Image.network(
                    _selectedImages[index].path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Basic info card — title, category, description
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFieldRow(
            label: 'Product name',
            required: true,
            child: TextFormField(
              controller: _titleController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'e.g. Fresh tomatoes',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
          const _HairlineDivider(),
          _buildFieldRow(
            label: 'Category',
            required: true,
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.surface,
              style: AppTextStyles.body,
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
          const _HairlineDivider(),
          _buildFieldRow(
            label: 'Description',
            required: false,
            child: TextFormField(
              controller: _descController,
              maxLines: 3,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'What makes this product special?',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pricing card — selling price, original price
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPricingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFieldRow(
            label: 'Selling price',
            required: true,
            prefix: 'Rs.',
            child: TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
          const _HairlineDivider(),
          _buildFieldRow(
            label: 'Original price (MRP)',
            required: false,
            prefix: 'Rs.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _originalPriceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                Text(
                  'Shows a strikethrough on the listing',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Stock card — quantity stepper, pickup toggle
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStockCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFieldRow(
            label: 'Stock quantity',
            required: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _stepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_stockQuantity > 0) {
                      setState(() => _stockQuantity--);
                    }
                  },
                ),
                SizedBox(
                  width: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) {
                      final prevVal =
                          (child.key as ValueKey<int>?)?.value ?? 0;
                      final isNewGreater = _stockQuantity > prevVal;
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: isNewGreater
                                ? const Offset(0, 0.4)
                                : const Offset(0, -0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '$_stockQuantity',
                      key: ValueKey(_stockQuantity),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add_rounded,
                  onTap: () => setState(() => _stockQuantity++),
                ),
              ],
            ),
          ),
          const _HairlineDivider(),
          _buildFieldRow(
            label: 'Available for pickup',
            required: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Customers can collect from you.',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 10),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _availableForPickup,
                    onChanged: (v) => setState(() => _availableForPickup = v),
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppColors.coral,
                    inactiveTrackColor: AppColors.divider,
                    inactiveThumbColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.coralLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.coralDark),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tip banner — coral-light with bulb icon
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTipBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.coralDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Good photos and a clear description help your product get reserved faster.',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.coralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Field row — label + input separated by hairline divider
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFieldRow({
    required String label,
    required bool required,
    required Widget child,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12,
                  color: required ? AppColors.coralDark : AppColors.muted,
                ),
              ),
              if (prefix != null) ...[
                const SizedBox(width: 6),
                Text(
                  prefix,
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom bar — sticky CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Consumer<ProductProvider>(
            builder: (context, product, _) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: product.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.ink,
                    disabledBackgroundColor: AppColors.mutedLight,
                    disabledForegroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: product.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.ink,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.product == null
                              ? 'List product'
                              : 'Update product',
                          style: AppTextStyles.buttonPrimary.copyWith(
                            fontSize: 15,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Hairline divider — used between field rows inside white cards
// ═════════════════════════════════════════════════════════════════════════════
class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
      ),
    );
  }
}
