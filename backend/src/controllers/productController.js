const Product = require('../models/productModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendNotification } = require('../utils/notificationUtils');
const { uploadToCloudinary } = require('../utils/cloudinaryUtils');
const User = require('../models/userModel');
const Order = require('../models/orderModel');

// @desc    Get all products (with search, filter, pagination)
// @route   GET /api/v1/products
// @access  Public
exports.getAllProducts = catchAsync(async (req, res, next) => {
  const escapeRegex = (string) => string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

  // 1) Initialize filter object
  const filter = {};

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
    filter.location = { $regex: escapeRegex(req.query.location), $options: 'i' };
  }

  // 4) Availability Filter (Default: Show only available and in-stock)
  if (req.query.showAll !== 'true') {
    filter.productStatus = 'Available';
    filter.stockQuantity = { $gt: 0 };
  }

  // 5) Search (Title, Description, Category, Vendor Name) - Case-insensitive
  if (req.query.search) {
    const escapedSearch = escapeRegex(req.query.search);
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
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;
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
exports.getProduct = catchAsync(async (req, res, next) => {
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
exports.createProduct = catchAsync(async (req, res, next) => {
  const { title, description, category, price, originalPrice, stock, stockQuantity, priceUnit, minOrder, sizes } = req.body;
  
  const existingProduct = await Product.findOne({ vendorId: req.user.id, title: title.trim() });
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
  if (resolvedStock < 0) {
    return next(new AppError('Stock quantity cannot be negative', 400));
  }

  const productData = {
    title,
    description,
    category,
    price: Number(price),
    priceUnit: priceUnit || 'piece',
    minOrder: minOrder ? Number(minOrder) : 1,
    originalPrice: originalPrice ? Number(originalPrice) : null,
    stockQuantity: resolvedStock,
    sizes: sizes || [],
    vendorId: req.user.id,
    vendorName: req.user.shopName || req.user.fullName,
    location: req.user.address
      ? [req.user.address.street, req.user.address.city, req.user.address.state].filter(Boolean).join(', ')
      : ''
  };

  // Handle Image Uploads
  if (req.files && req.files.length > 0) {
    const uploadPromises = req.files.map(file => uploadToCloudinary(file.buffer, 'localtrade/products'));
    productData.images = await Promise.all(uploadPromises);
  } else if (req.body.images) {
    productData.images = Array.isArray(req.body.images) ? req.body.images : [req.body.images];
  }

  const product = await Product.create(productData);

  // Send promotional notification to all customers
  try {
    const customers = await User.find({ role: 'customer' }).select('_id');
    if (customers.length > 0) {
      const shopName = req.user.shopName || req.user.fullName;
      const notificationPromises = customers.map(customer =>
        sendNotification(
          customer._id,
          'New product listed',
          `${shopName} added "${title}" in ${category || 'Local Goods'}.`,
          { productId: product._id.toString(), type: 'new_product' },
          'Promotional'
        )
      );
      await Promise.all(notificationPromises);
    }
  } catch (err) {
    console.error('Promotional notification error:', err.message);
  }

  res.status(201).json({
    success: true,
    status: 'success',
    data: { product },
  });
});

// @desc    Update product
// @route   PATCH /api/v1/products/:id
// @access  Private/Vendor
exports.updateProduct = catchAsync(async (req, res, next) => {
  let product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  // Check if product belongs to vendor
  if (product.vendorId.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new AppError('You are not authorized to update this product', 403));
  }

  const { title, description, category, price, originalPrice, stock, stockQuantity, productStatus, priceUnit, minOrder, sizes } = req.body;
  const updateData = {};
  
  if (title !== undefined) updateData.title = title;
  if (description !== undefined) updateData.description = description;
  if (category !== undefined) updateData.category = category;
  if (price !== undefined) updateData.price = Number(price);
  if (priceUnit !== undefined) updateData.priceUnit = priceUnit;
  if (minOrder !== undefined) updateData.minOrder = Number(minOrder);
  if (sizes !== undefined) updateData.sizes = sizes;
  if (originalPrice !== undefined) updateData.originalPrice = originalPrice ? Number(originalPrice) : null;
  if (productStatus !== undefined) updateData.productStatus = productStatus;
  
  if (stockQuantity !== undefined) {
    updateData.stockQuantity = Number(stockQuantity);
  } else if (stock !== undefined) {
    updateData.stockQuantity = Number(stock);
  }

  if (req.files && req.files.length > 0) {
    const uploadPromises = req.files.map(file => uploadToCloudinary(file.buffer, 'localtrade/products'));
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
exports.updateProductStock = catchAsync(async (req, res, next) => {
  const { stockQuantity, productStatus } = req.body;

  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  if (product.vendorId.toString() !== req.user.id && req.user.role !== 'admin') {
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
exports.deleteProduct = catchAsync(async (req, res, next) => {
  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  // Check ownership or admin
  if (product.vendorId.toString() !== req.user.id && req.user.role !== 'admin') {
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
exports.checkProductDeletable = catchAsync(async (req, res, next) => {
  const product = await Product.findById(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  // Check ownership
  if (product.vendorId.toString() !== req.user.id && req.user.role !== 'admin') {
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
exports.getMyProducts = catchAsync(async (req, res, next) => {
  const filter = { vendorId: req.user.id };

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip = (page - 1) * limit;

    const [products, totalResults] = await Promise.all([
      Product.find(filter).sort('-createdAt').skip(skip).limit(limit),
      Product.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      status: 'success',
      results: products.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      data: { products },
    });
  }

  const products = await Product.find(filter).sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: products.length,
    data: { products },
  });
});
