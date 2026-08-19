import { Response, NextFunction } from 'express';
import Review from '../models/reviewModel';
import Order from '../models/orderModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { AuthRequest } from '../types';

// @desc    Create a review
// @route   POST /api/v1/reviews
// @access  Private/Customer
export const createReview = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { productId, rating, reviewText } = req.body;

  if (!productId || !rating || !reviewText) {
    return next(new AppError('Please provide product ID, rating, and review text', 400));
  }

  const userId = req.user?.id || req.user?._id?.toString();

  // Check if customer has purchased the product
  const hasPurchased = await Order.findOne({
    customerId: userId,
    'products.product': productId,
    orderStatus: 'Delivered'
  });

  if (!hasPurchased) {
    return next(new AppError('You can only review products you have purchased and received.', 403));
  }

  // Check for duplicate review
  const existingReview = await Review.findOne({
    productId,
    userId,
  });

  if (existingReview) {
    return next(new AppError('You have already reviewed this product', 400));
  }

  const review = await Review.create({
    productId,
    userId,
    rating,
    reviewText
  });

  res.status(201).json({
    success: true,
    status: 'success',
    data: { review }
  });
});

// @desc    Get all reviews for a product
// @route   GET /api/v1/products/:productId/reviews
// @access  Public
export const getProductReviews = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  if (!req.params.productId) {
    return next(new AppError('Product ID is required', 400));
  }

  const page = Math.max(parseInt(req.query.page as string, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit as string, 10) || 20, 1), 50);
  const skip = (page - 1) * limit;

  const [reviews, totalCount] = await Promise.all([
    Review.find({ productId: req.params.productId })
      .populate('userId', 'fullName profileImage')
      .sort('-createdAt')
      .skip(skip)
      .limit(limit),
    Review.countDocuments({ productId: req.params.productId }),
  ]);

  res.status(200).json({
    success: true,
    status: 'success',
    results: reviews.length,
    totalCount,
    page,
    totalPages: Math.ceil(totalCount / limit),
    data: { reviews }
  });
});

// @desc    Update a review
// @route   PATCH /api/v1/reviews/:id
// @access  Private/Customer
export const updateReview = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const review = await Review.findOne({
    _id: req.params.id,
    userId,
  });

  if (!review) {
    return next(new AppError('Review not found or you are not authorized to update it', 404));
  }

  if (req.body.rating !== undefined) {
    const rating = Number(req.body.rating);
    if (isNaN(rating) || rating < 1 || rating > 5) {
      return next(new AppError('Rating must be between 1 and 5', 400));
    }
    review.rating = rating;
  }
  if (req.body.reviewText !== undefined) {
    if (typeof req.body.reviewText !== 'string' || req.body.reviewText.trim().length === 0) {
      return next(new AppError('Review text cannot be empty', 400));
    }
    if (req.body.reviewText.length > 1000) {
      return next(new AppError('Review text must be under 1000 characters', 400));
    }
    review.reviewText = req.body.reviewText;
  }

  await review.save(); // triggers post save hook

  res.status(200).json({
    success: true,
    status: 'success',
    data: { review }
  });
});

// @desc    Get reviews by the logged-in user
// @route   GET /api/v1/reviews/my-reviews
// @access  Private/Customer
export const getMyReviews = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const reviews = await Review.find({ userId })
    .populate('productId', 'title images')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: reviews.length,
    data: { reviews }
  });
});

// @desc    Vendor reply to a review
// @route   PATCH /api/v1/reviews/:id/reply
// @access  Private/Vendor (must own the product)
export const addVendorReply = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { text } = req.body;

  if (!text || typeof text !== 'string' || text.trim().length === 0) {
    return next(new AppError('Reply text is required', 400));
  }
  if (text.length > 500) {
    return next(new AppError('Reply must be under 500 characters', 400));
  }

  const review = await Review.findById(req.params.id).populate('productId', 'vendorId');

  if (!review) {
    return next(new AppError('Review not found', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();
  const product = review.productId as any;
  const productVendorId = product?.vendorId?._id
    ? product.vendorId._id.toString()
    : product?.vendorId?.toString?.() || '';

  if (productVendorId !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You can only reply to reviews on your own products', 403));
  }

  if (review.vendorReply && review.vendorReply.text) {
    return next(new AppError('You have already replied to this review', 400));
  }

  review.vendorReply = {
    text: text.trim(),
    repliedAt: new Date(),
  };
  await review.save();

  res.status(200).json({
    success: true,
    status: 'success',
    data: { review }
  });
});

// @desc    Delete a review
// @route   DELETE /api/v1/reviews/:id
// @access  Private/Customer/Admin
export const deleteReview = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const review = await Review.findById(req.params.id);

  if (!review) {
    return next(new AppError('No review found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  if (review.userId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You are not authorized to delete this review', 403));
  }

  await Review.findByIdAndDelete(req.params.id);

  res.status(204).json({
    success: true,
    status: 'success',
    data: null
  });
});

export default {
  createReview,
  getProductReviews,
  updateReview,
  getMyReviews,
  addVendorReply,
  deleteReview,
};
