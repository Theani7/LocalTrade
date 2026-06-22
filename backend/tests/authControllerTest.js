const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const User = require('../src/models/userModel');
const authController = require('../src/controllers/authController');
const httpMocks = require('node-mocks-http');

let mongoServer;

async function run() {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const user = await User.create({
    fullName: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    password: 'password123',
    role: 'customer'
  });

  const req = httpMocks.createRequest({
    method: 'PATCH',
    url: '/api/v1/auth/profile',
    user: { id: user._id },
    body: {
      address: JSON.stringify({
        fullName: 'Test Address',
        phone: '0987654321',
        city: 'Kathmandu',
        flatHouse: 'Apt 1'
      })
    }
  });

  const res = httpMocks.createResponse();
  let nextCalled = false;
  const next = (err) => {
    nextCalled = true;
    console.error('Error:', err);
  };

  await authController.updateProfile(req, res, next);
  
  if (!nextCalled) {
      console.log('Response status:', res.statusCode);
      const data = res._getJSONData();
      console.log('Response address:', data.data.user.address);
      
      const dbUser = await User.findById(user._id);
      console.log('DB address:', dbUser.address);
  }

  await mongoose.disconnect();
  await mongoServer.stop();
}

run().catch(console.error);
