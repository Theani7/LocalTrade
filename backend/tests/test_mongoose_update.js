const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const User = require('../src/models/userModel');

async function run() {
  const mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  // Create user with null address (the default)
  const user = await User.create({
    fullName: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    password: 'password123',
    role: 'customer'
  });

  console.log('Initial address:', user.address);

  const updatedUser = await User.findByIdAndUpdate(
    user._id,
    { address: { fullName: 'John', city: 'NYC' } },
    { new: true, runValidators: true }
  );

  console.log('Updated address:', updatedUser.address);

  // Re-fetch from DB
  const dbUser = await User.findById(user._id);
  console.log('DB address:', dbUser.address);

  await mongoose.disconnect();
  await mongoServer.stop();
}

run().catch(console.error);
