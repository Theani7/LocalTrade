import express from 'express';
import * as productController from '../controllers/productController';
import reviewRouter from './reviewRoutes';
import { protect, restrictTo, isApprovedVendor } from '../middleware/authMiddleware';
import upload from '../middleware/uploadMiddleware';

const router = express.Router();

// Mount nested routes
router.use('/:productId/reviews', reviewRouter);

// --- PUBLIC ROUTES ---
router.get('/', productController.getAllProducts);
router.get('/vendors/:id/profile', productController.getVendorProfile);

// --- PROTECTED ROUTES ---
router.get('/my-products', protect, restrictTo('vendor'), productController.getMyProducts);
router.patch('/:id/stock', protect, restrictTo('vendor', 'admin'), isApprovedVendor, productController.updateProductStock);

// Specific routes before generic :id
router.post('/', protect, restrictTo('vendor'), isApprovedVendor, upload.array('images', 5), upload.validateImageContent, productController.createProduct);
router.patch('/:id', protect, restrictTo('vendor', 'admin'), isApprovedVendor, upload.array('images', 5), upload.validateImageContent, productController.updateProduct);
router.delete('/:id', protect, restrictTo('vendor', 'admin'), isApprovedVendor, productController.deleteProduct);
router.get('/:id/deletable', protect, restrictTo('vendor', 'admin'), isApprovedVendor, productController.checkProductDeletable);

// --- PUBLIC ID ROUTE (Generic) ---
router.get('/:id', productController.getProduct);

export = router;
