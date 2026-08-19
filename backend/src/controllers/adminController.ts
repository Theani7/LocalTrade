import { Response, NextFunction } from 'express';
import User from '../models/userModel';
import Product from '../models/productModel';
import Order from '../models/orderModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { sendNotification } from '../utils/notificationUtils';
import { AuthRequest } from '../types';

// @desc    Get full system analytics
// @route   GET /api/v1/admin/analytics
// @access  Private/Admin
export const getSystemAnalytics = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
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
    { $unwind: '$products' },
    {
      $lookup: {
        from: 'products',
        localField: 'products.product',
        foreignField: '_id',
        as: 'productInfo'
      }
    },
    { $unwind: '$productInfo' },
    {
      $group: {
        _id: '$productInfo.category',
        revenue: { $sum: { $multiply: ['$products.price', '$products.quantity'] } }
      }
    },
    { $sort: { revenue: -1 } }
  ]);

  // Helper to ensure continuous 7-day timeline with 0 values for inactive days
  const fill7DayTimeline = (rawStats: any[], defaultFields: Record<string, any> = { count: 0 }) => {
    const map: Record<string, any> = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      map[dateStr] = { _id: dateStr, ...defaultFields };
    }
    for (const stat of rawStats) {
      if (map[stat._id]) {
        map[stat._id] = stat;
      }
    }
    return Object.values(map);
  };

  // Orders per day (last 7 days)
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  
  const rawDailyStats = await Order.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 },
        revenue: {
          $sum: {
            $cond: [{ $eq: ['$orderStatus', 'Delivered'] }, '$totalAmount', 0]
          }
        }
      }
    },
    { $sort: { _id: 1 } }
  ]);
  const dailyStats = fill7DayTimeline(rawDailyStats, { count: 0, revenue: 0 });

  const rawUserDailyStats = await User.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);
  const userDailyStats = fill7DayTimeline(rawUserDailyStats, { count: 0 });

  const rawProductDailyStats = await Product.aggregate([
    { $match: { createdAt: { $gte: sevenDaysAgo } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);
  const productDailyStats = fill7DayTimeline(rawProductDailyStats, { count: 0 });

  const recentOrders = await Order.find()
    .populate('customerId', 'fullName')
    .populate('vendorId', 'shopName fullName')
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

// @desc    Get all users (with search, role filter, pagination)
// @route   GET /api/v1/admin/users
// @access  Private/Admin
export const getAllUsers = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { search, role, page = 1, limit = 20 } = req.query as any;
  const filter: any = {};
  if (role && role !== 'All' && role !== 'all') {
    filter.role = role.toLowerCase();
  }

  const escapeRegex = (string: string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { fullName: { $regex: escapedSearch, $options: 'i' } },
      { email: { $regex: escapedSearch, $options: 'i' } },
      { phone: { $regex: escapedSearch, $options: 'i' } },
      { shopName: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  const pageNum = Math.max(parseInt(page, 10) || 1, 1);
  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
  const skip = (pageNum - 1) * limitNum;

  const [
    totalUsers,
    activeUsers,
    inactiveUsers,
    totalCustomers,
    totalVendors,
    pendingVendors,
    users,
    totalCount
  ] = await Promise.all([
    User.countDocuments(),
    User.countDocuments({ isActive: true }),
    User.countDocuments({ isActive: false }),
    User.countDocuments({ role: 'customer' }),
    User.countDocuments({ role: 'vendor' }),
    User.countDocuments({ role: 'vendor', vendorApprovalStatus: { $in: ['pending', null, undefined] as any } }),
    User.find(filter)
      .select('-password')
      .sort('-createdAt')
      .skip(skip)
      .limit(limitNum),
    User.countDocuments(filter),
  ]);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: pageNum,
    totalPages: Math.ceil(totalCount / limitNum),
    results: users.length,
    data: {
      users,
      stats: {
        totalUsers,
        activeUsers,
        inactiveUsers,
        totalCustomers,
        totalVendors,
        pendingVendors,
      }
    }
  });
});

// @desc    Get all vendors (with search, filter, pagination)
// @route   GET /api/v1/admin/vendors
// @access  Private/Admin
export const getAllVendors = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { search, status, page = 1, limit = 20 } = req.query as any;
  const filter: any = { role: 'vendor' };

  const escapeRegex = (string: string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  if (search) {
    const escapedSearch = escapeRegex(search);
    filter.$or = [
      { fullName: { $regex: escapedSearch, $options: 'i' } },
      { shopName: { $regex: escapedSearch, $options: 'i' } },
      { email: { $regex: escapedSearch, $options: 'i' } }
    ];
  }

  if (status && status !== 'All' && status !== 'all') {
    const statusLower = status.toLowerCase();
    if (statusLower === 'pending') {
      filter.vendorApprovalStatus = { $in: ['pending', null, undefined] };
    } else {
      filter.vendorApprovalStatus = statusLower;
    }
  }

  const pageNum = Math.max(parseInt(page, 10) || 1, 1);
  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
  const skip = (pageNum - 1) * limitNum;

  const [
    totalVendors,
    approvedVendors,
    pendingVendors,
    suspendedVendors,
    vendors,
    totalCount
  ] = await Promise.all([
    User.countDocuments({ role: 'vendor' }),
    User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'approved' }),
    User.countDocuments({ role: 'vendor', vendorApprovalStatus: { $in: ['pending', null, undefined] as any } }),
    User.countDocuments({ role: 'vendor', vendorApprovalStatus: 'suspended' }),
    User.find(filter)
      .select('-password')
      .sort('-createdAt')
      .skip(skip)
      .limit(limitNum),
    User.countDocuments(filter),
  ]);

  const vendorIds = vendors.map(v => v._id);
  const productCounts = await Product.aggregate([
    { $match: { vendorId: { $in: vendorIds } } },
    { $group: { _id: '$vendorId', count: { $sum: 1 } } },
  ]);
  const countMap: Record<string, number> = {};
  for (const pc of productCounts) {
    countMap[pc._id.toString()] = pc.count;
  }
  const vendorsWithCounts = vendors.map(v => ({
    ...(typeof (v as any).toObject === 'function' ? (v as any).toObject() : v),
    productCount: countMap[v._id.toString()] || 0,
  }));

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: pageNum,
    totalPages: Math.ceil(totalCount / limitNum),
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
export const getAllProducts = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { search, category, page = 1, limit = 20 } = req.query as any;
  const filter: any = {};

  const escapeRegex = (string: string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

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

  const pageNum = Math.max(parseInt(page, 10) || 1, 1);
  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);
  const skip = (pageNum - 1) * limitNum;

  const [products, totalCount, totalProducts, availableProducts, unavailableProducts] = await Promise.all([
    Product.find(filter)
      .populate('vendorId', 'fullName shopName')
      .sort('-createdAt')
      .skip(skip)
      .limit(limitNum),
    Product.countDocuments(filter),
    Product.countDocuments(),
    Product.countDocuments({ productStatus: 'Available' }),
    Product.countDocuments({ productStatus: { $in: ['OutOfStock', 'Inactive'] } }),
  ]);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: pageNum,
    totalPages: Math.ceil(totalCount / limitNum),
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
export const getProduct = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
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
export const getAllOrders = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { search, status, page = 1, limit = 10 } = req.query as any;
  const filter: any = {};

  if (status && status !== 'All') {
    filter.orderStatus = status;
  }

  if (search) {
    const escapeRegex = (string: string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
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

  const pageNum = parseInt(page, 10) || 1;
  const limitNum = parseInt(limit, 10) || 10;
  const skip = (pageNum - 1) * limitNum;
  const orders = await Order.find(filter)
    .populate('customerId', 'fullName')
    .populate('vendorId', 'fullName shopName')
    .sort('-createdAt')
    .skip(skip)
    .limit(limitNum);

  const totalCount = await Order.countDocuments(filter);

  res.status(200).json({
    success: true,
    status: 'success',
    totalCount,
    page: pageNum,
    totalPages: Math.ceil(totalCount / limitNum),
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
export const getVendorDetail = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
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
export const updateVendorStatus = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
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
export const toggleUserStatus = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  const reqUserId = req.user?.id || req.user?._id?.toString();
  if (user._id.toString() === reqUserId) {
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
    undefined,
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
export const exportAnalytics = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { format = 'csv', type = 'overview' } = req.query as any;

  // Escape CSV cells: neutralize formula injection and double-quote escaping
  const csvCell = (value: any) => {
    const str = value == null ? 'N/A' : String(value);
    const sanitized = str.replace(/^[=+\-@\t\r]/g, "'");
    return `"${sanitized.replace(/"/g, '""')}"`;
  };

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
      const customer = (order.customerId as any)?.fullName || 'N/A';
      const vendor = (order.vendorId as any)?.shopName || (order.vendorId as any)?.fullName || 'N/A';
      const amount = order.totalAmount || 0;
      const status = order.orderStatus || 'Unknown';
      const date = order.createdAt ? new Date(order.createdAt).toLocaleDateString() : '';
      csvContent += `"#${id}",${csvCell(customer)},${csvCell(vendor)},${amount},${csvCell(status)},${csvCell(date)}\n`;
    }
    filename = 'localtrade-orders';
  } else if (type === 'products') {
    const products = await Product.find()
      .populate('vendorId', 'fullName shopName')
      .sort('-createdAt');

    csvContent = 'Product,Vendor,Category,Price,Stock,Status\n';
    for (const product of products) {
      const vendor = (product.vendorId as any)?.shopName || (product.vendorId as any)?.fullName || 'N/A';
      const status = (product.stockQuantity > 0 && (product.productStatus as any) !== 'Unavailable') ? 'Available' : 'Unavailable';
      csvContent += `${csvCell(product.title)},${csvCell(vendor)},${csvCell(product.category || 'N/A')},${product.price},${product.stockQuantity},${csvCell(status)}\n`;
    }
    filename = 'localtrade-products';
  } else if (type === 'vendors') {
    const vendors = await User.find({ role: 'vendor' }).select('-password').sort('-createdAt');

    csvContent = 'Name,Shop,Email,Status,Joined\n';
    for (const vendor of vendors) {
      const joined = vendor.createdAt ? new Date(vendor.createdAt).toLocaleDateString() : '';
      csvContent += `${csvCell(vendor.fullName)},${csvCell(vendor.shopName || 'N/A')},${csvCell(vendor.email)},${csvCell(vendor.vendorApprovalStatus)},${csvCell(joined)}\n`;
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

export default {
  getSystemAnalytics,
  getAllUsers,
  getAllVendors,
  getAllProducts,
  getProduct,
  getAllOrders,
  getVendorDetail,
  updateVendorStatus,
  toggleUserStatus,
  exportAnalytics,
};
