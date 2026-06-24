const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

const sendToken = (user, statusCode, res) => {
  const token = signToken(user._id);
  const userObj = user.toObject();
  delete userObj.password;

  res.status(statusCode).json({
    success: true,
    status: 'success',
    token,
    data: { user: userObj },
  });
};

const generateOtp = () => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');
  const expires = Date.now() + 10 * 60 * 1000; // 10 minutes
  return { otp, hashedOtp, expires };
};

const createTempResetToken = () => {
  const raw = crypto.randomBytes(32).toString('hex');
  const hashed = crypto.createHash('sha256').update(raw).digest('hex');
  const expires = Date.now() + 5 * 60 * 1000; // 5 minutes
  return { raw, hashed, expires };
};

module.exports = { signToken, sendToken, generateOtp, createTempResetToken };
