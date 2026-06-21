const Feedback = require('../models/feedbackModel');
const catchAsync = require('../utils/catchAsync');

// @desc    Submit feedback
// @route   POST /api/v1/feedback
// @access  Private
exports.submitFeedback = catchAsync(async (req, res, next) => {
  const { 
    rating, 
    usabilityRating, 
    designRating, 
    performanceRating, 
    featureCompletenessRating, 
    comment 
  } = req.body;

  const feedback = await Feedback.create({
    userId: req.user.id,
    role: req.user.role,
    rating,
    usabilityRating,
    designRating,
    performanceRating,
    featureCompletenessRating,
    comment
  });

  res.status(201).json({
    success: true,
    status: 'success',
    data: { feedback }
  });
});

// @desc    Get all feedback (Admin only)
// @route   GET /api/v1/feedback
// @access  Private/Admin
exports.getAllFeedback = catchAsync(async (req, res, next) => {
  const feedbackList = await Feedback.find()
    .populate('userId', 'fullName email')
    .sort('-createdAt');

  // Calculate Averages
  const stats = await Feedback.aggregate([
    {
      $group: {
        _id: null,
        avgRating: { $avg: '$rating' },
        avgUsability: { $avg: '$usabilityRating' },
        avgDesign: { $avg: '$designRating' },
        avgPerformance: { $avg: '$performanceRating' },
        avgCompleteness: { $avg: '$featureCompletenessRating' },
        totalFeedback: { $sum: 1 }
      }
    }
  ]);

  res.status(200).json({
    success: true,
    status: 'success',
    results: feedbackList.length,
    data: { 
      feedback: feedbackList,
      stats: stats.length > 0 ? stats[0] : {
        avgRating: 0,
        avgUsability: 0,
        avgDesign: 0,
        avgPerformance: 0,
        avgCompleteness: 0,
        totalFeedback: 0
      }
    }
  });
});
