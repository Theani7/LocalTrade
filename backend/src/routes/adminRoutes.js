const express = require('express');
const adminController = require('../controllers/adminController');
const productController = require('../controllers/productController');
const { protect, restrictTo } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.use(restrictTo('admin'));

router.get('/analytics', adminController.getSystemAnalytics);
router.get('/analytics/export', adminController.exportAnalytics);
router.get('/users', adminController.getAllUsers);
router.get('/vendors', adminController.getAllVendors);
router.get('/products', adminController.getAllProducts);
router.get('/products/:id', adminController.getProduct);
router.get('/orders', adminController.getAllOrders);
router.patch('/vendors/:id/status', adminController.updateVendorStatus);
router.patch('/users/:id/toggle-status', adminController.toggleUserStatus);
router.delete('/products/:id', productController.deleteProduct);

module.exports = router;
