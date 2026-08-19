import express from 'express';
import * as vendorController from '../controllers/vendorController';
import { protect, restrictTo, isApprovedVendor } from '../middleware/authMiddleware';
import upload from '../middleware/uploadMiddleware';

const router = express.Router();

router.use(protect);
router.use(restrictTo('vendor'));
router.use(isApprovedVendor);

router.get('/analytics', vendorController.getVendorAnalytics);
router.get('/profile', vendorController.getVendorProfile);
router.patch('/profile', upload.single('profileImage'), upload.validateImageContent, vendorController.updateVendorProfile);

export = router;
