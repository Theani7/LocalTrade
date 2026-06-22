const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/userModel');
const jwt = require('jsonwebtoken');

let token;
let user;

test('Update address', async () => {
  user = await User.create({
    fullName: 'Test User 2',
    email: 'test2@example.com',
    phone: '1234567891',
    password: 'password123',
    role: 'customer'
  });
  token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || 'test_secret', { expiresIn: '1h' });

  const address = {
    fullName: 'Test Address',
    phone: '0987654321',
    city: 'Kathmandu',
    flatHouse: 'Apt 1'
  };

  const res = await request(app)
    .patch('/api/v1/auth/profile')
    .set('Authorization', `Bearer ${token}`)
    .field('address', JSON.stringify(address));

  console.log('Response body:', res.body.data.user.address);
  const dbUser = await User.findById(user._id);
  console.log('DB Address:', dbUser.address);
});
