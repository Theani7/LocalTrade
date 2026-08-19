import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import User from './src/models/userModel';

const seedCustomer = async (): Promise<void> => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI must be set in .env');
    }
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
        address: {
          fullName: 'Test Customer',
          phone: '9811111111',
          street: '',
          landmark: '',
          city: 'Patan',
          state: 'Bagmati',
          zipCode: '44700',
        },
        role: 'customer',
        isActive: true,
      });
      console.log('✅ Default Customer created successfully!');
      console.log(`Email: ${customerEmail}`);
      console.log(`Password: ${customerPassword}`);
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (err: any) {
    console.error('❌ Seeding Error:', err.message);
    process.exit(1);
  }
};

seedCustomer();
