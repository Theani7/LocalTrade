import request from 'supertest';
import app from '../src/app';
import User from '../src/models/userModel';
import Order from '../src/models/orderModel';
import Product from '../src/models/productModel';

describe('Admin and Vendor Analytics Revenue API', () => {
  let adminToken: string;
  let vendorToken: string;
  let customerToken: string;
  let vendorId: string;
  let customerId: string;
  let productId: string;

  beforeEach(async () => {
    // 1) Register & Login Admin
    const adminUser = {
      fullName: 'Admin User',
      email: 'admin.analytics@example.com',
      phone: '9811111111',
      password: 'password123',
      role: 'customer',
    };
    await request(app).post('/api/v1/auth/register').send(adminUser);
    await User.findOneAndUpdate({ email: adminUser.email }, { role: 'admin' });
    const adminLoginRes = await request(app).post('/api/v1/auth/login').send({
      email: adminUser.email,
      password: adminUser.password,
    });
    adminToken = adminLoginRes.body.token;

    // 2) Register & Login & Approve Vendor
    const vendorUser = {
      fullName: 'Analytics Vendor',
      email: 'vendor.analytics@example.com',
      phone: '9822222222',
      password: 'password123',
      role: 'vendor',
    };
    await request(app).post('/api/v1/auth/register').send(vendorUser);
    const vendorLoginRes = await request(app).post('/api/v1/auth/login').send({
      email: vendorUser.email,
      password: vendorUser.password,
    });
    vendorToken = vendorLoginRes.body.token;
    vendorId = vendorLoginRes.body.data.user._id;
    await User.findOneAndUpdate({ email: vendorUser.email }, { vendorApprovalStatus: 'approved' });

    // 3) Register Customer
    const customerUser = {
      fullName: 'Analytics Customer',
      email: 'customer.analytics@example.com',
      phone: '9833333333',
      password: 'password123',
      role: 'customer',
    };
    await request(app).post('/api/v1/auth/register').send(customerUser);
    const customerLoginRes = await request(app).post('/api/v1/auth/login').send({
      email: customerUser.email,
      password: customerUser.password,
    });
    customerToken = customerLoginRes.body.token;
    customerId = customerLoginRes.body.data.user._id;

    // 4) Create Product
    const prodRes = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        title: 'Fresh Apples',
        description: 'Crisp mountain apples',
        price: 200,
        category: 'Vegetables',
        stockQuantity: 100,
        images: ['https://example.com/apple.jpg'],
      });
    productId = prodRes.body.data.product._id;
  });

  it('should include Confirmed, Processing, Shipped, Delivered in totalRevenue and dailyStats, excluding Pending and Cancelled', async () => {
    // Create 4 orders directly:
    // 1. Pending (Rs. 500) -> should NOT count
    // 2. Confirmed (Rs. 1000) -> should count
    // 3. Delivered (Rs. 1500) -> should count
    // 4. Cancelled (Rs. 2000) -> should NOT count
    const baseOrder = {
      customerId,
      vendorId,
      products: [{ product: productId, quantity: 1, price: 200 }],
      shippingAddress: {
        fullName: 'Test Customer',
        phone: '9833333333',
        street: 'Street 1',
        city: 'Kathmandu',
        state: 'Bagmati',
        zipCode: '44600',
      },
    };

    await Order.create({ ...baseOrder, totalAmount: 500, orderStatus: 'Pending' });
    await Order.create({ ...baseOrder, totalAmount: 1000, orderStatus: 'Confirmed' });
    await Order.create({ ...baseOrder, totalAmount: 1500, orderStatus: 'Delivered' });
    await Order.create({ ...baseOrder, totalAmount: 2000, orderStatus: 'Cancelled' });

    // Query admin analytics
    const res = await request(app)
      .get('/api/v1/admin/analytics')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const stats = res.body.data.stats;
    // totalRevenue should be 1000 (Confirmed) + 1500 (Delivered) = 2500
    expect(stats.totalRevenue).toBe(2500);

    // dailyStats should reflect the 2500 revenue on today's date
    const dailyStats = res.body.data.dailyStats;
    expect(Array.isArray(dailyStats)).toBe(true);
    expect(dailyStats.length).toBe(30);

    const todayDateStr = new Date().toISOString().split('T')[0];
    const todayStat = dailyStats.find((d: any) => d._id === todayDateStr);
    expect(todayStat).toBeDefined();
    expect(todayStat.revenue).toBe(2500);

    // Query vendor analytics
    const vendorRes = await request(app)
      .get('/api/v1/vendors/analytics')
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(vendorRes.status).toBe(200);
    expect(vendorRes.body.data.stats.totalRevenue).toBe(2500);
  });
});
