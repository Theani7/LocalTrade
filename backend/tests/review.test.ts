import request from 'supertest';
import app from '../src/app';
import Product from '../src/models/productModel';
import Order from '../src/models/orderModel';
import User from '../src/models/userModel';

describe('Reviews API', () => {
  let customerToken: string;
  let vendorToken: string;
  let productId: string;
  let reviewId: string;

  const customer = {
    fullName: 'Review Customer',
    email: 'review.customer@example.com',
    phone: '9844444444',
    password: 'password123',
    address: { street: 'Street 1', city: 'Kathmandu', state: 'Bagmati', zipCode: '44600' },
    role: 'customer',
  };

  const vendor = {
    fullName: 'Review Vendor',
    email: 'review.vendor@example.com',
    phone: '9855555555',
    password: 'password123',
    address: { street: 'Street 1', city: 'Lalitpur', state: 'Bagmati', zipCode: '44600' },
    role: 'vendor',
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

    await User.findOneAndUpdate({ email: vendor.email }, { vendorApprovalStatus: 'approved' });

    // 3) Create a product
    const pRes = await request(app)
      .post('/api/v1/products')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        title: 'Review Product',
        description: 'Testing reviews',
        price: 500,
        category: 'Others',
        stockQuantity: 10,
        images: ['https://example.com/image.jpg'],
      });
    productId = pRes.body.data.product._id;
  });

  test('Should not allow review if not purchased', async () => {
    const res = await request(app)
      .post('/api/v1/reviews')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        productId,
        rating: 5,
        reviewText: 'Great product!',
      });

    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('Should allow review if purchased and delivered', async () => {
    // Manually create a delivered order for this customer and product
    const customerUser = await User.findOne({ email: customer.email });
    const vendorUser = await User.findOne({ email: vendor.email });

    try {
      const order = await Order.create({
        customerId: customerUser!._id,
        vendorId: vendorUser!._id,
        products: [{ product: productId, quantity: 1, price: 500 }],
        totalAmount: 500,
        shippingAddress: { fullName: 'Review Customer', phone: '9844444444', street: 'Street 1', city: 'Kathmandu', state: 'Bagmati', zipCode: '44600' },
        orderStatus: 'Delivered',
      });
      console.log('Created test order:', order._id, order.orderStatus, order.products[0].product);

      const foundOrder = await Order.findOne({
        customerId: customerUser!._id,
        'products.product': productId,
        orderStatus: 'Delivered',
      });
      console.log('Found test order:', foundOrder ? 'YES' : 'NO');
    } catch (err: any) {
      console.error('Failed to create manual order:', err.message);
    }

    const res = await request(app)
      .post('/api/v1/reviews')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        productId,
        rating: 4,
        reviewText: 'Good product!',
      });

    if (res.statusCode !== 201) {
      console.error('Review creation failed:', res.body);
    }

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    reviewId = res.body.data.review._id;

    // Check product average
    const product = await Product.findById(productId);
    expect(product?.ratingsQuantity).toBe(1);
    expect(product?.ratingsAverage).toBe(4);
  });
});
