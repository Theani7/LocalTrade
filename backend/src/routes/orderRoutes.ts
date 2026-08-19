import express from 'express';
import * as orderController from '../controllers/orderController';
import { protect, restrictTo, isApprovedVendor } from '../middleware/authMiddleware';

const router = express.Router();

router.use(protect);

router.post('/', restrictTo('customer'), orderController.createOrder);
router.get('/my-orders', restrictTo('customer'), orderController.getMyOrders);
router.get('/vendor-orders', restrictTo('vendor'), isApprovedVendor, orderController.getVendorOrders);
router.get('/:id', orderController.getOrder);
router.patch('/:id/status', restrictTo('vendor', 'admin'), isApprovedVendor, orderController.updateOrderStatus);
router.patch('/:id/cancel', restrictTo('customer', 'vendor', 'admin'), orderController.cancelOrder);

export = router;
