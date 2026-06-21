require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/userModel');

const promoteToAdmin = async (email) => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const user = await User.findOneAndUpdate(
      { email: email },
      { role: 'admin' },
      { new: true }
    );

    if (user) {
      console.log(`✅ Success! ${email} is now an Admin.`);
    } else {
      console.log(`❌ User with email ${email} not found.`);
    }

    await mongoose.connection.close();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

const emailArg = process.argv[2];
if (!emailArg) {
  console.log('Please provide an email: node promote-admin.js user@example.com');
  process.exit(1);
}

promoteToAdmin(emailArg);
