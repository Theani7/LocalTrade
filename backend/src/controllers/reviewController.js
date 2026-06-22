const Review = require('../models/reviewModel');
const Order = require('../models/orderModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

// @desc    Create a review
// @route   POST /api/v1/reviews
// @access  Private/Customer
exports.createReview = catchAsync(async (req, res, next) => {
  const { productId, rating, reviewText } = req.body;

  if (!productId || !rating || !reviewText) {
    return next(new AppError('Please provide product ID, rating, and review text', 400));
  }

  // Check if customer has purchased the product
  const hasPurchased = await Order.findOne({
    customerId: req.user.id,
    'products.product': productId,
    orderStatus: 'Delivered'
  });

  if (!hasPurchased && req.user.role !== 'admin') {
    return next(new AppError('You can only review products you have purchased and received.', 403));
  }

  // Check for duplicate review
  const existingReview = await Review.findOne({
    productId,
    userId: req.user.id
  });

  if (existingReview) {
    return next(new AppError('You have already reviewed this product', 400));
  }

  const review = await Review.create({
    productId,
    userId: req.user.id,
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
exports.getProductReviews = catchAsync(async (req, res, next) => {
  const reviews = await Review.find({ productId: req.params.productId })
    .populate('userId', 'fullName profileImage')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: reviews.length,
    data: { reviews }
  });
});

// @desc    Update a review
// @route   PATCH /api/v1/reviews/:id
// @access  Private/Customer
exports.updateReview = catchAsync(async (req, res, next) => {
  const review = await Review.findOne({
    _id: req.params.id,
    userId: req.user.id
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

// @desc    Delete a review
// @route   DELETE /api/v1/reviews/:id
// @access  Private/Customer/Admin
exports.deleteReview = catchAsync(async (req, res, next) => {
  const review = await Review.findById(req.params.id);

  if (!review) {
    return next(new AppError('No review found with that ID', 404));
  }

  if (review.userId.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new AppError('You are not authorized to delete this review', 403));
  }

  await Review.findByIdAndDelete(req.params.id); // triggers post findOneAnd hook

  res.status(204).json({
    success: true,
    status: 'success',
    data: null
  });
});
