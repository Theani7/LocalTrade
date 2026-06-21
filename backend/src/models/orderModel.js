const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: [true, 'Order must belong to a customer'],
    },
    vendorId: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: [true, 'Order must belong to a vendor'],
    },
    products: [
      {
        product: {
          type: mongoose.Schema.ObjectId,
          ref: 'Product',
          required: [true, 'Order must contain products'],
        },
        quantity: {
          type: Number,
          required: [true, 'Product must have a quantity'],
          default: 1,
        },
        price: {
          type: Number,
          required: [true, 'Product must have a price at time of order'],
        },
      },
    ],
    totalAmount: {
      type: Number,
      required: [true, 'Order must have a total amount'],
    },
    orderStatus: {
      type: String,
      enum: ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'],
      default: 'Pending',
    },
    shippingAddress: {
      type: {
        fullName: { type: String, required: true },
        phone: { type: String, required: true },
        flatHouse: { type: String },
        street: { type: String },
        landmark: { type: String },
        city: { type: String, required: true },
        state: { type: String, required: true },
        zipCode: { type: String, required: true },
      },
      required: [true, 'Order must have a shipping address'],
    },
    notes: String,
  },
  {
    timestamps: true,
  }
);

// Indexes for better performance
orderSchema.index({ customerId: 1 });
orderSchema.index({ vendorId: 1 });
orderSchema.index({ orderStatus: 1 });

const Order = mongoose.model('Order', orderSchema);

module.exports = Order;
