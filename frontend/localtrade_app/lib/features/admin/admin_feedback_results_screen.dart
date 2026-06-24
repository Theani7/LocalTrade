import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:intl/intl.dart';

class AdminFeedbackResultsScreen extends StatefulWidget {
  const AdminFeedbackResultsScreen({super.key});

  @override
  State<AdminFeedbackResultsScreen> createState() => _AdminFeedbackResultsScreenState();
}

class _AdminFeedbackResultsScreenState extends State<AdminFeedbackResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackProvider>(context, listen: false).fetchAllFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.background,
      body: Consumer<FeedbackProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Feedback results', style: AppTextStyles.screenTitle),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.feedbackList.length} submission${provider.feedbackList.length == 1 ? '' : 's'}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: provider.isLoading && provider.feedbackList.isEmpty
                      ? const ListSkeleton(itemCount: 3)
                      : provider.feedbackList.isEmpty
                          ? const EmptyState(
                              icon: Icons.rate_review_outlined,
                              title: 'No feedback yet',
                              message: 'Share the app with users to start collecting UAT feedback.',
                            )
                          : RefreshIndicator(
                              onRefresh: provider.fetchAllFeedback,
                              color: AppColors.coral,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Stats
                                    Text('Analytics summary', style: AppTextStyles.sectionHeading),
                                    const SizedBox(height: 10),
                                    _buildStatsGrid(provider.stats),
                                    const SizedBox(height: 24),

                                    // Feedback list
                                    Text('Feedback comments', style: AppTextStyles.sectionHeading),
                                    const SizedBox(height: 10),
                                    _buildFeedbackList(provider.feedbackList),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            );
          },
        ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox();

    final items = [
      {'label': 'Avg. rating', 'value': stats['avgRating'], 'color': AppColors.blue},
      {'label': 'Usability', 'value': stats['avgUsability'], 'color': AppColors.success},
      {'label': 'Design', 'value': stats['avgDesign'], 'color': AppColors.warning},
      {'label': 'Performance', 'value': stats['avgPerformance'], 'color': AppColors.coral},
      {'label': 'Completeness', 'value': stats['avgCompleteness'], 'color': AppColors.danger},
      {'label': 'Submissions', 'value': (stats['totalFeedback'] ?? 0).toDouble(), 'color': AppColors.muted},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (item['value'] as double).toStringAsFixed(1),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: item['color'] as Color),
              ),
              const SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackList(List<dynamic> feedback) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feedback.length,
      itemBuilder: (context, index) {
        final item = feedback[index];
        final date = DateTime.parse(item['createdAt']);
        final formattedDate = DateFormat('MMM d, yyyy').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['userId']?['fullName'] ?? 'Anonymous',
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coralLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item['role'].toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.coralDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formattedDate, style: AppTextStyles.caption),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${item['rating']} / 5',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['comment'],
                style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
