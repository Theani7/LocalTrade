import { Response, NextFunction } from 'express';
import mongoose from 'mongoose';
import User from '../models/userModel';
import Order from '../models/orderModel';
import Product from '../models/productModel';
import Review from '../models/reviewModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { uploadToCloudinary } from '../utils/cloudinaryUtils';
import { AuthRequest } from '../types';

// @desc    Get vendor analytics
// @route   GET /api/v1/vendors/analytics
// @access  Private/Vendor
export const getVendorAnalytics = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const totalProducts = await Product.countDocuments({ vendorId: userId });
  
  const statsResult = await Order.aggregate([
    { $match: { vendorId: new mongoose.Types.ObjectId(userId as string) } },
    {
      $group: {
        _id: null,
        totalOrders: { $sum: 1 },
        pendingOrders: {
          $sum: { $cond: [{ $eq: ['$orderStatus', 'Pending'] }, 1, 0] }
        },
        confirmedOrders: {
          $sum: {
            $cond: [
              { $in: ['$orderStatus', ['Confirmed', 'Processing']] },
              1,
              0
            ]
          }
        },
        deliveredOrders: {
          $sum: { $cond: [{ $eq: ['$orderStatus', 'Delivered'] }, 1, 0] }
        },
        totalRevenue: {
          $sum: {
            $cond: [{ $eq: ['$orderStatus', 'Delivered'] }, '$totalAmount', 0]
          }
        }
      }
    }
  ]);

  const stats = statsResult[0] || {
    totalOrders: 0,
    pendingOrders: 0,
    confirmedOrders: 0,
    deliveredOrders: 0,
    totalRevenue: 0
  };

  const recentOrders = await Order.find({ vendorId: userId })
    .populate('customerId', 'fullName')
    .sort('-createdAt')
    .limit(5);

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      stats: {
        totalProducts,
        totalOrders: stats.totalOrders,
        pendingOrders: stats.pendingOrders,
        confirmedOrders: stats.confirmedOrders,
        deliveredOrders: stats.deliveredOrders,
        totalRevenue: stats.totalRevenue
      },
      recentOrders
    }
  });
});

// @desc    Get vendor profile
// @route   GET /api/v1/vendors/profile
// @access  Private/Vendor
export const getVendorProfile = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const vendor = await User.findById(userId).select('-password');
  
  if (!vendor) {
    return next(new AppError('Vendor not found', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { vendor },
  });
});

// @desc    Update vendor profile
// @route   PATCH /api/v1/vendors/profile
// @access  Private/Vendor
export const updateVendorProfile = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { shopName, address, phone, businessDescription, bio, openingHours, categories } = req.body;
  
  // Input validation
  if (shopName !== undefined && shopName !== '' && (typeof shopName !== 'string' || shopName.trim().length === 0 || shopName.length > 100)) {
    return next(new AppError('Shop name must be a non-empty string under 100 characters', 400));
  }
  if (phone !== undefined && phone !== '' && !/^\d{7,15}$/.test(phone)) {
    return next(new AppError('Phone number must be digits only, 7 to 15 characters', 400));
  }

  const updateData: any = {};
  if (shopName !== undefined) updateData.shopName = shopName;
  if (address !== undefined && address !== null && address !== '') {
    try {
      const parsed = typeof address === 'string' ? JSON.parse(address) : address;
      if (typeof parsed === 'object' && parsed !== null) {
        updateData.address = {
          fullName: parsed.fullName || '',
          phone: parsed.phone || '',
          street: parsed.street || '',
          landmark: parsed.landmark || '',
          city: parsed.city || '',
          state: parsed.state || '',
          zipCode: parsed.zipCode || '',
        };
      }
    } catch (e) {
      // If parse fails, skip address update
    }
  }
  if (phone !== undefined) updateData.phone = phone;
  if (openingHours !== undefined) updateData.openingHours = openingHours;
  
  if (businessDescription !== undefined) {
    updateData.businessDescription = businessDescription;
  } else if (bio !== undefined) {
    updateData.businessDescription = bio;
  }

  // Parse categories robustly
  if (categories !== undefined) {
    if (Array.isArray(categories)) {
      updateData.categories = categories;
    } else {
      try {
        updateData.categories = JSON.parse(categories);
      } catch (e) {
        updateData.categories = categories
          .replace(/[\[\]]/g, '')
          .split(',')
          .map((c: string) => c.trim())
          .filter((c: string) => c.length > 0);
      }
    }
  }

  if (req.file) {
    updateData.profileImage = await uploadToCloudinary(req.file.buffer, 'localtrade/profiles');
  }

  const userId = req.user?.id || req.user?._id?.toString();
  const vendor = await User.findByIdAndUpdate(
    userId,
    updateData,
    { new: true, runValidators: true }
  ).select('-password');

  if (!vendor) {
    return next(new AppError('No vendor found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { vendor },
  });
});

export default {
  getVendorAnalytics,
  getVendorProfile,
  updateVendorProfile,
};
