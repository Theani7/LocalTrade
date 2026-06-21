import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
  late TextEditingController _stockController;

  String _selectedCategory = 'Vegetables';
  final List<String> _categories = [
    'Vegetables', 'Dairy', 'Handicrafts', 'Clothing', 'Local Goods', 'Tailoring', 'Others'
  ];

  final List<dynamic> _selectedImages = [];
  final List<Uint8List?> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?['title'] ?? '');
    _descController = TextEditingController(text: widget.product?['description'] ?? '');
    _priceController = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _originalPriceController = TextEditingController(text: widget.product?['originalPrice']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?['stock']?.toString() ?? '0');

    if (widget.product != null) {
      _selectedCategory = widget.product['category'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
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

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.product == null && _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final productData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': _priceController.text,
        'originalPrice': _originalPriceController.text.isEmpty ? null : _originalPriceController.text,
        'stock': _stockController.text,
        'category': _selectedCategory,
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
            content: Text(widget.product == null ? 'Product added' : 'Product updated'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Action failed'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
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
        title: Text(widget.product == null ? 'Add product' : 'Edit product'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              const Text('Product images', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.muted, size: 24),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: _imageBytes.length > index && _imageBytes[index] != null
                                ? Image.memory(_imageBytes[index]!, fit: BoxFit.cover, width: 90, height: 90)
                                : Image.network(_selectedImages[index].path, fit: BoxFit.cover, width: 90, height: 90),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              _buildField(controller: _titleController, label: 'Product title'),
              const SizedBox(height: 14),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration('Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 14),

              // Price row
              Row(
                children: [
                  Expanded(child: _buildField(controller: _priceController, label: 'Price (Rs.)', keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(controller: _originalPriceController, label: 'Original price (Rs.)', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(controller: _stockController, label: 'Stock', keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField(controller: _descController, label: 'Description', maxLines: 4),
              const SizedBox(height: 24),

              // Submit
              Consumer<ProductProvider>(
                builder: (context, product, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: product.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                      child: product.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                          : Text(
                              widget.product == null ? 'Add product' : 'Update product',
                              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: _inputDecoration(label),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
