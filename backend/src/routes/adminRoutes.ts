import express from 'express';
import * as adminController from '../controllers/adminController';
import * as productController from '../controllers/productController';
import { protect, restrictTo } from '../middleware/authMiddleware';

const router = express.Router();

router.use(protect);
router.use(restrictTo('admin'));

router.get('/analytics', adminController.getSystemAnalytics);
router.get('/analytics/export', adminController.exportAnalytics);
router.get('/users', adminController.getAllUsers);
router.get('/vendors', adminController.getAllVendors);
router.get('/vendors/:id', adminController.getVendorDetail);
router.get('/products', adminController.getAllProducts);
router.get('/products/:id', adminController.getProduct);
router.get('/products/:id/deletable', productController.checkProductDeletable);
router.get('/orders', adminController.getAllOrders);
router.patch('/vendors/:id/status', adminController.updateVendorStatus);
router.patch('/users/:id/toggle-status', adminController.toggleUserStatus);
router.delete('/products/:id', productController.deleteProduct);

export = router;
