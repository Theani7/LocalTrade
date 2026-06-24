const express = require('express');
const authController = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', protect, authController.getMe);
router.patch('/update-fcm-token', protect, authController.updateFcmToken);
router.patch('/profile', protect, upload.single('profileImage'), authController.updateProfile);
router.patch('/change-password', protect, authController.changePassword);
router.patch('/force-change-password', protect, authController.forceChangePassword);
router.post('/forgot-password', authController.forgotPassword);
router.patch('/reset-password/:token', authController.resetPassword);

module.exports = router;
