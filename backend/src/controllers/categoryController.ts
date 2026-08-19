import { Response, NextFunction } from 'express';
import Category from '../models/categoryModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { AuthRequest } from '../types';

// Public: get all active categories
export const getActiveCategories = catchAsync(async (req: AuthRequest, res: Response): Promise<void> => {
  const categories = await Category.find({ isActive: true }).sort('sortOrder name');
  res.status(200).json({
    success: true,
    data: { categories },
  });
});

// Admin: get all categories (including inactive)
export const getAllCategories = catchAsync(async (req: AuthRequest, res: Response): Promise<void> => {
  const categories = await Category.find().sort('sortOrder name');
  res.status(200).json({
    success: true,
    data: { categories },
  });
});

// Admin: create category
export const createCategory = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { name, icon, sortOrder } = req.body;
  if (!name || name.trim().length === 0) {
    return next(new AppError('Category name is required', 400));
  }
  const existing = await Category.findOne({ name: { $regex: `^${name.trim()}$`, $options: 'i' } });
  if (existing) {
    return next(new AppError('A category with this name already exists', 400));
  }
  const category = await Category.create({
    name: name.trim(),
    icon: icon || 'category',
    sortOrder: sortOrder ?? 0,
  });
  res.status(201).json({
    success: true,
    data: { category },
  });
});

// Admin: update category
export const updateCategory = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { name, icon, sortOrder, isActive } = req.body;
  const category = await Category.findById(req.params.id);
  if (!category) {
    return next(new AppError('Category not found', 404));
  }
  if (name && name.trim().length > 0) {
    const existing = await Category.findOne({
      name: { $regex: `^${name.trim()}$`, $options: 'i' },
      _id: { $ne: category._id },
    });
    if (existing) {
      return next(new AppError('A category with this name already exists', 400));
    }
    category.name = name.trim();
  }
  if (icon !== undefined) category.icon = icon;
  if (sortOrder !== undefined) category.sortOrder = sortOrder;
  if (isActive !== undefined) category.isActive = isActive;
  await category.save();
  res.status(200).json({
    success: true,
    data: { category },
  });
});

// Admin: delete category
export const deleteCategory = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const category = await Category.findById(req.params.id);
  if (!category) {
    return next(new AppError('Category not found', 404));
  }
  await Category.findByIdAndDelete(req.params.id);
  res.status(204).json({ success: true });
});

// Admin: reorder categories
export const reorderCategories = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  const { orderedIds } = req.body;
  if (!Array.isArray(orderedIds)) {
    return next(new AppError('orderedIds must be an array', 400));
  }
  const bulkOps = orderedIds.map((id: string, index: number) => ({
    updateOne: {
      filter: { _id: id },
      update: { sortOrder: index },
    },
  }));
  await Category.bulkWrite(bulkOps as any);
  res.status(200).json({
    success: true,
    message: 'Categories reordered',
  });
});

export default {
  getActiveCategories,
  getAllCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  reorderCategories,
};
