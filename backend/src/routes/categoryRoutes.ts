import express from 'express';
import * as categoryController from '../controllers/categoryController';
import { protect, restrictTo } from '../middleware/authMiddleware';

const router = express.Router();

// Public
router.get('/', categoryController.getActiveCategories);

// Admin
router.use(protect, restrictTo('admin'));
router.get('/admin', categoryController.getAllCategories);
router.post('/', categoryController.createCategory);
router.patch('/reorder', categoryController.reorderCategories);
router.patch('/:id', categoryController.updateCategory);
router.delete('/:id', categoryController.deleteCategory);

export = router;
