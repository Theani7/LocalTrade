const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Please provide your full name'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Please provide your email'],
      unique: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
    },
    phone: {
      type: String,
      required: [true, 'Please provide your phone number'],
      unique: true,
    },
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: 6,
      select: false,
    },
    address: {
      type: {
        fullName: { type: String },
        phone: { type: String },
        flatHouse: { type: String },
        street: { type: String },
        landmark: { type: String },
        city: { type: String },
        state: { type: String },
        zipCode: { type: String },
      },
      default: null,
    },
    // --- Vendor Specific Fields ---
    shopName: {
      type: String,
      trim: true,
    },
    businessDescription: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    openingHours: {
      type: String,
      default: '9:00 AM - 6:00 PM',
    },
    categories: {
      type: [String],
      default: [],
    },
    // ------------------------------
    profileImage: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      enum: ['customer', 'vendor', 'admin'],
      default: 'customer',
    },
    vendorApprovalStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'suspended'],
      default: function () {
        return this.role === 'vendor' ? 'pending' : 'approved';
      },
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    fcmToken: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 12);
});

// Method to compare password
userSchema.methods.comparePassword = async function (candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

// Indexes for vendor search and filter
userSchema.index({ shopName: 1 });
userSchema.index({ address: 1 });
userSchema.index({ role: 1 });
userSchema.index({ vendorApprovalStatus: 1 });

const User = mongoose.model('User', userSchema);

module.exports = User;
