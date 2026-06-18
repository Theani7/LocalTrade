require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/userModel');
const Product = require('./src/models/productModel');
const Order = require('./src/models/orderModel');
const Review = require('./src/models/reviewModel');
const Feedback = require('./src/models/feedbackModel');
const Notification = require('./src/models/notificationModel');

const clearData = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI is not defined in the environment variables');
    }

    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('Clearing all products...');
    const productResult = await Product.deleteMany({});
    console.log(`✅ Deleted ${productResult.deletedCount} products.`);

    console.log('Clearing all vendors...');
    const vendorResult = await User.deleteMany({ role: 'vendor' });
    console.log(`✅ Deleted ${vendorResult.deletedCount} vendors.`);

    console.log('Clearing related data (orders, reviews, feedback, notifications)...');
    const orderResult = await Order.deleteMany({});
    const reviewResult = await Review.deleteMany({});
    const feedbackResult = await Feedback.deleteMany({});
    const notificationResult = await Notification.deleteMany({});
    
    console.log(`✅ Deleted ${orderResult.deletedCount} orders.`);
    console.log(`✅ Deleted ${reviewResult.deletedCount} reviews.`);
    console.log(`✅ Deleted ${feedbackResult.deletedCount} feedback entries.`);
    console.log(`✅ Deleted ${notificationResult.deletedCount} notifications.`);

    console.log('\nEnsuring default admin exists...');
    const adminEmail = 'admin@gmail.com';
    const adminPassword = 'admin123';

    // Remove any existing user with this email to ensure fresh state
    await User.deleteOne({ email: adminEmail });

    await User.create({
      fullName: 'System Admin',
      email: adminEmail,
      phone: '9800000000',
      password: adminPassword,
      address: 'Kathmandu, Nepal',
      role: 'admin',
      isActive: true,
      vendorApprovalStatus: 'approved'
    });

    console.log(`✅ Default Admin created/reset:`);
    console.log(`   Email: ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);

    console.log('\n--- Data Cleanup & Admin Reset Completed ---');
    
    await mongoose.connection.close();
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

clearData();
