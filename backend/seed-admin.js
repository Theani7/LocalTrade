require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/userModel');

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;

    if (!adminEmail || !adminPassword) {
      console.error('ADMIN_EMAIL and ADMIN_PASSWORD must be set in .env');
      process.exit(1);
    }

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: adminEmail });

    if (existingAdmin) {
      // If the existing admin still has mustChangePassword, update the password
      if (existingAdmin.mustChangePassword) {
        existingAdmin.password = adminPassword;
        existingAdmin.mustChangePassword = true;
        await existingAdmin.save();
        console.log('Admin password reset (mustChangePassword flag retained).');
      } else {
        console.log('Admin user already exists. Skipping...');
      }
    } else {
      console.log('Creating default admin user...');
      await User.create({
        fullName: 'System Admin',
        email: adminEmail,
        phone: '9800000000',
        password: adminPassword,
        address: {
          fullName: 'System Admin',
          phone: '9800000000',
          city: 'Kathmandu',
          state: 'Bagmati',
          zipCode: '44600',
        },
        role: 'admin',
        isActive: true,
        vendorApprovalStatus: 'approved',
        mustChangePassword: true,
      });
      console.log('Admin created. Credentials read from .env');
      console.log('IMPORTANT: Admin must change password on first login.');
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (err) {
    console.error('Seeding Error:', err.message);
    process.exit(1);
  }
};

seedAdmin();
