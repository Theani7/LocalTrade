const express = require('express');
const vendorController = require('../controllers/vendorController');
const { protect, restrictTo } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

const router = express.Router();

router.use(protect);
router.use(restrictTo('vendor'));

router.get('/analytics', vendorController.getVendorAnalytics);
router.get('/profile', vendorController.getVendorProfile);
router.patch('/profile', upload.single('profileImage'), vendorController.updateVendorProfile);

module.exports = router;
