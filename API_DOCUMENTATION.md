# API Documentation - SajhaBazar v1

Base URL: `http://localhost:5000/api/v1`

## 📋 Standard Response Format
All successful API responses follow this structure:
```json
{
  "success": true,
  "status": "success",
  "data": { ... }
}
```

Error responses:
```json
{
  "success": false,
  "status": "fail" or "error",
  "message": "Human-readable error message"
}
```

## 🔐 Authentication
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/auth/register` | `POST` | Register new user | No |
| `/auth/login` | `POST` | User login | No |
| `/auth/me` | `GET` | Get current user profile | Yes |
| `/auth/update-fcm-token` | `PATCH` | Update Firebase token | Yes |

## 📦 Products
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/products` | `GET` | List all products (with advanced search/filters) | No |
| `/products/:id` | `GET` | Get product details | No |
| `/products` | `POST` | Create new product (Multipart) | Yes (Vendor) |
| `/products/:id` | `PATCH` | Update product (Multipart) | Yes (Vendor) |
| `/products/:id` | `DELETE` | Delete product | Yes (Vendor) |
| `/products/my-products` | `GET` | List vendor's products | Yes (Vendor) |

### Advanced Filtering (GET /products)
Query Parameters:
- `search`: Search by title, description, category, or vendor name.
- `category`: Filter by specific category.
- `location`: Filter by vendor area/address (regex search).
- `sort`: `price_low`, `price_high`, `newest`, `availability`.
- `page`: Page number for pagination (default 1).
- `limit`: items per page (default 10).

## 🛒 Orders
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/orders` | `POST` | Place a new order | Yes (Customer) |
| `/orders/my-orders` | `GET` | List customer orders | Yes (Customer) |
| `/orders/vendor-orders` | `GET` | List vendor orders | Yes (Vendor) |
| `/orders/:id` | `GET` | Get order details | Yes |
| `/orders/:id/status` | `PATCH` | Update fulfillment status | Yes (Vendor) |

## 🛡️ Admin
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/admin/analytics` | `GET` | Get system KPIs (Revenue, Growth) | Yes (Admin) |
| `/admin/vendors` | `GET` | List all vendors (with filters) | Yes (Admin) |
| `/admin/vendors/:id/status` | `PATCH` | Approve/Suspend vendor | Yes (Admin) |
| `/admin/users` | `GET` | List all users (with search/roles) | Yes (Admin) |

## 📊 Vendor
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/vendors/analytics` | `GET` | Get vendor-specific KPIs | Yes (Vendor) |
| `/vendors/profile` | `GET` | Get vendor business profile | Yes (Vendor) |

## 📝 Feedback (UAT)
| Endpoint | Method | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `/feedback` | `POST` | Submit UAT feedback | Yes |
| `/feedback` | `GET` | View all feedback analytics | Yes (Admin) |
