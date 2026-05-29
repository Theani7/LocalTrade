const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const notificationController = require('../controllers/notificationController');

const router = express.Router();

router.use(protect);

// @desc    Get all notifications for user
// @route   GET /api/v1/notifications
router.get('/', notificationController.getNotifications);

// @desc    Mark notification as read
// @route   PATCH /api/v1/notifications/:id/read
router.patch('/:id/read', notificationController.markAsRead);

// @desc    Mark all as read
// @route   PATCH /api/v1/notifications/mark-all-read
router.patch('/mark-all-read', notificationController.markAllAsRead);

module.exports = router;
