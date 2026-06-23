import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: AppColors.divider),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 16, width: 70, color: AppColors.divider),
                      Container(
                        height: 28,
                        width: 70,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 14, width: 100, color: AppColors.divider),
                Container(
                  height: 24,
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 12, width: 160, color: AppColors.divider),
            const SizedBox(height: 6),
            Container(height: 12, width: 120, color: AppColors.divider),
            const SizedBox(height: 10),
            Container(height: 14, width: 80, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 20, width: 50, color: AppColors.divider),
            const SizedBox(height: 6),
            Container(height: 12, width: 70, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Container(
            key: ValueKey(index),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: AppColors.divider),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 80, color: AppColors.divider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReviewCardSkeleton extends StatelessWidget {
  final int count;
  const ReviewCardSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: Column(
        children: List.generate(count, (index) => Container(
          key: ValueKey(index),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
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
                      color: AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: 80, color: AppColors.divider),
                        const SizedBox(height: 4),
                        Container(height: 10, width: 60, color: AppColors.divider),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 10, width: 100, color: AppColors.divider),
              const SizedBox(height: 6),
              Container(height: 12, width: double.infinity, color: AppColors.divider),
              const SizedBox(height: 4),
              Container(height: 12, width: 200, color: AppColors.divider),
            ],
          ),
        )),
      ),
    );
  }
}

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 180, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Container(
                    height: 22,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(height: 14, width: 60, color: AppColors.divider),
                        Container(height: 20, width: 100, color: AppColors.divider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(height: 16, width: 60, color: AppColors.divider),
                              const SizedBox(height: 4),
                              Container(height: 10, width: 40, color: AppColors.divider),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: AppColors.divider),
                        Expanded(
                          child: Column(
                            children: [
                              Container(height: 16, width: 60, color: AppColors.divider),
                              const SizedBox(height: 4),
                              Container(height: 10, width: 40, color: AppColors.divider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 70, color: AppColors.divider),
                        const SizedBox(height: 8),
                        Container(height: 12, width: double.infinity, color: AppColors.divider),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 200, color: AppColors.divider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
