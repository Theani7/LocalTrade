const User = require('../models/userModel');
const Order = require('../models/orderModel');
const Product = require('../models/productModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { uploadToCloudinary } = require('../utils/cloudinaryUtils');

// @desc    Get vendor analytics
// @route   GET /api/v1/vendors/analytics
// @access  Private/Vendor
exports.getVendorAnalytics = catchAsync(async (req, res, next) => {
  const mongoose = require('mongoose');
  const totalProducts = await Product.countDocuments({ vendorId: req.user.id });
  
  const statsResult = await Order.aggregate([
    { $match: { vendorId: new mongoose.Types.ObjectId(req.user.id) } },
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

  const recentOrders = await Order.find({ vendorId: req.user.id })
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
exports.getVendorProfile = catchAsync(async (req, res, next) => {
  const vendor = await User.findById(req.user.id).select('-password');
  
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
exports.updateVendorProfile = catchAsync(async (req, res, next) => {
  const { shopName, address, phone, businessDescription, bio, openingHours, categories } = req.body;
  
  // Input validation
  if (shopName !== undefined && shopName !== '' && (typeof shopName !== 'string' || shopName.trim().length === 0 || shopName.length > 100)) {
    return next(new AppError('Shop name must be a non-empty string under 100 characters', 400));
  }
  if (phone !== undefined && phone !== '' && !/^\d{7,15}$/.test(phone)) {
    return next(new AppError('Phone number must be digits only, 7 to 15 characters', 400));
  }

  const updateData = {};
  if (shopName !== undefined) updateData.shopName = shopName;
  if (address !== undefined && address !== null && address !== '') {
    try {
      const parsed = typeof address === 'string' ? JSON.parse(address) : address;
      if (typeof parsed === 'object' && parsed !== null) {
        updateData.address = {
          fullName: parsed.fullName || '',
          phone: parsed.phone || '',
          flatHouse: parsed.flatHouse || '',
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
          .map(c => c.trim())
          .filter(c => c.length > 0);
      }
    }
  }

  if (req.file) {
    updateData.profileImage = await uploadToCloudinary(req.file.buffer, 'localtrade/profiles');
  }

  const vendor = await User.findByIdAndUpdate(
    req.user.id,
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
