/*
  Helper script to reproduce the order creation flow used in tests.
  Run with: node backend/tmp_check.js
*/
const request = require('supertest');
const app = require('./src/app');

async function run() {
  try {
    // Register customer
    const cust = {
      fullName: 'Order Customer',
      email: 'order.customer@example.com',
      phone: '9822222222',
      password: 'password123',
      address: 'Kathmandu',
      role: 'customer',
    };
    await request(app).post('/api/v1/auth/register').send(cust);
    const cLogin = await request(app).post('/api/v1/auth/login').send({ email: cust.email, password: cust.password });
    const customerToken = cLogin.body.token;

    // Register vendor
    const vend = {
      fullName: 'Order Vendor',
      email: 'order.vendor@example.com',
      phone: '9833333333',
      password: 'password123',
      address: 'Lalitpur',
      role: 'vendor',
    };
    await request(app).post('/api/v1/auth/register').send(vend);
    const vLogin = await request(app).post('/api/v1/auth/login').send({ email: vend.email, password: vend.password });
    const vendorToken = vLogin.body.token;
    const vendorId = vLogin.body.data.user._id;
    // Approve vendor directly in DB
    const User = require('./src/models/userModel');
    await User.findOneAndUpdate({ email: vend.email }, { vendorApprovalStatus: 'approved' });

    // Create product (simple JSON, no file upload)
    const pRes = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        title: 'Order Product',
        description: 'Testing orders',
        price: 500,
        category: 'Others',
        stockQuantity: 10,
        images: ['https://example.com/image.jpg'],
      });
    console.log('Product create status', pRes.statusCode);
    console.log('Product create body', JSON.stringify(pRes.body, null, 2));
    const productId = pRes.body.data?.product?._id;

    // Create order
    const oRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        items: [{ productId, quantity: 1, vendorId }],
        shippingAddress: 'Kathmandu',
        phone: '9822222222',
      });
    console.log('Order create status', oRes.statusCode);
    console.log('Order create body', JSON.stringify(oRes.body, null, 2));
  } catch (err) {
    console.error('Unexpected error', err);
  }
}

run();
