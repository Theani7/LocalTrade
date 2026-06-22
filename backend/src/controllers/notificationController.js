const Notification = require('../models/notificationModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

// @desc    Get all notifications for user
// @route   GET /api/v1/notifications
// @access  Private
exports.getNotifications = catchAsync(async (req, res, next) => {
  const filter = { recipient: req.user.id };

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [notifications, totalResults] = await Promise.all([
      Notification.find(filter).sort('-createdAt').skip(skip).limit(limit),
      Notification.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      status: 'success',
      results: notifications.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      data: { notifications },
    });
  }

  const notifications = await Notification.find(filter).sort('-createdAt');

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
  const result = await Notification.updateMany(
    { recipient: req.user.id, isRead: { $ne: true } }, 
    { isRead: true }
  );
  
  const unreadCountAfter = await Notification.countDocuments({ 
    recipient: req.user.id, 
    isRead: false 
  });

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
