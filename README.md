# LocalTrade: Nepal's Community Marketplace 🇳🇵

LocalTrade is a modern, elegant, full-stack mobile marketplace platform designed to empower micro and small businesses in Nepal. It connects local producers, such as vegetable sellers, handicraft makers, dairy farmers, and tailors, directly with their community through a simple and intuitive reservation-based ordering system.

## ✨ Key Features

### 🛍️ For Customers
- **Product Discovery:** Browse and search local goods with advanced filtering by category (Vegetables, Dairy, Handicrafts, etc.).
- **Smart Shopping:** Seamless cart management and reservation-based checkout (no complex online payment required).
- **Order Tracking:** Real-time order monitoring with a professional timeline UI.
- **Notifications:** Instant alerts for order updates and system announcements.

### 🏪 For Vendors
- **Business Dashboard:** Comprehensive analytics showing total revenue, order statuses, and inventory counts.
- **Inventory Management:** Easy-to-use tools to list, edit, and manage products with multiple image support.
- **Order Fulfillment:** Direct queue for managing customer orders and updating fulfillment status.
- **Visual Storytelling:** High-quality image hosting powered by Cloudinary.

### 🛡️ For Administrators
- **Platform Oversight:** Full control over user management and vendor moderation.
- **Vendor Approval:** Secure onboarding process ensuring only verified local businesses participate.
- **System Analytics:** High-level insights into platform growth, marketplace activity, and revenue.

## 🚀 Tech Stack

- **Frontend:** Flutter (Dart) with Material 3 UI and Provider state management.
- **Backend:** Node.js (Express.js) following MVC architecture.
- **Database:** MongoDB Atlas (Mongoose ODM).
- **Image Storage:** Cloudinary.
- **Push Notifications:** Firebase Cloud Messaging (FCM).
- **Authentication:** JWT-based secure auth with bcrypt password hashing and Role-Based Access Control (RBAC).

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (latest stable)
- Node.js (v18+)
- MongoDB Atlas account
- Firebase project
- Cloudinary account

### Backend Setup
1. Navigate to `/backend`:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file from `.env.example` and fill in your credentials.
4. Start the development server:
   ```bash
   npm run dev
   ```

### Frontend Setup
1. Navigate to `/frontend/localtrade_app`:
   ```bash
   cd frontend/localtrade_app
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Configure Firebase using FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 🧪 Testing & Reliability

LocalTrade features a robust testing suite and standardized error-handling to ensure a stable production-grade experience.

### Backend Testing
We use **Jest** and **Supertest** with an in-memory MongoDB server for isolated API testing.

- **Run all tests:** `cd backend && npm test`
- **Run specific test:** `npx jest tests/auth.test.js`

**Test Coverage:**
- [x] **Authentication:** Registration, Login, JWT verification, and RBAC.
- [x] **Products:** Full CRUD lifecycle and vendor approval validation.
- [x] **Orders:** Stock management, total calculation, and status updates.

## 📄 Documentation

- [API Documentation](API_DOCUMENTATION.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)

## 🎓 Academic Project
This project was developed for a final year university submission, demonstrating a production-grade implementation of a community-focused marketplace.

## ⚖️ License
Distributed under the MIT License. See `LICENSE` for more information.
