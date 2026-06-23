const User = require('../models/userModel');
const { sendToken } = require('../utils/authUtils');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
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
        flatHouse: address.flatHouse || '',
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

  const user = await User.findOne({ email }).select('+password');

  if (!user || !(await user.comparePassword(password, user.password))) {
    return next(new AppError('Incorrect email or password', 401));
  }

  if (!user.isActive) {
    return next(new AppError('Your account has been deactivated', 401));
  }

  sendToken(user, 200, res);
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
          flatHouse: parsed.flatHouse || '',
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
