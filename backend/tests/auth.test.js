const request = require('supertest');
const app = require('../src/app');

describe('Authentication API', () => {
  const customerUser = {
    fullName: 'Test Customer',
    email: 'customer@example.com',
    phone: '9800000000',
    password: 'password123',
    address: 'Kathmandu',
    role: 'customer'
  };

  test('Should register a new customer', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send(customerUser);

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.data.user.email).toBe(customerUser.email);
  });

  test('Should not register with existing email', async () => {
    await request(app).post('/api/v1/auth/register').send(customerUser);
    
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send(customerUser);

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('Should login an existing user', async () => {
    await request(app).post('/api/v1/auth/register').send(customerUser);

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: customerUser.email,
        password: customerUser.password
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
  });

  test('Should not login with incorrect password', async () => {
    await request(app).post('/api/v1/auth/register').send(customerUser);

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: customerUser.email,
        password: 'wrongpassword'
      });

    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
