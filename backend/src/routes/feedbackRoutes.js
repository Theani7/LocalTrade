const express = require('express');
const feedbackController = require('../controllers/feedbackController');
const { protect, restrictTo } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/', feedbackController.submitFeedback);
router.get('/', restrictTo('admin'), feedbackController.getAllFeedback);

module.exports = router;
