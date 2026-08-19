import { Response, NextFunction } from 'express';
import Feedback from '../models/feedbackModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { AuthRequest } from '../types';

// @desc    Submit feedback
// @route   POST /api/v1/feedback
// @access  Private
export const submitFeedback = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { 
    rating, 
    usabilityRating, 
    designRating, 
    performanceRating, 
    featureCompletenessRating, 
    comment 
  } = req.body;

  const userId = req.user?.id || req.user?._id?.toString();
  const existing = await Feedback.findOne({ userId });
  if (existing) {
    return next(new AppError('You have already submitted feedback', 400));
  }

  try {
    const feedback = await Feedback.create({
      userId,
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
  } catch (err: any) {
    if (err.code === 11000) {
      return next(new AppError('You have already submitted feedback', 400));
    }
    throw err;
  }
});

// @desc    Get all feedback (Admin only)
// @route   GET /api/v1/feedback
// @access  Private/Admin
export const getAllFeedback = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
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

export default {
  submitFeedback,
  getAllFeedback,
};
