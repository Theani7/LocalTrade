import { Response, NextFunction } from 'express';
import Notification from '../models/notificationModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { AuthRequest } from '../types';

// @desc    Get all notifications for user
// @route   GET /api/v1/notifications
// @access  Private
export const getNotifications = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const filter = { recipient: userId };

  const unreadCount = await Notification.countDocuments({ recipient: userId, isRead: false });

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const [notifications, totalResults] = await Promise.all([
      Notification.find(filter).sort('-createdAt').skip(skip).limit(limit),
      Notification.countDocuments(filter),
    ]);

    res.status(200).json({
      success: true,
      status: 'success',
      results: notifications.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      unreadCount,
      data: { notifications },
    });
    return;
  }

  const notifications = await Notification.find(filter).sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: notifications.length,
    unreadCount,
    data: { notifications },
  });
});

// @desc    Mark notification as read
// @route   PATCH /api/v1/notifications/:id/read
// @access  Private
export const markAsRead = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, recipient: userId },
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
export const markAllAsRead = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const result = await Notification.updateMany(
    { recipient: userId, isRead: { $ne: true } }, 
    { isRead: true }
  );
  
  const unreadCountAfter = await Notification.countDocuments({ 
    recipient: userId, 
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

// @desc    Delete a notification
// @route   DELETE /api/v1/notifications/:id
// @access  Private
export const deleteNotification = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const notification = await Notification.findOneAndDelete({
    _id: req.params.id,
    recipient: userId,
  });

  if (!notification) {
    return next(new AppError('Notification not found or unauthorized', 404));
  }

  res.status(204).json({
    success: true,
    status: 'success',
    data: null,
  });
});

export default {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
};
