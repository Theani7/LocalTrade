const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const dotenv = require('dotenv');
const multer = require('multer'); // Needed for Multer error handling
const AppError = require('./utils/appError');

// Custom NoSQL query injection sanitizer middleware for Express 5 compatibility
const sanitizeObject = (obj) => {
  if (obj && typeof obj === 'object') {
    const dangerousKeys = ['$__proto__', 'constructor', 'prototype'];
    for (const key in obj) {
      if (key.startsWith('$') || dangerousKeys.includes(key)) {
        delete obj[key];
      } else if (typeof obj[key] === 'object' && obj[key] !== null) {
        sanitizeObject(obj[key]);
      }
    }
  }
};

const customMongoSanitize = (req, res, next) => {
  if (req.body) sanitizeObject(req.body);
  if (req.query) sanitizeObject(req.query);
  if (req.params) sanitizeObject(req.params);
  next();
};
const rateLimit = require('express-rate-limit');

// Load environment variables based on environment
if (process.env.NODE_ENV === 'test') {
  dotenv.config({ path: path.join(__dirname, '../.env.test') });
} else {
  dotenv.config();
}

const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const vendorRoutes = require('./routes/vendorRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const reviewRoutes = require('./routes/reviewRoutes');

const app = express();

// Security Middlewares
app.use(helmet({
  crossOriginResourcePolicy: false,
}));

// CORS Configuration with Whitelist
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5000',
  'http://localhost:8080',
  'http://localhost:19000',
];
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    // Allow any localhost port in development (Flutter web uses random ports)
    const isLocalhost = /^http:\/\/localhost:\d+$/.test(origin);
    if (allowedOrigins.indexOf(origin) === -1 && !isLocalhost) {
      const msg = 'The CORS policy for this site does not allow access from the specified Origin.';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  },
  credentials: true,
}));

// Data sanitization against NoSQL query injection
app.use(customMongoSanitize);

// Limit requests from same API
const limiter = rateLimit({
  max: 200, // General limit: 200 requests per 15 minutes per IP
  windowMs: 15 * 60 * 1000,
  message: 'Too many requests from this IP, please try again in 15 minutes!',
});
app.use('/api', limiter);

// Stricter limiter for authentication routes to mitigate credential‑stuffing attacks.
// We disable it in the test environment to avoid interfering with automated test suites.
if (process.env.NODE_ENV !== 'test') {
  const authLimiter = rateLimit({
    max: 20, // 20 requests per 15 minutes per IP for auth endpoints
    windowMs: 15 * 60 * 1000,
    message: 'Too many authentication attempts, please try again later.',
  });
  app.use('/api/v1/auth', authLimiter);
}

// Body Parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Health Check Route
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'LocalTrade API is healthy and running',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV,
  });
});

// Serve static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
const API_PREFIX = '/api/v1';
app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/admin`, adminRoutes);
app.use(`${API_PREFIX}/products`, productRoutes);
app.use(`${API_PREFIX}/orders`, orderRoutes);
app.use(`${API_PREFIX}/notifications`, notificationRoutes);
app.use(`${API_PREFIX}/vendors`, vendorRoutes);
app.use(`${API_PREFIX}/feedback`, feedbackRoutes);
app.use(`${API_PREFIX}/reviews`, reviewRoutes);

// ---------------------------------------------------------------------
// Multer error handling
// ---------------------------------------------------------------------
// Multer can throw its own errors (e.g., file too large, invalid file type).
// Those errors are not caught by the generic async wrapper, so we translate
// them into our AppError format so the global error handler can respond
// with a consistent JSON payload.
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    // Multer's own error codes are descriptive, we expose the message directly.
    return next(new AppError(err.message, 400));
  }
  // Our custom fileFilter creates a generic Error with a specific message.
  if (err && typeof err.message === 'string' && err.message.includes('Invalid file type')) {
    return next(new AppError(err.message, 400));
  }
  next(err);
});

// 404 Route
app.use((req, res, next) => {
  const error = new Error(`Can't find ${req.originalUrl} on this server!`);
  res.status(404);
  next(error);
});

// Global Error Handler
app.use((err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  if (process.env.NODE_ENV === 'test') {
    console.error('--- ERROR CAUGHT BY GLOBAL HANDLER ---');
    console.error(err.stack);
    console.error('--------------------------------------');
  }

  // Specific Error Handling for MongoDB
  if (err.name === 'CastError') {
    err.message = `Invalid ${err.path}: ${err.value}`;
    err.statusCode = 400;
    err.status = 'fail';
  }

  if (err.code === 11000) {
    const match = err.errmsg ? err.errmsg.match(/(["'])(\\?.)*?\1/) : null;
    const value = match ? match[0] : 'Unknown value';
    err.message = `Duplicate field value: ${value}. Please use another value!`;
    err.statusCode = 400;
    err.status = 'fail';
  }

  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(el => el.message);
    err.message = `Invalid input data. ${errors.join('. ')}`;
    err.statusCode = 400;
    err.status = 'fail';
  }

  if (err.name === 'JsonWebTokenError') {
    err.message = 'Invalid token. Please log in again!';
    err.statusCode = 401;
    err.status = 'fail';
  }

  if (err.name === 'TokenExpiredError') {
    err.message = 'Your token has expired! Please log in again.';
    err.statusCode = 401;
    err.status = 'fail';
  }

  res.status(err.statusCode).json({
    success: false,
    status: err.status,
    message: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

module.exports = app;

