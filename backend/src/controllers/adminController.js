const User = require('../models/userModel');
const Product = require('../models/productModel');
const Order = require('../models/orderModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendNotification } = require('../utils/notificationUtils');

// @desc    Get full system analytics
// @route   GET /api/v1/admin/analytics
// @access  Private/Admin
exports.getSystemAnalytics = catchAsync(async (req, res, next) => {
  const totalUsers = await User.countDocuments();
  const totalCustomers = await User.countDocuments({ role: 'customer' });
  const totalVendors = await User.countDocuments({ role: 'vendor' });
  const pendingVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'pending' });
  const approvedVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'approved' });
  const suspendedVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'suspended' });

  const totalProducts = await Product.countDocuments();

  const statsResult = await Order.aggregate([
    {
      $group: {
        _id: null,
        totalOrders: { $sum: 1 },
        completedOrders: {
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

  const orderStats = statsResult[0] || {
    totalOrders: 0,
    completedOrders: 0,
    totalRevenue: 0
  };

  const totalOrders = orderStats.totalOrders;
  const completedOrders = orderStats.completedOrders;
  const totalRevenue = orderStats.totalRevenue;

  // Revenue by category (Aggregation)
  const revenueByCategory = await Order.aggregate([
    { $match: { orderStatus: 'Delivered' } },
    { $unwind: '$items' },
    {
      $lookup: {
        from: 'products',
        localField: 'items.productId',
        foreignField: '_id',
        as: 'productInfo'
      }
    },
    { $unwind: '$productInfo' },
    {
      $group: {
        _id: '$productInfo.category',
        revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
      }
    },
    { $sort: { revenue: -1 } }
  ]);

  // Orders per day (last 7 days)
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  
  const dailyStats = await Order.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 },
        revenue: { $sum: '$totalAmount' }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  const recentOrders = await Order.find()
    .populate('customerId', 'fullName')
    .populate('vendorId', 'fullName')
    .sort('-createdAt')
    .limit(5);

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      stats: {
        totalUsers,
        totalCustomers,
        totalVendors,
        pendingVendors,
        approvedVendors,
        suspendedVendors,
        totalProducts,
        totalOrders,
        completedOrders,
        totalRevenue
      },
      revenueByCategory,
      dailyStats,
      recentOrders
    }
  });
});

// @desc    Get all users (with search, filter, pagination)
// @route   GET /api/v1/admin/users
// @access  Private/Admin
exports.getAllUsers = catchAsync(async (req, res, next) => {
  const { search, role, page = 1, limit = 10 } = req.query;
  const filter = {};

  const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { fullName: { $regex: escapedSearch, $options: 'i' } },
      { email: { $regex: escapedSearch, $options: 'i' } },
      { phone: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  if (role && role !== 'All') {
    filter.role = role;
  }

  const skip = (page - 1) * limit;
  const users = await User.find(filter)
    .select('-password')
    .sort('-createdAt')
    .skip(skip)
    .limit(parseInt(limit, 10));

  const totalCount = await User.countDocuments(filter);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: parseInt(page, 10),
    totalPages: Math.ceil(totalCount / limit),
    results: users.length,
    data: { users }
  });
});

// @desc    Get all vendors (with search, filter, pagination)
// @route   GET /api/v1/admin/vendors
// @access  Private/Admin
exports.getAllVendors = catchAsync(async (req, res, next) => {
  const { search, status, page = 1, limit = 10 } = req.query;
  const filter = { role: 'vendor' };

  const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { fullName: { $regex: escapedSearch, $options: 'i' } },
      { shopName: { $regex: escapedSearch, $options: 'i' } },
      { email: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  if (status && status !== 'All') {
    filter.vendorApprovalStatus = status;
  }

  const skip = (page - 1) * limit;
  const vendors = await User.find(filter)
    .select('-password')
    .sort('-createdAt')
    .skip(skip)
    .limit(parseInt(limit, 10));

  const totalCount = await User.countDocuments(filter);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: parseInt(page, 10),
    totalPages: Math.ceil(totalCount / limit),
    results: vendors.length,
    data: { vendors }
  });
});

// @desc    Get all products (with search, filter, pagination)
// @route   GET /api/v1/admin/products
// @access  Private/Admin
exports.getAllProducts = catchAsync(async (req, res, next) => {
  const { search, category, page = 1, limit = 10 } = req.query;
  const filter = {};

  const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { title: { $regex: escapedSearch, $options: 'i' } },
      { description: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  if (category && category !== 'All') {
    filter.category = category;
  }

  const skip = (page - 1) * limit;
  const products = await Product.find(filter)
    .populate('vendorId', 'fullName shopName')
    .sort('-createdAt')
    .skip(skip)
    .limit(parseInt(limit, 10));

  const totalCount = await Product.countDocuments(filter);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: parseInt(page, 10),
    totalPages: Math.ceil(totalCount / limit),
    results: products.length,
    data: { products }
  });
});

// @desc    Get all orders (with search, filter, pagination)
// @route   GET /api/v1/admin/orders
// @access  Private/Admin
exports.getAllOrders = catchAsync(async (req, res, next) => {
  const { search, status, page = 1, limit = 10 } = req.query;
  const filter = {};

  if (status && status !== 'All') {
    filter.orderStatus = status;
  }

  if (search) {
    const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    const searchRegex = new RegExp(escapeRegex(search), 'i');
    filter.$or = [
      { 'shippingAddress.fullName': searchRegex },
      { 'shippingAddress.phone': searchRegex },
    ];
  }

  const skip = (page - 1) * limit;
  const orders = await Order.find(filter)
    .populate('customerId', 'fullName')
    .populate('vendorId', 'fullName shopName')
    .sort('-createdAt')
    .skip(skip)
    .limit(parseInt(limit, 10));

  const totalCount = await Order.countDocuments(filter);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: parseInt(page, 10),
    totalPages: Math.ceil(totalCount / limit),
    results: orders.length,
    data: { orders }
  });
});

// @desc    Approve or Suspend Vendor
// @route   PATCH /api/v1/admin/vendors/:id/status
// @access  Private/Admin
exports.updateVendorStatus = catchAsync(async (req, res, next) => {
  const { status } = req.body;

  if (!['approved', 'suspended', 'pending'].includes(status)) {
    return next(new AppError('Invalid status provided', 400));
  }

  const user = await User.findById(req.params.id);

  if (!user || user.role !== 'vendor') {
    return next(new AppError('No vendor found with that ID', 404));
  }

  user.vendorApprovalStatus = status;
  await user.save();

  // Notify Vendor of the status change
  let title = 'Account Status Updated';
  let message = `Your vendor account status has been updated to ${status}.`;
  
  if (status === 'approved') {
    title = 'Vendor Account Approved!';
    message = 'Congratulations! Your vendor account has been approved. You can now start listing products.';
  } else if (status === 'suspended') {
    title = 'Account Suspended';
    message = 'Your vendor account has been suspended. Please contact support for more details.';
  }

  await sendNotification(user._id, title, message, { status }, 'Account');

  res.status(200).json({
    success: true,
    status: 'success',
    message: `Vendor status updated to ${status}`,
    data: { user },
  });
});

// @desc    Toggle User Active Status
// @route   PATCH /api/v1/admin/users/:id/toggle-status
// @access  Private/Admin
exports.toggleUserStatus = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  if (user._id.toString() === req.user.id) {
    return next(new AppError('You cannot deactivate your own account', 400));
  }
  if (user.role === 'admin') {
    return next(new AppError('Cannot toggle admin account status', 400));
  }

  user.isActive = !user.isActive;
  await user.save();

  await sendNotification(
    user._id,
    `Your account has been ${user.isActive ? 'activated' : 'deactivated'}`,
    `If you have questions, please contact support.`,
    null,
    'Account'
  );

  res.status(200).json({
    success: true,
    status: 'success',
    message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
    data: { user },
  });
});
