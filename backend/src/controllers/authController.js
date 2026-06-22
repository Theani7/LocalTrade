const User = require('../models/userModel');
const { sendToken } = require('../utils/authUtils');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { notifyAdmins } = require('../utils/notificationUtils');

exports.register = catchAsync(async (req, res, next) => {
  const { fullName, email, phone, password, role, shopName, businessDescription, categories, openingHours, address } = req.body;

  // Security: Allow registering only as customer or vendor
  if (role && !['customer', 'vendor'].includes(role)) {
    return next(new AppError('Unauthorized: Invalid role selection', 400));
  }

  // Check if user already exists
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

  // Store vendor-specific fields during registration
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
    // Parse and store address
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

  // Notify Admins if a new vendor registers
  if (role === 'vendor') {
    await notifyAdmins(
      'New Vendor Registration',
      `${fullName} (${shopName || 'No shop name'}) has registered as a vendor and is awaiting approval.`,
      { userId: newUser._id.toString(), type: 'vendor_approval' }
    );
  }

  sendToken(newUser, 201, res);
});

exports.login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  // 1) Check if email and password exist
  if (!email || !password) {
    return next(new AppError('Please provide email and password', 400));
  }

  // 2) Check if user exists && password is correct
  const user = await User.findOne({ email }).select('+password');

  if (!user || !(await user.comparePassword(password, user.password))) {
    return next(new AppError('Incorrect email or password', 401));
  }

  // 3) Check if user is active
  if (!user.isActive) {
    return next(new AppError('Your account has been deactivated', 401));
  }

  // 4) If everything ok, send token to client
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

// @desc    Update user profile
// @route   PATCH /api/v1/auth/profile
// @access  Private
exports.updateProfile = catchAsync(async (req, res, next) => {
  const { fullName, phone, address, shopName, businessDescription, openingHours, categories } = req.body;
  
  const updateData = {};
  if (fullName !== undefined) updateData.fullName = fullName;
  if (phone !== undefined) updateData.phone = phone;
  
  // Parse address if it comes as a JSON string (multipart form)
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

  // Vendor-specific fields
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
