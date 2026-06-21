require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/userModel');

const seedCustomer = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const customerEmail = 'customer@example.com';
    const customerPassword = 'Password@123';

    // Check if customer already exists
    const existingCustomer = await User.findOne({ email: customerEmail });

    if (existingCustomer) {
      console.log('Customer user already exists. Skipping...');
    } else {
      console.log('Creating default customer user...');
      await User.create({
        fullName: 'Test Customer',
        email: customerEmail,
        phone: '9811111111',
        password: customerPassword,
        address: 'Patan, Nepal',
        role: 'customer',
        isActive: true
      });
      console.log('✅ Default Customer created successfully!');
      console.log(`Email: ${customerEmail}`);
      console.log(`Password: ${customerPassword}`);
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding Error:', err.message);
    process.exit(1);
  }
};

seedCustomer();
