const express = require('express');
const orderController = require('../controllers/orderController');
const { protect, restrictTo, isApprovedVendor } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/', restrictTo('customer'), orderController.createOrder);
router.get('/my-orders', restrictTo('customer'), orderController.getMyOrders);
router.get('/vendor-orders', restrictTo('vendor'), isApprovedVendor, orderController.getVendorOrders);
router.get('/:id', orderController.getOrder);
router.patch('/:id/status', restrictTo('vendor', 'admin'), isApprovedVendor, orderController.updateOrderStatus);
router.patch('/:id/cancel', orderController.cancelOrder);

module.exports = router;
