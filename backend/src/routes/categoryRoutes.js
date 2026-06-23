const express = require('express');
const categoryController = require('../controllers/categoryController');
const { protect, restrictTo } = require('../middleware/authMiddleware');

const router = express.Router();

// Public
router.get('/', categoryController.getActiveCategories);

// Admin
router.use(protect, restrictTo('admin'));
router.get('/admin', categoryController.getAllCategories);
router.post('/', categoryController.createCategory);
router.patch('/:id', categoryController.updateCategory);
router.delete('/:id', categoryController.deleteCategory);
router.patch('/reorder', categoryController.reorderCategories);

module.exports = router;
