import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class FeedbackSubmissionScreen extends StatefulWidget {
  const FeedbackSubmissionScreen({super.key});

  @override
  State<FeedbackSubmissionScreen> createState() => _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final _commentController = TextEditingController();
  double _overallRating = 5;
  double _usabilityRating = 5;
  double _designRating = 5;
  double _performanceRating = 5;
  double _completenessRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a comment about your experience.')),
      );
      return;
    }

    final feedbackData = {
      'rating': _overallRating,
      'usabilityRating': _usabilityRating,
      'designRating': _designRating,
      'performanceRating': _performanceRating,
      'featureCompletenessRating': _completenessRating,
      'comment': _commentController.text.trim(),
    };

    final success = await Provider.of<FeedbackProvider>(context, listen: false).submitFeedback(feedbackData);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          title: const Text('Thank you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink)),
          content: const Text('Your feedback has been submitted.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done', style: TextStyle(color: AppColors.coral)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve LocalTrade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rate your experience with the platform.',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 24),

            _buildRatingSection('Overall satisfaction', _overallRating, (v) => setState(() => _overallRating = v)),
            _buildRatingSection('Usability', _usabilityRating, (v) => setState(() => _usabilityRating = v)),
            _buildRatingSection('Design', _designRating, (v) => setState(() => _designRating = v)),
            _buildRatingSection('Performance', _performanceRating, (v) => setState(() => _performanceRating = v)),
            _buildRatingSection('Feature completeness', _completenessRating, (v) => setState(() => _completenessRating = v)),

            const SizedBox(height: 16),
            const Text('Comments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'What did you like? What can be improved?',
              ),
            ),
            const SizedBox(height: 24),

            Consumer<FeedbackProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    child: provider.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                        : const Text('Submit feedback'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink)),
              Text('${value.toInt()} / 5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.coral)),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.coral,
            inactiveColor: AppColors.divider,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
