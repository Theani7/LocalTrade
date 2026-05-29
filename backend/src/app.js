const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const dotenv = require('dotenv');

// Custom NoSQL query injection sanitizer middleware for Express 5 compatibility
const sanitizeObject = (obj) => {
  if (obj && typeof obj === 'object') {
    for (const key in obj) {
      if (key.startsWith('$')) {
        delete obj[key];
      } else {
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
    if (allowedOrigins.indexOf(origin) === -1 && process.env.NODE_ENV === 'production') {
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
  max: 200, // Limit each IP to 200 requests per 15 minutes
  windowMs: 15 * 60 * 1000,
  message: 'Too many requests from this IP, please try again in 15 minutes!',
});
app.use('/api', limiter);

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
