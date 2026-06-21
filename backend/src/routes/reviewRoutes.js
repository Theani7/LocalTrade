const express = require('express');
const reviewController = require('../controllers/reviewController');
const { protect, restrictTo } = require('../middleware/authMiddleware');

const router = express.Router({ mergeParams: true });

// GET /api/v1/products/:productId/reviews
router.get('/', reviewController.getProductReviews);

router.use(protect);

router.post('/', restrictTo('customer', 'admin'), reviewController.createReview);
router.patch('/:id', restrictTo('customer'), reviewController.updateReview);
router.delete('/:id', restrictTo('customer', 'admin'), reviewController.deleteReview);

module.exports = router;
