import express from 'express';
import * as authController from '../controllers/authController';
import { protect } from '../middleware/authMiddleware';
import upload from '../middleware/uploadMiddleware';

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', protect, authController.getMe);
router.patch('/update-fcm-token', protect, authController.updateFcmToken);
router.patch('/profile', protect, upload.single('profileImage'), upload.validateImageContent, authController.updateProfile);
router.patch('/change-password', protect, authController.changePassword);
router.patch('/force-change-password', protect, authController.forceChangePassword);
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOtp);
router.patch('/reset-password-with-otp', authController.resetPasswordWithOtp);

export = router;
