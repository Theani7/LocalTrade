const request = require('supertest');
const app = require('../src/app');

// We don't have a token, so we can't easily test the protected route without mocking auth.
// Let's just create a user, log in, get token, and update profile.

const mongoose = require('mongoose');
const User = require('../src/models/userModel');
require('dotenv').config();

async function run() {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/localtrade');
  
  // create dummy user
  let user = await User.findOne({ email: 'test_local@example.com' });
  if (!user) {
    user = await User.create({
      fullName: 'Test Local',
      email: 'test_local@example.com',
      password: 'password123',
      phone: '0000000000',
      role: 'customer'
    });
  }

  const loginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'test_local@example.com', password: 'password123' });
    
  const token = loginRes.body.token;

  const address = {
    fullName: 'Test Local',
    phone: '0000000000',
    flatHouse: '',
    street: 'Test Street',
    landmark: '',
    city: '',
    state: '',
    zipCode: ''
  };

  const updateRes = await request(app)
    .patch('/api/v1/auth/profile')
    .set('Authorization', `Bearer ${token}`)
    .field('fullName', 'Test Local Updated')
    .field('address', JSON.stringify(address));

  console.log('Update Status:', updateRes.status);
  console.log('Updated user address:', updateRes.body.data.user.address);

  // fetch me
  const meRes = await request(app)
    .get('/api/v1/auth/me')
    .set('Authorization', `Bearer ${token}`);
    
  console.log('Me user address:', meRes.body.data.user.address);

  await mongoose.disconnect();
}

run().catch(console.error);
