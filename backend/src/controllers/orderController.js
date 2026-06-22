const Order = require('../models/orderModel');
const Product = require('../models/productModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendNotification } = require('../utils/notificationUtils');

// @desc    Create new order
// @route   POST /api/v1/orders
// @access  Private/Customer
exports.createOrder = catchAsync(async (req, res, next) => {
  // Support both 'items' and 'products' keys for backward compatibility
  const items = req.body.items || req.body.products;

  if (process.env.NODE_ENV === 'development') {
    console.log('Order Payload Received:', JSON.stringify(req.body, null, 2));
  }

  if (!items || items.length === 0) {
    return next(new AppError('No order items provided. Expected "items" or "products" array.', 400));
  }

  // 1) Process each item
  let totalAmount = 0;
  const orderProducts = [];
  const processedProducts = [];
  let vendorId = null;

  try {
    for (const item of items) {
      const productId = item.productId || item.product;
      
      if (!productId) {
        throw new AppError('Invalid item format: Missing product ID', 400);
      }

      // ATOMIC STOCK REDUCTION & AVAILABILITY CHECK
      // This query ensures:
      // 1. Product exists
      // 2. Product is 'Available' (status check)
      // 3. Current stock is >= requested quantity
      const updatedProduct = await Product.findOneAndUpdate(
        { 
          _id: productId, 
          productStatus: 'Available',
          stockQuantity: { $gte: item.quantity } 
        },
        { 
          $inc: { stockQuantity: -item.quantity } 
        },
        { new: true, runValidators: true }
      );

      if (!updatedProduct) {
        throw new AppError(`Product "${productId}" is unavailable or has insufficient stock.`, 400);
      }

      processedProducts.push({ id: productId, quantity: item.quantity });

      // Capture vendorId from the product (server-side, not from client)
      if (!vendorId) vendorId = updatedProduct.vendorId;

      // Auto-update status if stock hits zero (The model pre-save middleware will also handle this, 
      // but findOneAndUpdate doesn't always trigger pre-save unless explicitly handled or saved again)
      if (updatedProduct.stockQuantity === 0) {
        updatedProduct.productStatus = 'OutOfStock';
        await updatedProduct.save(); // Trigger model middleware for consistency
      }

      totalAmount += updatedProduct.price * item.quantity;
      orderProducts.push({
        product: productId,
        quantity: item.quantity,
        price: updatedProduct.price,
      });
    }

    // 2) Create order record — vendorId derived from product, not from client request
    const order = await Order.create({
      customerId: req.user.id,
      vendorId,
      products: orderProducts,
      totalAmount: totalAmount, // ALWAYS use server-calculated total
      shippingAddress: req.body.shippingAddress,
      phone: req.body.phone || req.user.phone,
      notes: req.body.notes
    });

    // 4) Send notification to vendor
    await sendNotification(
      order.vendorId,
      'New Order Received!',
      `You have a new order (#${order._id.toString().substring(18)}) for Rs. ${totalAmount}`,
      { orderId: order._id.toString(), type: 'new_order' },
      'Order'
    );

    res.status(201).json({
      success: true,
      status: 'success',
      data: { order },
    });
  } catch (error) {
    // ROLLBACK STOCK FOR PROCESSED ITEMS
    for (const processed of processedProducts) {
      try {
        const prod = await Product.findById(processed.id);
        if (prod) {
          prod.stockQuantity += processed.quantity;
          await prod.save();
        }
      } catch (rollbackErr) {
        console.error('Failed to rollback stock for product:', processed.id, rollbackErr);
      }
    }
    return next(error);
  }
});

// @desc    Get order details
// @route   GET /api/v1/orders/:id
// @access  Private
exports.getOrder = catchAsync(async (req, res, next) => {
  const order = await Order.findById(req.params.id)
    .populate('customerId', 'fullName phone email')
    .populate('vendorId', 'fullName shopName phone address')
    .populate('products.product', 'title images stockQuantity');

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  // Check if authorized
  if (
    order.customerId._id.toString() !== req.user.id &&
    order.vendorId._id.toString() !== req.user.id &&
    req.user.role !== 'admin'
  ) {
    return next(new AppError('You are not authorized to view this order', 403));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { order },
  });
});

// @desc    Get my orders (Customer)
// @route   GET /api/v1/orders/my-orders
// @access  Private/Customer
exports.getMyOrders = catchAsync(async (req, res, next) => {
  const orders = await Order.find({ customerId: req.user.id })
    .populate('vendorId', 'shopName fullName')
    .populate('products.product', 'title images stockQuantity')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: orders.length,
    data: { orders },
  });
});

// @desc    Get vendor orders
exports.getVendorOrders = catchAsync(async (req, res, next) => {
  const orders = await Order.find({ vendorId: req.user.id })
    .populate('customerId', 'fullName phone')
    .populate('products.product', 'title images stockQuantity')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    status: 'success',
    results: orders.length,
    data: { orders },
  });
});

// @desc    Update order status
// @route   PATCH /api/v1/orders/:id/status
// @access  Private/Vendor/Admin
exports.updateOrderStatus = catchAsync(async (req, res, next) => {
  const { status } = req.body;
  const order = await Order.findById(req.params.id);

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  // Only vendor or admin can update status
  if (order.vendorId.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new AppError('You are not authorized to update this order', 403));
  }

  // Status transition validation
  if (order.orderStatus === 'Delivered' || order.orderStatus === 'Cancelled') {
    return next(new AppError('Cannot update status of a delivered or cancelled order', 400));
  }

  if (status === 'Pending') {
    return next(new AppError('Cannot revert status back to Pending', 400));
  }

  const statusValues = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
  const currentIndex = statusValues.indexOf(order.orderStatus);
  const targetIndex = statusValues.indexOf(status);

  if (status !== 'Cancelled' && targetIndex <= currentIndex) {
    return next(new AppError(`Cannot revert order status from "${order.orderStatus}" to "${status}"`, 400));
  }

  order.orderStatus = status;
  await Order.findByIdAndUpdate(req.params.id, { orderStatus: status }, { new: true, runValidators: false });

  // Send notification to customer
  await sendNotification(
    order.customerId,
    'Order Status Updated',
    `Your order (#${order._id.toString().substring(18)}) is now ${status}.`,
    { orderId: order._id.toString(), type: 'order_update' },
    'Order'
  );

  res.status(200).json({
    success: true,
    status: 'success',
    data: { order },
  });
});

// @desc    Cancel order (Customer/Admin)
// @route   PATCH /api/v1/orders/:id/cancel
// @access  Private
exports.cancelOrder = catchAsync(async (req, res, next) => {
  const order = await Order.findById(req.params.id);

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  // Only customer or admin can cancel
  if (order.customerId.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new AppError('You are not authorized to cancel this order', 403));
  }

  // Customer can only cancel Pending orders
  if (order.orderStatus !== 'Pending' && req.user.role !== 'admin') {
    return next(new AppError('Order cannot be cancelled after confirmation', 400));
  }

  order.orderStatus = 'Cancelled';
  order.cancellationReason = req.body.reason || undefined;
  order.cancellationFeedback = req.body.feedback || undefined;
  await Order.findByIdAndUpdate(
    req.params.id,
    {
      orderStatus: 'Cancelled',
      cancellationReason: req.body.reason || undefined,
      cancellationFeedback: req.body.feedback || undefined,
    },
    { new: true, runValidators: false }
  );

  // Rollback stock for all products in this order
  for (const item of order.products) {
    try {
      const prod = await Product.findById(item.product);
      if (prod) {
        prod.stockQuantity += item.quantity;
        await prod.save();
      }
    } catch (err) {
      console.error('Failed to restore stock on cancel:', item.product, err);
    }
  }

  // Send notification to vendor
  await sendNotification(
    order.vendorId,
    'Order Cancelled',
    `Order (#${order._id.toString().substring(18)}) was cancelled by the customer.`,
    { orderId: order._id.toString(), type: 'order_cancelled' },
    'Order'
  );

  res.status(200).json({
    success: true,
    status: 'success',
    data: { order },
  });
});
