const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const User = require('../src/models/userModel');
const app = require('../src/app');
const request = require('supertest');
const jwt = require('jsonwebtoken');

async function run() {
  const mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const user = await User.create({
    fullName: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    password: 'password123',
    role: 'customer'
  });

  const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || 'test_secret', { expiresIn: '1h' });

  const address = {
    fullName: 'Test User',
    phone: '1234567890',
    flatHouse: 'Apt 42',
    street: '123 Main St',
    landmark: 'Near park',
    city: 'Kathmandu',
    state: 'Bagmati',
    zipCode: '44600'
  };

  const res = await request(app)
    .patch('/api/v1/auth/profile')
    .set('Authorization', `Bearer ${token}`)
    .field('fullName', 'Test User Updated')
    .field('phone', '1234567890')
    .field('address', JSON.stringify(address));

  console.log('--- RESPONSE ---');
  console.log(JSON.stringify(res.body.data.user, null, 2));

  await mongoose.disconnect();
  await mongoServer.stop();
}

run().catch(console.error);
