# Testing Checklist - LocalTrade

Use this checklist to verify the functionality of the LocalTrade platform before demonstration.

## 🔑 Authentication
- [ ] User registration (Customer/Vendor).
- [ ] User login with valid credentials.
- [ ] Error handling for invalid credentials.
- [ ] Persistent login (app stays logged in after restart).
- [ ] Logout functionality.

## 🛡️ Vendor Approval
- [ ] New vendor status is 'pending' by default.
- [ ] Pending vendor cannot access dashboard.
- [ ] Admin can approve vendor.
- [ ] Approved vendor can access dashboard.
- [ ] Admin can suspend vendor.

## 📦 Product Management
- [ ] Vendor can add product with images.
- [ ] Vendor can edit own product.
- [ ] Vendor can delete own product.
- [ ] Customers can see products.
- [ ] Search functionality works.
- [ ] Category filtering works.

## 🛒 Shopping & Orders
- [ ] Add items to cart.
- [ ] Update cart quantities.
- [ ] Remove items from cart.
- [ ] Place order with shipping address.
- [ ] Customer can see order history.
- [ ] Vendor receives order in dashboard.
- [ ] Vendor can update status (Confirmed -> Delivered).
- [ ] Order timeline reflects status changes.

## 🔔 Notifications
- [ ] Notification received when order is placed (Vendor).
- [ ] Notification received when status changes (Customer).
- [ ] Notification center shows history.
- [ ] Unread badges update correctly.

## 🛡️ Admin Dashboard
- [ ] View total system stats.
- [ ] Manage user list.
- [ ] Manage vendor approvals.
- [ ] Overview of all marketplace orders.

## 📱 UI/UX & Performance
- [ ] Loading indicators during API calls.
- [ ] Empty states when no data is available.
- [ ] Error messages for failed requests.
- [ ] Responsive layout on different screen sizes.
- [ ] Smooth image loading (cached).

