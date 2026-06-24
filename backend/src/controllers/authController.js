const User = require('../models/userModel');
const crypto = require('crypto');
const { sendToken, generateOtp, createTempResetToken } = require('../utils/authUtils');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendEmail } = require('../config/email');
const { notifyAdmins } = require('../utils/notificationUtils');

exports.register = catchAsync(async (req, res, next) => {
  let { fullName, email, phone, password, role, shopName, businessDescription, categories, openingHours, address } = req.body;

  if (role && !['customer', 'vendor'].includes(role)) {
    return next(new AppError('Unauthorized: Invalid role selection', 400));
  }

  if (!email || !email.includes('@') || !email.includes('.')) {
    return next(new AppError('Please provide a valid email address', 400));
  }
  if (!password || password.length < 6) {
    return next(new AppError('Password must be at least 6 characters', 400));
  }
  // Phone number is required for both customers and vendors. The User schema enforces it,
  // but the controller previously allowed it to be missing which caused a Mongoose validation
  // error that bubbled up as a 500. We now validate explicitly to return a controlled 400.
  if (!phone) {
    return next(new AppError('Phone number is required', 400));
  }
  if (!fullName || typeof fullName !== 'string' || fullName.trim().length === 0 || fullName.length > 100) {
    return next(new AppError('Full name is required and must be under 100 characters', 400));
  }
  if (phone && (!/^\d{7,15}$/.test(phone))) {
    return next(new AppError('Phone number must be digits only, 7 to 15 characters', 400));
  }

  const existingUser = await User.findOne({ $or: [{ email }, { phone }] });
  if (existingUser) {
    return next(new AppError('User with this email or phone already exists', 400));
  }

  const userData = {
    fullName,
    email,
    phone,
    password,
    role,
  };

  if (role === 'vendor') {
    if (shopName) userData.shopName = shopName;
    if (businessDescription) userData.businessDescription = businessDescription;
    if (openingHours) userData.openingHours = openingHours;
    if (categories) {
      try {
        userData.categories = Array.isArray(categories) ? categories : JSON.parse(categories);
      } catch (e) {
        userData.categories = [];
      }
    }
    if (address && typeof address === 'object') {
      userData.address = {
        fullName: address.fullName || fullName || '',
        phone: address.phone || phone || '',
        street: address.street || '',
        landmark: address.landmark || '',
        city: address.city || '',
        state: address.state || '',
        zipCode: address.zipCode || '',
      };
    }
  }

  const newUser = await User.create(userData);

  if (role === 'vendor') {
    await notifyAdmins(
      'New vendor registration',
      `${fullName} (${shopName || 'No shop name'}) has registered as a vendor and is awaiting approval.`,
      { userId: newUser._id.toString(), type: 'vendor_approval' }
    );
  }

  sendToken(newUser, 201, res);
});

exports.login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return next(new AppError('Please provide email and password', 400));
  }

  const user = await User.findOne({ email }).select('+password +mustChangePassword');

  if (!user || !(await user.comparePassword(password, user.password))) {
    return next(new AppError('Incorrect email or password', 401));
  }

  if (!user.isActive) {
    return next(new AppError('Your account has been deactivated', 401));
  }

  // Include mustChangePassword in the response so frontend can force password reset
  const userObj = user.toObject();
  delete userObj.password;
  if (user.mustChangePassword) {
    userObj.mustChangePassword = true;
  }

  const { signToken } = require('../utils/authUtils');
  const token = signToken(user._id);

  res.status(200).json({
    success: true,
    status: 'success',
    token,
    data: { user: userObj },
  });
});

exports.getMe = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user.id);

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: {
      user,
    },
  });
});

exports.updateFcmToken = catchAsync(async (req, res, next) => {
  const { fcmToken } = req.body;

  const user = await User.findByIdAndUpdate(req.user.id, { fcmToken }, {
    new: true,
    runValidators: true
  });

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'FCM token updated'
  });
});

exports.updateProfile = catchAsync(async (req, res, next) => {
  const { fullName, phone, address, shopName, businessDescription, openingHours, categories } = req.body;

  if (fullName !== undefined && (typeof fullName !== 'string' || fullName.trim().length === 0 || fullName.length > 100)) {
    return next(new AppError('Full name must be a non-empty string under 100 characters', 400));
  }
  if (phone !== undefined && phone !== '' && !/^\d{7,15}$/.test(phone)) {
    return next(new AppError('Phone number must be digits only, 7 to 15 characters', 400));
  }
  if (shopName !== undefined && shopName !== '' && (typeof shopName !== 'string' || shopName.trim().length === 0 || shopName.length > 100)) {
    return next(new AppError('Shop name must be a non-empty string under 100 characters', 400));
  }

  const updateData = {};
  if (fullName !== undefined) updateData.fullName = fullName;
  if (phone !== undefined) updateData.phone = phone;

  if (address !== undefined && address !== null && address !== '') {
    try {
      const parsed = typeof address === 'string' ? JSON.parse(address) : address;
      if (typeof parsed === 'object' && parsed !== null) {
        updateData.address = {
          fullName: parsed.fullName || '',
          phone: parsed.phone || '',
          street: parsed.street || '',
          landmark: parsed.landmark || '',
          city: parsed.city || '',
          state: parsed.state || '',
          zipCode: parsed.zipCode || '',
        };
      }
    } catch (e) {
      // If parse fails, skip address update
    }
  }

  if (shopName !== undefined) updateData.shopName = shopName;
  if (businessDescription !== undefined) updateData.businessDescription = businessDescription;
  if (openingHours !== undefined) updateData.openingHours = openingHours;
  if (categories !== undefined) {
    try {
      updateData.categories = Array.isArray(categories) ? categories : JSON.parse(categories);
    } catch (e) {
      updateData.categories = [];
    }
  }

  if (req.file) {
    const { uploadToCloudinary } = require('../utils/cloudinaryUtils');
    updateData.profileImage = await uploadToCloudinary(req.file.buffer, 'localtrade/profiles');
  }

  const user = await User.findByIdAndUpdate(
    req.user.id,
    updateData,
    { new: true, runValidators: true }
  ).select('-password');

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    data: { user },
  });
});

exports.changePassword = catchAsync(async (req, res, next) => {
  const { currentPassword, newPassword, confirmPassword } = req.body;

  if (!currentPassword || !newPassword || !confirmPassword) {
    return next(new AppError('Current password, new password and confirm password are required', 400));
  }
  if (newPassword.length < 6) {
    return next(new AppError('New password must be at least 6 characters', 400));
  }
  if (newPassword !== confirmPassword) {
    return next(new AppError('New password and confirm password do not match', 400));
  }

  const user = await User.findById(req.user.id).select('+password');

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  const isCorrect = await user.comparePassword(currentPassword, user.password);

  if (!isCorrect) {
    return next(new AppError('Current password is incorrect', 401));
  }

  user.password = newPassword;
  await user.save();

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'Password changed successfully',
  });
});

// Force change password for users with mustChangePassword flag (no current password required)
exports.forceChangePassword = catchAsync(async (req, res, next) => {
  const { newPassword, confirmPassword } = req.body;

  if (!newPassword || !confirmPassword) {
    return next(new AppError('New password and confirm password are required', 400));
  }
  if (newPassword.length < 6) {
    return next(new AppError('New password must be at least 6 characters', 400));
  }
  if (newPassword !== confirmPassword) {
    return next(new AppError('New password and confirm password do not match', 400));
  }

  const user = await User.findById(req.user.id).select('+password +mustChangePassword');

  if (!user) {
    return next(new AppError('No user found with that ID', 404));
  }

  if (!user.mustChangePassword) {
    return next(new AppError('Password change is not required for this account', 400));
  }

  user.password = newPassword;
  user.mustChangePassword = false;
  await user.save();

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'Password updated successfully. You can now use your new password.',
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Forgot Password — Send OTP
// ─────────────────────────────────────────────────────────────────────────────
exports.forgotPassword = catchAsync(async (req, res, next) => {
  const { email } = req.body;

  if (!email) {
    return next(new AppError('Please provide your email address', 400));
  }

  const user = await User.findOne({ email });

  if (!user) {
    return res.status(200).json({
      success: true,
      status: 'success',
      message: 'If an account with that email exists, an OTP has been sent.',
    });
  }

  const { otp, hashedOtp, expires } = generateOtp();
  user.passwordResetOtp = hashedOtp;
  user.passwordResetOtpExpires = expires;
  user.passwordResetTempToken = undefined;
  user.passwordResetTempTokenExpires = undefined;
  await user.save({ validateBeforeSave: false });

  try {
    await sendEmail({
      to: user.email,
      subject: 'LocalTrade — Password Reset OTP',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>Password Reset</h2>
          <p>You requested a password reset for your LocalTrade account.</p>
          <p>Use the following OTP to reset your password. It expires in 10 minutes.</p>
          <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; text-align: center; padding: 20px; background: #FBF5EA; border-radius: 8px; margin: 16px 0; color: #2B2620;">
            ${otp}
          </div>
          <p style="color: #6E6557; font-size: 12px;">If you didn't request this, please ignore this email.</p>
        </div>
      `,
    });
  } catch (err) {
    user.passwordResetOtp = undefined;
    user.passwordResetOtpExpires = undefined;
    await user.save({ validateBeforeSave: false });
    return next(new AppError('Failed to send reset email. Please try again later.', 500));
  }

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'If an account with that email exists, an OTP has been sent.',
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Verify OTP
// ─────────────────────────────────────────────────────────────────────────────
exports.verifyOtp = catchAsync(async (req, res, next) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return next(new AppError('Email and OTP are required', 400));
  }

  const user = await User.findOne({ email }).select('+passwordResetOtp +passwordResetOtpExpires');

  if (!user || !user.passwordResetOtp || !user.passwordResetOtpExpires) {
    return next(new AppError('No reset request found. Please request a new OTP.', 400));
  }

  if (user.passwordResetOtpExpires < Date.now()) {
    user.passwordResetOtp = undefined;
    user.passwordResetOtpExpires = undefined;
    await user.save({ validateBeforeSave: false });
    return next(new AppError('OTP has expired. Please request a new one.', 400));
  }

  const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

  if (user.passwordResetOtp !== hashedOtp) {
    return next(new AppError('Invalid OTP. Please try again.', 400));
  }

  const { raw, hashed, expires } = createTempResetToken();
  user.passwordResetTempToken = hashed;
  user.passwordResetTempTokenExpires = expires;
  user.passwordResetOtp = undefined;
  user.passwordResetOtpExpires = undefined;
  await user.save({ validateBeforeSave: false });

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'OTP verified successfully.',
    data: { tempToken: raw },
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Reset Password (after OTP verification)
// ─────────────────────────────────────────────────────────────────────────────
exports.resetPasswordWithOtp = catchAsync(async (req, res, next) => {
  const { tempToken, password } = req.body;

  if (!tempToken) {
    return next(new AppError('Temporary token is required. Please verify OTP first.', 400));
  }
  if (!password || password.length < 6) {
    return next(new AppError('Password must be at least 6 characters', 400));
  }

  const hashedToken = crypto.createHash('sha256').update(tempToken).digest('hex');

  const user = await User.findOne({
    passwordResetTempToken: hashedToken,
    passwordResetTempTokenExpires: { $gt: Date.now() },
  }).select('+passwordResetTempToken +passwordResetTempTokenExpires');

  if (!user) {
    return next(new AppError('Session expired. Please verify OTP again.', 400));
  }

  user.password = password;
  user.passwordResetTempToken = undefined;
  user.passwordResetTempTokenExpires = undefined;
  await user.save();

  res.status(200).json({
    success: true,
    status: 'success',
    message: 'Password has been reset successfully.',
  });
});
