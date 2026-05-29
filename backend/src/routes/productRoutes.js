const express = require('express');
const productController = require('../controllers/productController');
const reviewRouter = require('./reviewRoutes');
const { protect, restrictTo, isApprovedVendor } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

const router = express.Router();

// Mount nested routes
router.use('/:productId/reviews', reviewRouter);

// --- PUBLIC ROUTES ---
router.get('/', productController.getAllProducts);
// Move :id after specific routes but before protect if it should be public
// But wait, my-products is protected. 

// --- PROTECTED ROUTES ---
router.get('/my-products', protect, restrictTo('vendor'), productController.getMyProducts);
router.patch('/:id/stock', protect, restrictTo('vendor', 'admin'), isApprovedVendor, productController.updateProductStock);

// Specific routes before generic :id
router.post('/', protect, restrictTo('vendor'), isApprovedVendor, upload.array('images', 5), productController.createProduct);
router.patch('/:id', protect, restrictTo('vendor', 'admin'), isApprovedVendor, upload.array('images', 5), productController.updateProduct);
router.delete('/:id', protect, restrictTo('vendor', 'admin'), isApprovedVendor, productController.deleteProduct);

// --- PUBLIC ID ROUTE (Generic) ---
router.get('/:id', productController.getProduct);

module.exports = router;
