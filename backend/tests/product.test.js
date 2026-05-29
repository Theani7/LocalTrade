const request = require('supertest');
const app = require('../src/app');

describe('Products API', () => {
  let vendorToken;
  let productId;

  const vendorUser = {
    fullName: 'Test Vendor',
    email: 'vendor@example.com',
    phone: '9811111111',
    password: 'password123',
    address: 'Patan',
    role: 'vendor'
  };

  const productData = {
    title: 'Fresh Tomatoes',
    description: 'Organic local tomatoes',
    price: 150,
    category: 'Vegetables',
    stockQuantity: 50,
    images: ['https://example.com/image.jpg']
  };

  beforeEach(async () => {
    // Register & Login
    await request(app).post('/api/v1/auth/register').send(vendorUser);
    const loginRes = await request(app).post('/api/v1/auth/login').send({
      email: vendorUser.email,
      password: vendorUser.password
    });
    vendorToken = loginRes.body.token;

    // Approve
    const User = require('../src/models/userModel');
    await User.findOneAndUpdate({ email: vendorUser.email }, { vendorApprovalStatus: 'approved' });
    
    // Create a product for tests that need it
    const pRes = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send(productData);

    if (pRes.statusCode !== 201) {
      console.error('Product Creation Failed in Setup:', JSON.stringify(pRes.body, null, 2));
    }
    
    productId = pRes.body.data?.product?._id;
  });

  test('Should create a new product', async () => {
    const res = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        ...productData,
        title: 'New Product'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
  });

  test('Should get all products', async () => {
    const res = await request(app).get('/api/v1/products');
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.results).toBeGreaterThan(0);
  });

  test('Should get single product by ID', async () => {
    const res = await request(app).get(`/api/v1/products/${productId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.product.title).toBe(productData.title);
  });

  test('Should update product', async () => {
    const res = await request(app)
      .patch(`/api/v1/products/${productId}`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        price: 160
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.product.price).toBe(160);
  });

  test('Should delete product', async () => {
    const res = await request(app)
      .delete(`/api/v1/products/${productId}`)
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(res.statusCode).toBe(204);
  });
});
