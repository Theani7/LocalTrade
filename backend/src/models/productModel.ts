import mongoose, { Schema } from 'mongoose';
import { IProductDoc } from '../types';

const productSchema = new Schema<IProductDoc>(
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
      min: [0.01, 'Price must be a positive number'],
    },
    originalPrice: {
      type: Number,
      default: null,
      min: [0.01, 'Original price must be a positive number'],
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
      type: Schema.Types.ObjectId,
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
    sizes: {
      type: [String],
      default: [],
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
      set: (val: number) => Math.round(val * 10) / 10, // rounds to 4.7
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
productSchema.virtual('stock').get(function (this: IProductDoc) {
  return this.stockQuantity;
}).set(function (this: IProductDoc, val: number) {
  this.stockQuantity = val;
});

productSchema.virtual('isAvailable').get(function (this: IProductDoc) {
  return this.productStatus === 'Available' && this.stockQuantity > 0;
});

// Middleware to update status based on stock — only if productStatus wasn't explicitly set
productSchema.pre('save', function (this: IProductDoc) {
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
productSchema.index({ vendorId: 1, title: 1 }, { unique: true });
productSchema.index({ price: 1 });
productSchema.index({ productStatus: 1 });
productSchema.index({ stockQuantity: 1 });
productSchema.index({ location: 1 });
productSchema.index({ createdAt: -1 });

const Product = mongoose.model<IProductDoc>('Product', productSchema);

export = Product;
