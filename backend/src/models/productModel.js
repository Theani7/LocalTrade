const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'A product must have a title'],
      trim: true,
      maxlength: [100, 'A product title must have less or equal than 100 characters'],
    },
    description: {
      type: String,
      required: [true, 'A product must have a description'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'A product must have a category'],
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'A product must have a price'],
    },
    originalPrice: {
      type: Number,
      default: null,
    },
    priceUnit: {
      type: String,
      enum: ['piece', 'kg', '100g', 'liter', 'dozen', 'packet', 'bundle'],
      default: 'piece',
    },
    minOrder: {
      type: Number,
      default: 1,
      min: [0.1, 'Minimum order must be at least 0.1'],
    },
    images: {
      type: [String],
      required: [true, 'A product must have at least one image'],
    },
    vendorId: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: [true, 'Product must belong to a vendor'],
    },
    stockQuantity: {
      type: Number,
      required: [true, 'Please provide stock quantity'],
      min: [0, 'Stock cannot be negative'],
      default: 0,
    },
    productStatus: {
      type: String,
      enum: ['Available', 'OutOfStock', 'Inactive'],
      default: 'Available',
    },
    vendorName: {
      type: String,
      trim: true,
    },
    location: {
      type: String,
      trim: true,
    },
    ratingsAverage: {
      type: Number,
      default: 0,
      min: [0, 'Rating must be above or equal to 0'],
      max: [5, 'Rating must be below or equal to 5'],
      set: val => Math.round(val * 10) / 10, // rounds to 4.7
    },
    ratingsQuantity: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtuals for backward compatibility
productSchema.virtual('stock').get(function() {
  return this.stockQuantity;
}).set(function(val) {
  this.stockQuantity = val;
});

productSchema.virtual('isAvailable').get(function() {
  return this.productStatus === 'Available' && this.stockQuantity > 0;
});

// Middleware to update status based on stock — only if productStatus wasn't explicitly set
productSchema.pre('save', function() {
  if (this.isModified('productStatus')) return;
  if (this.stockQuantity <= 0) {
    this.productStatus = 'OutOfStock';
  } else if (this.productStatus === 'OutOfStock') {
    this.productStatus = 'Available';
  }
});

// Indexes for search and filter performance
productSchema.index({ title: 'text', description: 'text', vendorName: 'text' });
productSchema.index({ category: 1 });
productSchema.index({ vendorId: 1 });
productSchema.index({ price: 1 });
productSchema.index({ productStatus: 1 });
productSchema.index({ stockQuantity: 1 });
productSchema.index({ location: 1 });
productSchema.index({ createdAt: -1 });

const Product = mongoose.model('Product', productSchema);

module.exports = Product;
