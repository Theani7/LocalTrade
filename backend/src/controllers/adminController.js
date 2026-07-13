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

  const userDailyStats = await User.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  const productDailyStats = await Product.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 }
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
      userDailyStats,
      productDailyStats,
      recentOrders
    }
  });
});

// @desc    Get all users (with search, filter, pagination)
// @route   GET /api/v1/admin/users
// @access  Private/Admin
exports.getAllUsers = catchAsync(async (req, res, next) => {
  const { search, role, page = 1, limit = 10 } = req.query;
  const filter = { role: 'customer' };

  const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { fullName: { $regex: escapedSearch, $options: 'i' } },
      { email: { $regex: escapedSearch, $options: 'i' } },
      { phone: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  const totalCustomers = await User.countDocuments({ role: 'customer' });
  const activeCustomers = await User.countDocuments({ role: 'customer', isActive: true });
  const inactiveCustomers = await User.countDocuments({ role: 'customer', isActive: false });

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
    data: {
      users,
      stats: {
        totalUsers: totalCustomers,
        activeUsers: activeCustomers,
        inactiveUsers: inactiveCustomers,
      }
    }
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

  const totalVendors = await User.countDocuments({ role: 'vendor' });
  const approvedVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'approved' });
  const pendingVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: { $in: ['pending', null, undefined] } });
  const suspendedVendors = await User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'suspended' });

  const skip = (page - 1) * limit;
  const vendors = await User.find(filter)
    .select('-password')
    .sort('-createdAt')
    .skip(skip)
    .limit(parseInt(limit, 10));

  const totalCount = await User.countDocuments(filter);

  const vendorIds = vendors.map(v => v._id);
  const productCounts = await Product.aggregate([
    { $match: { vendorId: { $in: vendorIds } } },
    { $group: { _id: '$vendorId', count: { $sum: 1 } } },
  ]);
  const countMap = {};
  for (const pc of productCounts) {
    countMap[pc._id.toString()] = pc.count;
  }
  const vendorsWithCounts = vendors.map(v => ({
    ...v.toObject(),
    productCount: countMap[v._id.toString()] || 0,
  }));

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: parseInt(page, 10),
    totalPages: Math.ceil(totalCount / limit),
    results: vendors.length,
    data: {
      vendors: vendorsWithCounts,
      stats: {
        totalVendors,
        approvedVendors,
        pendingVendors,
        suspendedVendors,
      }
    }
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

  const totalProducts = await Product.countDocuments();
  const availableProducts = await Product.countDocuments({ productStatus: 'Available' });
  const unavailableProducts = await Product.countDocuments({ productStatus: { $in: ['OutOfStock', 'Inactive'] } });

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
    data: {
      products,
      stats: {
        totalProducts,
        availableProducts,
        unavailableProducts,
      }
    }
  });
});

// @desc    Get single product details
// @route   GET /api/v1/admin/products/:id
// @access  Private/Admin
exports.getProduct = catchAsync(async (req, res, next) => {
  const product = await Product.findById(req.params.id)
    .populate('vendorId', 'fullName email phone shopName businessDescription categories address');

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { product }
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

  const totalOrders = await Order.countDocuments();
  const pendingOrders = await Order.countDocuments({ orderStatus: 'Pending' });
  const deliveredOrders = await Order.countDocuments({ orderStatus: 'Delivered' });
  const cancelledOrders = await Order.countDocuments({ orderStatus: 'Cancelled' });

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
    data: {
      orders,
      stats: {
        totalOrders,
        pendingOrders,
        deliveredOrders,
        cancelledOrders,
      }
    }
  });
});

// @desc    Get vendor detail with stats
// @route   GET /api/v1/admin/vendors/:id
// @access  Private/Admin
exports.getVendorDetail = catchAsync(async (req, res, next) => {
  const vendor = await User.findById(req.params.id).select('-password');

  if (!vendor || vendor.role !== 'vendor') {
    return next(new AppError('No vendor found with that ID', 404));
  }

  const vendorId = vendor._id;

  const totalProducts = await Product.countDocuments({ vendorId });
  const availableProducts = await Product.countDocuments({ vendorId, productStatus: 'Available' });
  const outOfStockProducts = await Product.countDocuments({ vendorId, productStatus: 'OutOfStock' });

  const orderStats = await Order.aggregate([
    { $match: { vendorId: vendorId } },
    {
      $group: {
        _id: null,
        totalOrders: { $sum: 1 },
        deliveredOrders: {
          $sum: { $cond: [{ $eq: ['$orderStatus', 'Delivered'] }, 1, 0] }
        },
        pendingOrders: {
          $sum: { $cond: [{ $eq: ['$orderStatus', 'Pending'] }, 1, 0] }
        },
        cancelledOrders: {
          $sum: { $cond: [{ $eq: ['$orderStatus', 'Cancelled'] }, 1, 0] }
        },
        totalRevenue: {
          $sum: {
            $cond: [{ $eq: ['$orderStatus', 'Delivered'] }, '$totalAmount', 0]
          }
        },
      }
    }
  ]);

  const stats = orderStats[0] || {
    totalOrders: 0,
    deliveredOrders: 0,
    pendingOrders: 0,
    cancelledOrders: 0,
    totalRevenue: 0,
  };

  const recentOrders = await Order.find({ vendorId })
    .populate('customerId', 'fullName')
    .sort('-createdAt')
    .limit(5)
    .select('orderStatus totalAmount createdAt customerId');

  const products = await Product.find({ vendorId })
    .select('title price images stockQuantity productStatus')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      vendor,
      stats: {
        totalProducts,
        availableProducts,
        outOfStockProducts,
        ...stats,
      },
      recentOrders,
      products,
    }
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
  let title = 'Account status updated';
  let message = `Your vendor account status has been updated to ${status}.`;
  
  if (status === 'approved') {
    title = 'Vendor account approved';
    message = 'Your vendor account has been approved. You can now start listing products.';
  } else if (status === 'suspended') {
    title = 'Vendor account suspended';
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
    user.isActive
      ? 'Your account is now active. You can sign in and use LocalTrade.'
      : 'Your account has been deactivated. Please contact support if you have questions.',
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

// @desc    Export analytics as CSV
// @route   GET /api/v1/admin/analytics/export
// @access  Private/Admin
exports.exportAnalytics = catchAsync(async (req, res, next) => {
  const { format = 'csv', type = 'overview' } = req.query;

  let csvContent = '';
  let filename = '';

  if (type === 'orders') {
    const orders = await Order.find()
      .populate('customerId', 'fullName email')
      .populate('vendorId', 'fullName shopName')
      .sort('-createdAt');

    csvContent = 'Order ID,Customer,Vendor,Amount,Status,Date\n';
    for (const order of orders) {
      const id = order._id.toString().slice(-8).toUpperCase();
      const customer = order.customerId?.fullName || 'N/A';
      const vendor = order.vendorId?.shopName || order.vendorId?.fullName || 'N/A';
      const amount = order.totalAmount || 0;
      const status = order.orderStatus || 'Unknown';
      const date = order.createdAt ? new Date(order.createdAt).toLocaleDateString() : '';
      csvContent += `"#${id}","${customer}","${vendor}",${amount},"${status}","${date}"\n`;
    }
    filename = 'localtrade-orders';
  } else if (type === 'products') {
    const products = await Product.find()
      .populate('vendorId', 'fullName shopName')
      .sort('-createdAt');

    csvContent = 'Product,Vendor,Category,Price,Stock,Status\n';
    for (const product of products) {
      const vendor = product.vendorId?.shopName || product.vendorId?.fullName || 'N/A';
      const status = (product.stockQuantity > 0 && product.productStatus !== 'unavailable') ? 'Available' : 'Unavailable';
      csvContent += `"${product.title}","${vendor}","${product.category || 'N/A'}",${product.price},${product.stockQuantity},"${status}"\n`;
    }
    filename = 'localtrade-products';
  } else if (type === 'vendors') {
    const vendors = await User.find({ role: 'vendor' }).select('-password').sort('-createdAt');

    csvContent = 'Name,Shop,Email,Status,Joined\n';
    for (const vendor of vendors) {
      const joined = vendor.createdAt ? new Date(vendor.createdAt).toLocaleDateString() : '';
      csvContent += `"${vendor.fullName}","${vendor.shopName || 'N/A'}","${vendor.email}","${vendor.vendorApprovalStatus}","${joined}"\n`;
    }
    filename = 'localtrade-vendors';
  } else {
    const totalUsers = await User.countDocuments();
    const totalVendors = await User.countDocuments({ role: 'vendor' });
    const totalProducts = await Product.countDocuments();
    const totalOrders = await Order.countDocuments();
    const revenueResult = await Order.aggregate([
      { $match: { orderStatus: 'Delivered' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);
    const totalRevenue = revenueResult[0]?.total || 0;

    csvContent = 'Metric,Value\n';
    csvContent += `Total Users,${totalUsers}\n`;
    csvContent += `Total Vendors,${totalVendors}\n`;
    csvContent += `Total Products,${totalProducts}\n`;
    csvContent += `Total Orders,${totalOrders}\n`;
    csvContent += `Total Revenue,${totalRevenue}\n`;
    filename = 'localtrade-overview';
  }

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}-${new Date().toISOString().split('T')[0]}.csv"`);
  res.status(200).send(csvContent);
});
