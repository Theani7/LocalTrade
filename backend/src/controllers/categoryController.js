const Category = require('../models/categoryModel');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

// Public: get all active categories
exports.getActiveCategories = catchAsync(async (req, res) => {
  const categories = await Category.find({ isActive: true }).sort('sortOrder name');
  res.status(200).json({
    success: true,
    data: { categories },
  });
});

// Admin: get all categories (including inactive)
exports.getAllCategories = catchAsync(async (req, res) => {
  const categories = await Category.find().sort('sortOrder name');
  res.status(200).json({
    success: true,
    data: { categories },
  });
});

// Admin: create category
exports.createCategory = catchAsync(async (req, res, next) => {
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
exports.updateCategory = catchAsync(async (req, res, next) => {
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
exports.deleteCategory = catchAsync(async (req, res, next) => {
  const category = await Category.findById(req.params.id);
  if (!category) {
    return next(new AppError('Category not found', 404));
  }
  await Category.findByIdAndDelete(req.params.id);
  res.status(204).json({ success: true });
});

// Admin: reorder categories
exports.reorderCategories = catchAsync(async (req, res, next) => {
  const { orderedIds } = req.body;
  if (!Array.isArray(orderedIds)) {
    return next(new AppError('orderedIds must be an array', 400));
  }
  const bulkOps = orderedIds.map((id, index) => ({
    updateOne: {
      filter: { _id: id },
      update: { sortOrder: index },
    },
  }));
  await Category.bulkWrite(bulkOps);
  res.status(200).json({
    success: true,
    message: 'Categories reordered',
  });
});
