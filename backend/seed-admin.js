require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/userModel');

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const adminEmail = 'admin@sajhabazar.com';
    const adminPassword = 'Admin@123';

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: adminEmail });

    if (existingAdmin) {
      console.log('Admin user already exists. Skipping...');
    } else {
      console.log('Creating default admin user...');
      await User.create({
        fullName: 'System Admin',
        email: adminEmail,
        phone: '9800000000',
        password: adminPassword,
        address: 'Kathmandu, Nepal',
        role: 'admin',
        isActive: true
      });
      console.log('✅ Default Admin created successfully!');
      console.log(`Email: ${adminEmail}`);
      console.log(`Password: ${adminPassword}`);
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding Error:', err.message);
    process.exit(1);
  }
};

seedAdmin();
