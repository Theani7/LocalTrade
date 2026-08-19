import { Response, NextFunction } from 'express';
import Product from '../models/productModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import notificationUtils from '../utils/notificationUtils';
import { uploadToCloudinary } from '../utils/cloudinaryUtils';
import User from '../models/userModel';
import Order from '../models/orderModel';
import Review from '../models/reviewModel';
import { AuthRequest } from '../types';

// @desc    Get all products (with search, filter, pagination)
// @route   GET /api/v1/products
// @access  Public
export const getAllProducts = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const escapeRegex = (string: string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  // 1) Initialize filter object
  const filter: any = {};

  // Vendor Filter
  if (req.query.vendorId) {
    filter.vendorId = req.query.vendorId;
  }

  // 2) Category Filter
  if (req.query.category && req.query.category !== 'All') {
    filter.category = req.query.category;
  }

  // 3) Location Filter (Area/Address)
  if (req.query.location) {
    filter.location = { $regex: escapeRegex(req.query.location as string), $options: 'i' };
  }

  // 4) Availability Filter (Default: Show only available and in-stock)
  if (req.query.showAll !== 'true') {
    filter.productStatus = 'Available';
    filter.stockQuantity = { $gt: 0 };
  }

  // 5) Search (Title, Description, Category, Vendor Name) - Case-insensitive
  if (req.query.search) {
    const escapedSearch = escapeRegex(req.query.search as string);
    const searchRegex = { $regex: escapedSearch, $options: 'i' };
    filter.$or = [
      { title: searchRegex },
      { description: searchRegex },
      { category: searchRegex },
      { vendorName: searchRegex },
    ];
  }

  // 6) Sorting
  let sortBy = '-createdAt'; // Default
  if (req.query.sort) {
    switch (req.query.sort) {
      case 'price_low':
        sortBy = 'price';
        break;
      case 'price_high':
        sortBy = '-price';
        break;
      case 'newest':
        sortBy = '-createdAt';
        break;
      case 'availability':
        sortBy = '-productStatus -stockQuantity -createdAt';
        break;
      default:
        sortBy = '-createdAt';
    }
  }

  // 7) Pagination
  const page = Math.max(parseInt(req.query.page as string, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit as string, 10) || 10, 1), 100);
  const skip = (page - 1) * limit;

  // Execute query and count in parallel
  const [products, totalCount] = await Promise.all([
    Product.find(filter)
      .sort(sortBy)
      .skip(skip)
      .limit(limit)
      .populate('vendorId', 'fullName shopName address profileImage'),
    Product.countDocuments(filter),
  ]);

  res.status(200).json({
    success: true,
    status: 'success',
    results: products.length,
    totalCount,
    page,
    totalPages: Math.ceil(totalCount / limit),
    data: { products },
  });
});

// @desc    Get single product
// @route   GET /api/v1/products/:id
// @access  Public
export const getProduct = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const product = await Product.findById(req.params.id).populate('vendorId', 'fullName shopName phone address profileImage');

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { product },
  });
});

// @desc    Create new product
// @route   POST /api/v1/products
// @access  Private/Vendor
export const createProduct = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { title, description, category, price, originalPrice, stock, stockQuantity, priceUnit, minOrder, sizes } = req.body;

  if (!title || !title.trim()) {
    return next(new AppError('Product title is required', 400));
  }

  const userId = req.user?.id || req.user?._id?.toString();
  const existingProduct = await Product.findOne({
    vendorId: userId,
    title: { $regex: `^${title.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, $options: 'i' },
  });
  if (existingProduct) {
    return next(new AppError('You already have a product with this title', 400));
  }
  
  const priceNum = Number(price);
  if (isNaN(priceNum) || priceNum <= 0) {
    return next(new AppError('Price must be a positive number', 400));
  }
  if (originalPrice) {
    const origNum = Number(originalPrice);
    if (isNaN(origNum) || origNum <= 0) {
      return next(new AppError('Original price must be a positive number', 400));
    }
  }

  const resolvedStock = stockQuantity !== undefined ? Number(stockQuantity) : (stock !== undefined ? Number(stock) : 0);
  if (isNaN(resolvedStock) || resolvedStock < 0) {
    return next(new AppError('Stock quantity must be a non-negative number', 400));
  }

  const parsedSizes = Array.isArray(sizes) ? sizes : (typeof sizes === 'string' ? JSON.parse(sizes) : []);
  const resolvedMinOrder = minOrder !== undefined && minOrder !== '' ? Number(minOrder) : 1;
  if (isNaN(resolvedMinOrder) || resolvedMinOrder <= 0) {
    return next(new AppError('Minimum order must be a positive number', 400));
  }

  const productData: any = {
    title: title.trim(),
    description,
    category,
    price: priceNum,
    priceUnit: priceUnit || 'piece',
    minOrder: resolvedMinOrder,
    originalPrice: originalPrice ? Number(originalPrice) : null,
    stockQuantity: resolvedStock,
    sizes: parsedSizes,
    vendorId: userId,
    vendorName: req.user?.shopName || req.user?.fullName,
    location: req.user?.address
      ? [req.user.address.street, req.user.address.city, req.user.address.state].filter(Boolean).join(', ')
      : ''
  };

  // Handle Image Uploads
  const files = req.files as Express.Multer.File[];
  if (files && Array.isArray(files) && files.length > 0) {
    const uploadPromises = files.map((file) => uploadToCloudinary(file.buffer, 'localtrade/products'));
    productData.images = await Promise.all(uploadPromises);
  } else if (req.body.images) {
    productData.images = Array.isArray(req.body.images) ? req.body.images : [req.body.images];
  }

  const product = await Product.create(productData);

  // Send promotional notification to all customers (fire-and-forget, never blocks response)
  notificationUtils
    .allCustomers(
      'New product listed',
      `${req.user?.shopName || req.user?.fullName} added "${title}" in ${category || 'Local Goods'}.`,
      { productId: product._id.toString(), type: 'new_product' }
    )
    .catch((err: any) => console.error('Promotional notification error:', err.message));

  res.status(201).json({
    success: true,
    status: 'success',
    data: { product },
  });
});

// @desc    Update product
// @route   PATCH /api/v1/products/:id
// @access  Private/Vendor
export const updateProduct = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  let product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  // Check if product belongs to vendor
  if (product.vendorId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You are not authorized to update this product', 403));
  }

  const { title, description, category, price, originalPrice, stock, stockQuantity, productStatus, priceUnit, minOrder, sizes } = req.body;
  const updateData: any = {};
  
  if (title !== undefined) {
    if (!title.trim()) return next(new AppError('Product title is required', 400));
    updateData.title = title.trim();
  }
  if (description !== undefined) updateData.description = description;
  if (category !== undefined) updateData.category = category;
  if (price !== undefined) {
    const priceNum = Number(price);
    if (isNaN(priceNum) || priceNum <= 0) {
      return next(new AppError('Price must be a positive number', 400));
    }
    updateData.price = priceNum;
  }
  if (priceUnit !== undefined) updateData.priceUnit = priceUnit;
  if (minOrder !== undefined && minOrder !== '') {
    const minNum = Number(minOrder);
    if (isNaN(minNum) || minNum <= 0) {
      return next(new AppError('Minimum order must be a positive number', 400));
    }
    updateData.minOrder = minNum;
  }
  if (sizes !== undefined) {
    updateData.sizes = Array.isArray(sizes) ? sizes : (typeof sizes === 'string' ? JSON.parse(sizes) : []);
  }
  if (originalPrice !== undefined) {
    const origNum = originalPrice ? Number(originalPrice) : null;
    if (origNum !== null && (isNaN(origNum) || origNum <= 0)) {
      return next(new AppError('Original price must be a positive number', 400));
    }
    updateData.originalPrice = origNum;
  }
  if (productStatus !== undefined) updateData.productStatus = productStatus;
  
  if (stockQuantity !== undefined) {
    const stockNum = Number(stockQuantity);
    if (isNaN(stockNum) || stockNum < 0) {
      return next(new AppError('Stock quantity must be a non-negative number', 400));
    }
    updateData.stockQuantity = stockNum;
  } else if (stock !== undefined) {
    const stockNum = Number(stock);
    if (isNaN(stockNum) || stockNum < 0) {
      return next(new AppError('Stock quantity must be a non-negative number', 400));
    }
    updateData.stockQuantity = stockNum;
  }

  const files = req.files as Express.Multer.File[];
  if (files && Array.isArray(files) && files.length > 0) {
    const uploadPromises = files.map((file) => uploadToCloudinary(file.buffer, 'localtrade/products'));
    updateData.images = await Promise.all(uploadPromises);
  }

  product = await Product.findByIdAndUpdate(req.params.id, updateData, {
    new: true,
    runValidators: true,
  });

  res.status(200).json({
    success: true,
    status: 'success',
    data: { product },
  });
});

// @desc    Update product stock quickly
// @route   PATCH /api/v1/products/:id/stock
// @access  Private/Vendor
export const updateProductStock = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { stockQuantity, productStatus } = req.body;

  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  if (product.vendorId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('Unauthorized', 403));
  }

  if (stockQuantity !== undefined) {
    if (stockQuantity < 0) {
      return next(new AppError('Stock quantity cannot be negative', 400));
    }
    product.stockQuantity = stockQuantity;
  }
  if (productStatus !== undefined) product.productStatus = productStatus;

  await product.save();

  res.status(200).json({
    success: true,
    status: 'success',
    data: { product },
  });
});

// @desc    Delete product
// @route   DELETE /api/v1/products/:id
// @access  Private/Vendor/Admin
export const deleteProduct = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  // Check ownership or admin
  if (product.vendorId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You are not authorized to delete this product', 403));
  }

  // Check if product is referenced in any active orders
  const activeOrder = await Order.findOne({
    'products.product': req.params.id,
    orderStatus: { $nin: ['Delivered', 'Cancelled'] }
  });
  if (activeOrder) {
    return next(new AppError('Cannot delete product that has active orders', 400));
  }

  await Product.findByIdAndDelete(req.params.id);

  res.status(204).json({
    success: true,
    status: 'success',
    data: null,
  });
});

// @desc    Check if product can be deleted
// @route   GET /api/v1/products/:id/deletable
// @access  Private/Vendor
export const checkProductDeletable = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  // Check ownership
  if (product.vendorId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You are not authorized to delete this product', 403));
  }

  // Check for active orders
  const activeOrder = await Order.findOne({
    'products.product': req.params.id,
    orderStatus: { $nin: ['Delivered', 'Cancelled'] }
  });

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      canDelete: !activeOrder,
      reason: activeOrder ? 'Product has active orders' : null,
    },
  });
});

// @desc    Get vendor products
// @route   GET /api/v1/products/my-products
// @access  Private/Vendor
export const getMyProducts = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const filter = { vendorId: userId };

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const [products, totalResults] = await Promise.all([
      Product.find(filter).sort('-createdAt').skip(skip).limit(limit),
      Product.countDocuments(filter),
    ]);

    res.status(200).json({
      success: true,
      status: 'success',
      results: products.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      data: { products },
    });
    return;
  }

  const products = await Product.find(filter).sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: products.length,
    data: { products },
  });
});

// @desc    Get public vendor profile
// @route   GET /api/v1/vendors/:id/profile
// @access  Public
export const getVendorProfile = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const vendor = await User.findById(req.params.id).select('fullName shopName businessDescription categories address phone profileImage');

  if (!vendor || vendor.role !== 'vendor') {
    return next(new AppError('No vendor found with that ID', 404));
  }

  const vendorId = vendor._id;

  const products = await Product.find({ vendorId, productStatus: 'Available' }).select('title price images stockQuantity ratingsAverage');
  const productIds = products.map((p) => p._id);

  const reviewStats = await Review.aggregate([
    { $match: { productId: { $in: productIds } } },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
      },
    },
  ]);

  const reviews = await Review.find({ productId: { $in: productIds } })
    .populate('userId', 'fullName profileImage')
    .sort('-createdAt')
    .limit(5);

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      vendor: {
        id: vendor._id,
        fullName: vendor.fullName,
        shopName: vendor.shopName,
        shopDescription: vendor.businessDescription,
        categories: vendor.categories,
        address: vendor.address,
        phone: vendor.phone,
        profileImage: vendor.profileImage,
      },
      products: products,
      stats: {
        totalProducts: products.length,
        averageRating: reviewStats[0]?.averageRating || 0,
        totalReviews: reviewStats[0]?.totalReviews || 0,
      },
      recentReviews: reviews,
    },
  });
});

export default {
  getAllProducts,
  getProduct,
  createProduct,
  updateProduct,
  updateProductStock,
  deleteProduct,
  checkProductDeletable,
  getMyProducts,
  getVendorProfile,
};
