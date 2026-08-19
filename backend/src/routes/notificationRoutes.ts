import express from 'express';
import { protect } from '../middleware/authMiddleware';
import * as notificationController from '../controllers/notificationController';

const router = express.Router();

router.use(protect);

// @desc    Get all notifications for user
// @route   GET /api/v1/notifications
router.get('/', notificationController.getNotifications);

// @desc    Mark all as read
// @route   PATCH /api/v1/notifications/mark-all-read
router.patch('/mark-all-read', notificationController.markAllAsRead);

// @desc    Mark notification as read
// @route   PATCH /api/v1/notifications/:id/read
router.patch('/:id/read', notificationController.markAsRead);

// @desc    Delete notification
// @route   DELETE /api/v1/notifications/:id
router.delete('/:id', notificationController.deleteNotification);

export = router;
