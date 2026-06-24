const express = require('express');
const reviewController = require('../controllers/reviewController');
const { protect, restrictTo } = require('../middleware/authMiddleware');

const router = express.Router({ mergeParams: true });

// GET /api/v1/products/:productId/reviews
router.get('/', reviewController.getProductReviews);

router.use(protect);

// GET /api/v1/reviews/my-reviews (must be before /:id routes)
router.get('/my-reviews', restrictTo('customer'), reviewController.getMyReviews);

router.post('/', restrictTo('customer', 'admin'), reviewController.createReview);
router.patch('/:id', restrictTo('customer'), reviewController.updateReview);
router.patch('/:id/reply', restrictTo('vendor', 'admin'), reviewController.addVendorReply);
router.delete('/:id', restrictTo('customer', 'admin'), reviewController.deleteReview);

module.exports = router;
