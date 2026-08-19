import { Response, NextFunction } from 'express';
import Order from '../models/orderModel';
import Product from '../models/productModel';
import User from '../models/userModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { sendNotification } from '../utils/notificationUtils';
import { AuthRequest } from '../types';

// @desc    Create new order
// @route   POST /api/v1/orders
// @access  Private/Customer
export const createOrder = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  // Support both 'items' and 'products' keys for backward compatibility
  const items = req.body.items || req.body.products;

  if (process.env.NODE_ENV === 'development') {
    console.log('Order Payload Received:', JSON.stringify(req.body, null, 2));
  }

  if (!items || items.length === 0) {
    return next(new AppError('No order items provided. Expected "items" or "products" array.', 400));
  }

  const WEIGHT_UNITS = ['kg', '100g', 'liter'];

  // Validate all quantities are positive and unit-appropriate
  for (const item of items) {
    if (!item.quantity || item.quantity <= 0) {
      return next(new AppError('Each item quantity must be greater than zero', 400));
    }
    if (!Number.isFinite(Number(item.quantity))) {
      return next(new AppError('Each item quantity must be a number', 400));
    }
  }

  // Validate all products are from the same vendor
  const vendorIds = new Set<string>();
  const productsById = new Map<string, any>();
  for (const item of items) {
    const productId = item.productId || item.product;
    if (!productId) {
      return next(new AppError('Invalid item format: Missing product ID', 400));
    }
    const product = await Product.findById(productId);
    if (!product) {
      return next(new AppError(`Product ${productId} not found`, 404));
    }
    productsById.set(productId, product);
    vendorIds.add(product.vendorId.toString());
  }
  if (vendorIds.size > 1) {
    return next(new AppError('All products in an order must be from the same vendor', 400));
  }

  // Ensure the selling vendor is approved and active
  const sellingVendor = await User.findById([...vendorIds][0]).select('vendorApprovalStatus isActive');
  if (!sellingVendor || sellingVendor.vendorApprovalStatus !== 'approved' || sellingVendor.isActive === false) {
    return next(new AppError('The vendor for these products is currently unavailable.', 400));
  }

  // Validate quantity steps and minOrder against the DB product
  for (const item of items) {
    const productId = item.productId || item.product;
    const product = productsById.get(productId);
    const quantity = item.quantity;
    const stepOk = WEIGHT_UNITS.includes(product.priceUnit)
      ? Math.abs(quantity * 10 - Math.round(quantity * 10)) < 1e-9
      : Number.isInteger(quantity);
    if (!stepOk) {
      return next(new AppError(
        `Quantity for "${product.title}" must be a ${WEIGHT_UNITS.includes(product.priceUnit) ? 'multiple of 0.1 (weight unit)' : 'whole number'}`,
        400
      ));
    }
    const minOrder = product.minOrder || 1;
    if (quantity < minOrder) {
      return next(new AppError(`Minimum order for "${product.title}" is ${minOrder} ${product.priceUnit}`, 400));
    }
  }

  // 1) Process each item
  let totalAmount = 0;
  const orderProducts: any[] = [];
  const processedProducts: { id: string; quantity: number }[] = [];
  let vendorId: any = null;

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

      // Auto-update status if stock hits zero
      if (updatedProduct.stockQuantity === 0) {
        updatedProduct.productStatus = 'OutOfStock';
        await updatedProduct.save();
      }

      totalAmount += updatedProduct.price * item.quantity;
      orderProducts.push({
        product: productId,
        quantity: item.quantity,
        price: updatedProduct.price,
        priceUnit: updatedProduct.priceUnit || 'piece',
        size: item.size || null,
      });
    }

    // 2) Create order record — vendorId derived from product, not from client request
    const customerId = req.user?.id || req.user?._id?.toString();
    const order = await Order.create({
      customerId,
      vendorId,
      products: orderProducts,
      totalAmount: totalAmount, // ALWAYS use server-calculated total
      shippingAddress: req.body.shippingAddress,
      notes: req.body.notes
    });

    // 4) Send notification to vendor
    await sendNotification(
      order.vendorId,
      'New order received',
      `Order #${order._id.toString().substring(18)} for Rs. ${totalAmount}. Please review and confirm.`,
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
        await Product.findOneAndUpdate(
          { _id: processed.id },
          {
            $inc: { stockQuantity: processed.quantity },
            ...(processed.quantity > 0 ? { productStatus: 'Available' } : {}),
          },
          { new: true }
        );
      } catch (rollbackErr: any) {
        console.error('Failed to rollback stock for product:', processed.id, rollbackErr);
      }
    }
    return next(error);
  }
});

// @desc    Get order details
// @route   GET /api/v1/orders/:id
// @access  Private
export const getOrder = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const order = await Order.findById(req.params.id)
    .populate('customerId', 'fullName phone email')
    .populate('vendorId', 'fullName shopName phone address')
    .populate('products.product', 'title images stockQuantity');

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();
  const orderCustomerId = ((order.customerId as any)?._id?.toString() || order.customerId?.toString() || '');
  const orderVendorId = ((order.vendorId as any)?._id?.toString() || order.vendorId?.toString() || '');

  // Authorization: customer, vendor, or admin may access.
  if (
    orderCustomerId !== reqUserId &&
    orderVendorId !== reqUserId &&
    req.user?.role !== 'admin'
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
export const getMyOrders = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const filter = { customerId: userId };

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const [orders, totalResults] = await Promise.all([
      Order.find(filter)
        .populate('vendorId', 'shopName fullName')
        .populate('products.product', 'title images stockQuantity')
        .sort('-createdAt')
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);

    res.status(200).json({
      success: true,
      status: 'success',
      results: orders.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      data: { orders },
    });
    return;
  }

  const orders = await Order.find(filter)
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
export const getVendorOrders = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const userId = req.user?.id || req.user?._id?.toString();
  const filter = { vendorId: userId };

  if (req.query.page || req.query.limit) {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const [orders, totalResults] = await Promise.all([
      Order.find(filter)
        .populate('customerId', 'fullName phone')
        .populate('products.product', 'title images stockQuantity')
        .sort('-createdAt')
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);

    res.status(200).json({
      success: true,
      status: 'success',
      results: orders.length,
      totalPages: Math.ceil(totalResults / limit),
      currentPage: page,
      totalResults,
      data: { orders },
    });
    return;
  }

  const orders = await Order.find(filter)
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

// @desc    Cancel/Reject order (Customer/Vendor/Admin)
// @route   PATCH /api/v1/orders/:id/cancel
// @access  Private
export const cancelOrder = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const order = await Order.findById(req.params.id);

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();
  const isCustomer = order.customerId.toString() === reqUserId;
  const isVendor = order.vendorId.toString() === reqUserId;
  const isAdmin = req.user?.role === 'admin';

  // Only customer, vendor, or admin can cancel
  if (!isCustomer && !isVendor && !isAdmin) {
    return next(new AppError('You are not authorized to cancel this order', 403));
  }

  // Cannot cancel already delivered or cancelled order
  if (order.orderStatus === 'Delivered' || order.orderStatus === 'Cancelled') {
    return next(new AppError('Cannot cancel a delivered or already cancelled order', 400));
  }

  // Customer can only cancel Pending orders
  if (isCustomer && !isAdmin && order.orderStatus !== 'Pending') {
    return next(new AppError('Order cannot be cancelled after confirmation', 400));
  }

  const updatedOrder = await Order.findByIdAndUpdate(
    req.params.id,
    {
      orderStatus: 'Cancelled',
      cancellationReason: req.body.reason || (isVendor ? 'Rejected by vendor' : undefined),
      cancellationFeedback: req.body.feedback || undefined,
    },
    { new: true, runValidators: false }
  )
    .populate('customerId', 'fullName phone')
    .populate('vendorId', 'shopName')
    .populate('products.product', 'title images');

  // Rollback stock for all products in this order
  for (const item of order.products) {
    try {
      const productId = typeof item.product === 'object' && (item.product as any)._id
        ? (item.product as any)._id
        : item.product;
      await Product.findOneAndUpdate(
        { _id: productId },
        {
          $inc: { stockQuantity: item.quantity },
          productStatus: 'Available',
        },
        { new: true }
      );
    } catch (err: any) {
      console.error('Failed to restore stock on cancel:', item.product, err);
    }
  }

  // Send appropriate notifications
  if (isCustomer) {
    await sendNotification(
      order.vendorId,
      'Order cancelled by customer',
      `Order #${order._id.toString().substring(18)} was cancelled by the customer. Stock has been restored.`,
      { orderId: order._id.toString(), type: 'order_cancelled' },
      'Order'
    );
  } else if (isVendor) {
    await sendNotification(
      order.customerId,
      'Order rejected by vendor',
      `Your order #${order._id.toString().substring(18)} was rejected by the vendor.`,
      { orderId: order._id.toString(), type: 'order_cancelled' },
      'Order'
    );
  } else {
    // Admin cancelled - notify both
    await sendNotification(
      order.customerId,
      'Order cancelled by admin',
      `Your order #${order._id.toString().substring(18)} was cancelled by support.`,
      { orderId: order._id.toString(), type: 'order_cancelled' },
      'Order'
    );
    await sendNotification(
      order.vendorId,
      'Order cancelled by admin',
      `Order #${order._id.toString().substring(18)} was cancelled by support. Stock has been restored.`,
      { orderId: order._id.toString(), type: 'order_cancelled' },
      'Order'
    );
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { order: updatedOrder },
  });
});

// @desc    Update order status
// @route   PATCH /api/v1/orders/:id/status
// @access  Private/Vendor/Admin
export const updateOrderStatus = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { status } = req.body;
  const order = await Order.findById(req.params.id);

  if (!order) {
    return next(new AppError('No order found with that ID', 404));
  }

  const reqUserId = (req.user?.id || req.user?._id?.toString() || '').toString();

  // Only vendor or admin can update status
  if (order.vendorId.toString() !== reqUserId && req.user?.role !== 'admin') {
    return next(new AppError('You are not authorized to update this order', 403));
  }

  // Status transition validation
  if (order.orderStatus === 'Delivered' || order.orderStatus === 'Cancelled') {
    return next(new AppError('Cannot update status of a delivered or cancelled order', 400));
  }

  if (status === 'Pending') {
    return next(new AppError('Cannot revert status back to Pending', 400));
  }

  if (status === 'Cancelled') {
    // If status is updated to Cancelled, perform full cancellation and stock rollback
    return cancelOrder(req, res, next);
  }

  const statusValues = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered'];
  if (!statusValues.includes(status)) {
    return next(new AppError(`Invalid status: ${status}`, 400));
  }
  const currentIndex = statusValues.indexOf(order.orderStatus);
  const targetIndex = statusValues.indexOf(status);

  if (targetIndex <= currentIndex) {
    return next(new AppError(`Cannot revert order status from "${order.orderStatus}" to "${status}"`, 400));
  }

  order.orderStatus = status;
  const updatedOrder = await Order.findByIdAndUpdate(req.params.id, { orderStatus: status }, { new: true, runValidators: false })
    .populate('customerId', 'fullName phone')
    .populate('vendorId', 'shopName')
    .populate('products.product', 'title images');

  // Send notification to customer
  await sendNotification(
    order.customerId,
    `Order ${status.toLowerCase()}`,
    `Your order #${order._id.toString().substring(18)} is now ${status.toLowerCase()}.`,
    { orderId: order._id.toString(), type: 'order_update' },
    'Order'
  );

  res.status(200).json({
    success: true,
    status: 'success',
    data: { order: updatedOrder },
  });
});

export default {
  createOrder,
  getOrder,
  getMyOrders,
  getVendorOrders,
  updateOrderStatus,
  cancelOrder,
};
