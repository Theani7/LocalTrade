import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/product_card.dart';

class MyWishlistScreen extends StatefulWidget {
  const MyWishlistScreen({super.key});

  @override
  State<MyWishlistScreen> createState() => _MyWishlistScreenState();
}

class _MyWishlistScreenState extends State<MyWishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Wishlist', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.items.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: () => provider.loadWishlist(),
                  color: AppColors.coral,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: _buildEmptyState(),
                    ),
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadWishlist(),
            color: AppColors.coral,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingH, 8, AppSpacing.screenPaddingH, 8),
                  child: Row(
                    children: [
                      Text(
                        '${provider.itemCount} item${provider.itemCount == 1 ? '' : 's'}',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      final product = provider.items[index];
                      return Stack(
                        children: [
                          ProductCard(
                            product: product,
                            showCartButton: false,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () async {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                await provider.removeFromWishlist(
                                    product['_id'].toString());
                                if (!mounted) return;
                                messenger.showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor: AppColors.ink,
                                      content: const Text(
                                        'Removed from wishlist',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.surface),
                                      ),
                                    ),
                                  );
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 32, color: AppColors.coral),
            ),
            const SizedBox(height: 20),
            Text('No items yet', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product to save it here',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Browse products',
                    style: AppTextStyles.cardTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
