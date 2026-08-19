import mongoose, { Schema, Model, Types } from 'mongoose';
import Product from './productModel';
import { IReviewDoc } from '../types';

interface ReviewModel extends Model<IReviewDoc> {
  calcAverageRatings(productId: Types.ObjectId | string): Promise<void>;
}

const reviewSchema = new Schema<IReviewDoc, ReviewModel>(
  {
    reviewText: {
      type: String,
      required: [true, 'Review cannot be empty'],
      trim: true,
      maxlength: [1000, 'Review cannot exceed 1000 characters'],
    },
    rating: {
      type: Number,
      required: [true, 'Review must have a rating'],
      min: [1, 'Rating must be above or equal to 1'],
      max: [5, 'Rating must be below or equal to 5'],
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    productId: {
      type: Schema.Types.ObjectId,
      ref: 'Product',
      required: [true, 'Review must belong to a product.'],
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Review must belong to a user'],
    },
    vendorReply: {
      text: {
        type: String,
        trim: true,
        maxlength: [500, 'Reply cannot exceed 500 characters'],
      },
      repliedAt: {
        type: Date,
      },
    },
  },
  {
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Prevent duplicate reviews (1 user -> 1 review per product)
reviewSchema.index({ productId: 1, userId: 1 }, { unique: true });

// Static method to calculate average rating
reviewSchema.statics.calcAverageRatings = async function (this: ReviewModel, productId: Types.ObjectId | string) {
  const stats = await this.aggregate([
    {
      $match: { productId: productId }
    },
    {
      $group: {
        _id: '$productId',
        nRating: { $sum: 1 },
        avgRating: { $avg: '$rating' }
      }
    }
  ]);

  if (stats.length > 0) {
    await Product.findByIdAndUpdate(productId, {
      ratingsQuantity: stats[0].nRating,
      ratingsAverage: stats[0].avgRating
    });
  } else {
    await Product.findByIdAndUpdate(productId, {
      ratingsQuantity: 0,
      ratingsAverage: 0
    });
  }
};

// Call calcAverageRatings after saving a review
reviewSchema.post('save', async function (this: IReviewDoc) {
  await (this.constructor as ReviewModel).calcAverageRatings(this.productId as any);
});

// Call calcAverageRatings after updating or deleting a review
reviewSchema.post(/^findOneAnd/, async function (doc: IReviewDoc | null) {
  if (doc) {
    await (doc.constructor as ReviewModel).calcAverageRatings(doc.productId as any);
  }
});

const Review = mongoose.model<IReviewDoc, ReviewModel>('Review', reviewSchema);

export = Review;
