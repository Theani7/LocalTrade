import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../widgets/app_scaffold.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    _categories = await provider.fetchAllCategories();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Categories', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add, size: 20, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
          : _categories.isEmpty
              ? const Center(
                  child: Text('No categories yet', style: TextStyle(color: AppColors.muted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = cat['isActive'] == true;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.coralLight : AppColors.mutedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              size: 18,
                              color: isActive ? AppColors.coralDark : AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isActive ? AppColors.ink : AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isActive ? AppColors.success : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditDialog(cat),
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
                          ),
                          IconButton(
                            onPressed: () => _toggleActive(cat),
                            icon: Icon(
                              isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showDeleteConfirm(cat),
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final provider = Provider.of<CategoryProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await provider.createCategory(controller.text.trim());
              if (!mounted) return;
              if (success) {
                _loadCategories();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to create category'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> cat) {
    final controller = TextEditingController(text: cat['name'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final provider = Provider.of<CategoryProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await provider.updateCategory(cat['_id'], name: controller.text.trim());
              if (!mounted) return;
              if (success) {
                _loadCategories();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to update category'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> cat) async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    await provider.updateCategory(cat['_id'], isActive: !(cat['isActive'] ?? true));
    _loadCategories();
  }

  void _showDeleteConfirm(Map<String, dynamic> cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text('Delete "${cat['name']}"? Products in this category will keep their current category label.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<CategoryProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await provider.deleteCategory(cat['_id']);
              if (!mounted) return;
              if (success) {
                _loadCategories();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to delete category'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
