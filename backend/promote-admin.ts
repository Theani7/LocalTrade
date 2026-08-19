import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import User from './src/models/userModel';

const promoteToAdmin = async (email: string): Promise<void> => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI must be set in .env');
    }
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const user = await User.findOneAndUpdate(
      { email: email },
      { role: 'admin' },
      { returnDocument: 'after' }
    );

    if (user) {
      console.log(`✅ Success! ${email} is now an Admin.`);
    } else {
      console.log(`❌ User with email ${email} not found.`);
    }

    await mongoose.connection.close();
  } catch (err: any) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

const emailArg = process.argv[2];
if (!emailArg) {
  console.log('Please provide an email: tsx promote-admin.ts user@example.com');
  process.exit(1);
}

promoteToAdmin(emailArg);
