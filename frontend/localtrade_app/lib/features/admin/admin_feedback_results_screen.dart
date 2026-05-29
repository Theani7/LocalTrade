import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
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
    Future.microtask(() => Provider.of<FeedbackProvider>(context, listen: false).fetchAllFeedback());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAT Feedback Results'),
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.feedbackList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.feedbackList.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No Feedback Yet',
              message: 'Share the app with users to start collecting UAT feedback.',
            );
          }

          final stats = provider.stats;

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllFeedback(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UAT Analytics Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatsGrid(stats),
                  const SizedBox(height: 32),
                  const Text('Detailed Feedback Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildFeedbackList(provider.feedbackList),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) {
            switch (index) {
              case 0: return _buildStatCard('Avg. Rating', stats['avgRating'], Colors.blue);
              case 1: return _buildStatCard('Usability', stats['avgUsability'], Colors.green);
              case 2: return _buildStatCard('Design', stats['avgDesign'], Colors.orange);
              case 3: return _buildStatCard('Performance', stats['avgPerformance'], Colors.purple);
              case 4: return _buildStatCard('Completeness', stats['avgCompleteness'], Colors.red);
              case 5: return _buildStatCard('Submissions', stats['totalFeedback'].toDouble(), Colors.teal);
              default: return const SizedBox();
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['userId']?['fullName'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['role'].toString().toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${item['rating']} / 5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['comment'],
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
