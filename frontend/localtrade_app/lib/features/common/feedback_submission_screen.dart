import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../core/theme/app_theme.dart';

class FeedbackSubmissionScreen extends StatefulWidget {
  const FeedbackSubmissionScreen({super.key});

  @override
  State<FeedbackSubmissionScreen> createState() => _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final TextEditingController _commentController = TextEditingController();
  
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thank You!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Your feedback has been submitted successfully. We appreciate your input for our UAT process.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAT Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve LocalTrade',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please rate your experience with the platform. Your feedback is vital for our final evaluation.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            _buildRatingSection('Overall Satisfaction', _overallRating, (val) => setState(() => _overallRating = val)),
            _buildRatingSection('Usability & Ease of Use', _usabilityRating, (val) => setState(() => _usabilityRating = val)),
            _buildRatingSection('UI/UX Design', _designRating, (val) => setState(() => _designRating = val)),
            _buildRatingSection('App Performance', _performanceRating, (val) => setState(() => _performanceRating = val)),
            _buildRatingSection('Feature Completeness', _completenessRating, (val) => setState(() => _completenessRating = val)),
            
            const SizedBox(height: 24),
            const Text('Additional Comments', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What did you like? What can be improved?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            
            Consumer<FeedbackProvider>(
              builder: (context, provider, _) => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toInt().toString(),
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Poor', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('${value.toInt()} / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const Text('Excellent', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
