const request = require('supertest');
const app = require('../src/app');

describe('Orders API', () => {
  let customerToken;
  let vendorToken;
  let productId;
  let orderId;
  let vendorId;

  const customer = {
    fullName: 'Order Customer',
    email: 'order.customer@example.com',
    phone: '9822222222',
    password: 'password123',
    address: 'Kathmandu',
    role: 'customer'
  };

  const vendor = {
    fullName: 'Order Vendor',
    email: 'order.vendor@example.com',
    phone: '9833333333',
    password: 'password123',
    address: 'Lalitpur',
    role: 'vendor'
  };

  beforeEach(async () => {
    // 1) Register & Login Customer
    await request(app).post('/api/v1/auth/register').send(customer);
    const cRes = await request(app).post('/api/v1/auth/login').send({ email: customer.email, password: customer.password });
    customerToken = cRes.body.token;

    // 2) Register & Login & Approve Vendor
    await request(app).post('/api/v1/auth/register').send(vendor);
    const vRes = await request(app).post('/api/v1/auth/login').send({ email: vendor.email, password: vendor.password });
    vendorToken = vRes.body.token;
    vendorId = vRes.body.data.user._id;
    
    const User = require('../src/models/userModel');
    await User.findOneAndUpdate({ email: vendor.email }, { vendorApprovalStatus: 'approved' });

    // 3) Create a product for the vendor
    const pRes = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        title: 'Order Product',
        description: 'Testing orders',
        price: 500,
        category: 'Others',
        stockQuantity: 10,
        images: ['https://example.com/image.jpg']
      });

    if (pRes.statusCode !== 201) {
      console.error('Product Creation Failed in Setup (Orders):', JSON.stringify(pRes.body, null, 2));
    }
    
    productId = pRes.body.data?.product?._id;

    // 4) Create an order for tests that need it
    const oRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        items: [{ productId: productId, quantity: 1, vendorId: vendorId }],
        shippingAddress: 'Kathmandu',
        phone: '9822222222'
      });

    if (oRes.statusCode !== 201) {
      console.error('Order Creation Failed in Setup:', JSON.stringify(oRes.body, null, 2));
    }

    orderId = oRes.body.data?.order?._id;
  });

  test('Should place a new order', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        items: [{ productId: productId, quantity: 1, vendorId: vendorId }],
        shippingAddress: 'New Road',
        phone: '9822222222'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
  });

  test('Should get my orders as customer', async () => {
    const res = await request(app)
      .get('/api/v1/orders/my-orders')
      .set('Authorization', `Bearer ${customerToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.results).toBeGreaterThan(0);
  });

  test('Should update order status as vendor', async () => {
    const res = await request(app)
      .patch(`/api/v1/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        status: 'Shipped'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.order.orderStatus).toBe('Shipped');
  });

  test('Should not update order status as customer', async () => {
    const res = await request(app)
      .patch(`/api/v1/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        status: 'Delivered'
      });

    expect(res.statusCode).toBe(403);
  });
});
