const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const User = require('../src/models/userModel');

async function run() {
  const mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const user = await User.create({
    fullName: 'Test Null',
    email: 'testnull@example.com',
    password: 'password123',
    phone: '1234567890'
  });

  console.log('Original address:', user.address);

  const updated = await User.findByIdAndUpdate(
    user._id,
    {
      address: {
        fullName: 'Test Null Updated',
        city: 'NYC',
        street: 'Main St'
      }
    },
    { new: true, runValidators: true }
  );

  console.log('Updated address:', updated.address);

  await mongoose.disconnect();
  await mongoServer.stop();
}

run().catch(console.error);
