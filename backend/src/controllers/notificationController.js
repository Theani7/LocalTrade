const Notification = require('../models/notificationModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

// @desc    Get all notifications for user
// @route   GET /api/v1/notifications
// @access  Private
exports.getNotifications = catchAsync(async (req, res, next) => {
  const notifications = await Notification.find({ recipient: req.user.id }).sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: notifications.length,
    data: { notifications },
  });
});

// @desc    Mark notification as read
// @route   PATCH /api/v1/notifications/:id/read
// @access  Private
exports.markAsRead = catchAsync(async (req, res, next) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, recipient: req.user.id },
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    return next(new AppError('Notification not found or unauthorized', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { notification },
  });
});

// @desc    Mark all notifications as read
// @route   PATCH /api/v1/notifications/mark-all-read
// @access  Private
exports.markAllAsRead = catchAsync(async (req, res, next) => {
  console.log(`[DEBUG] MarkAllRead request received for user: ${req.user.id}`);
  
  const result = await Notification.updateMany(
    { recipient: req.user.id, isRead: { $ne: true } }, 
    { isRead: true }
  );
  
  const unreadCountAfter = await Notification.countDocuments({ 
    recipient: req.user.id, 
    isRead: false 
  });

  console.log(`[DEBUG] MarkAllRead result for ${req.user.id}: Modified: ${result.modifiedCount}, Unread now: ${unreadCountAfter}`);

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'All notifications marked as read',
    data: {
      modifiedCount: result.modifiedCount,
      unreadCount: unreadCountAfter
    }
  });
});
