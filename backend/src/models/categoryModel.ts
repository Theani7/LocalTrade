import mongoose, { Schema } from 'mongoose';
import { ICategoryDoc } from '../types';

const categorySchema = new Schema<ICategoryDoc>(
  {
    name: {
      type: String,
      required: [true, 'Category must have a name'],
      unique: true,
      trim: true,
    },
    icon: {
      type: String,
      default: 'category',
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

categorySchema.index({ sortOrder: 1 });
categorySchema.index({ isActive: 1 });

const Category = mongoose.model<ICategoryDoc>('Category', categorySchema);

export = Category;
