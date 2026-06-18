# LocalTrade: Nepal's Community Marketplace 🇳🇵

LocalTrade is a modern, elegant, full-stack mobile marketplace platform designed to empower micro and small businesses in Nepal. It connects local producers, such as vegetable sellers, handicraft makers, dairy farmers, and tailors, directly with their community through a simple and intuitive reservation-based ordering system.

---

## 🏗️ Project Architecture

### Backend (Node.js/Express)
- **Architecture:** Model-View-Controller (MVC).
- **Database:** MongoDB Atlas with Mongoose ODM.
- **Security:** JWT-based Authentication, Role-Based Access Control (RBAC), Password Hashing (bcrypt), and Middleware for rate-limiting & security headers (Helmet).
- **Storage:** Cloudinary for high-performance image hosting.
- **Notifications:** Firebase Admin SDK for real-time push notifications.

### Frontend (Flutter)
- **Framework:** Flutter (Material 3).
- **State Management:** Provider pattern for scalable state handling.
- **Networking:** HTTP package with interceptors for JWT handling.
- **Local Storage:** Flutter Secure Storage for tokens and Shared Preferences for user settings.

---

## 🛠️ Technical Setup & Operations

### 1. Database Setup (MongoDB Atlas)
1.  **Create Cluster:** Sign up at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) and create a free shared cluster.
2.  **Network Access:** In the Atlas dashboard, go to "Network Access" and click **Add IP Address**. For development, you can "Allow Access from Anywhere" (`0.0.0.0/0`).
3.  **Database Access:** Create a database user with **Read and Write** permissions. Remember the password.
4.  **Connection String:** Click **Connect** > **Drivers** and copy the URI. Replace `<password>` with your user's password.
5.  **Environment Variable:** Add this URI to your backend `.env` file as `MONGODB_URI`.

### 2. Image Storage (Cloudinary)
1.  Sign up for a free account at [Cloudinary](https://cloudinary.com).
2.  From your Dashboard, copy the **Cloud Name**, **API Key**, and **API Secret**.
3.  Add these to your backend `.env` file.

### 3. Push Notifications (Firebase)
1.  Create a project in the [Firebase Console](https://console.firebase.google.com).
2.  **Service Account:** Go to **Project Settings** > **Service Accounts** and click **Generate New Private Key**.
3.  **Backend Config:** Open the downloaded JSON and map the values to your backend `.env` (Project ID, Client Email, Private Key).
4.  **Frontend Config:** Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to configure the Flutter app:
    ```bash
    flutterfire configure
    ```

### 4. Backend Operations
Navigate to the `/backend` directory:
```bash
cd backend
npm install
```

#### Seeding & Resetting Data
To quickly populate or reset your database:
```bash
# Populate mock vendors and products
node seed-data.js

# Reset database (Deletes all vendors/products/orders and resets Admin)
npm run clear:data
```

> **Default Admin Credentials:**
> - **Email:** `admin@gmail.com`
> - **Password:** `admin123`

#### Running Tests
```bash
npm test
```

---

## 🚀 Installation & Running

### Backend
1. Create `.env` from `.env.example`.
2. `npm install`
3. `npm run dev` (Runs on `http://localhost:5000`)

### Frontend
1. Navigate to `/frontend/LocalTrade_app`.
2. `flutter pub get`
3. Ensure the backend URL is correctly set in `lib/core/constants/app_constants.dart`.
4. `flutter run`

---

## 📄 Documentation & Guides

- **[REQUIREMENTS.txt](REQUIREMENTS.txt):** Consolidated system requirements and environment keys.
- **[API Documentation](API_DOCUMENTATION.md):** Detailed endpoint list, request formats, and auth logic.
- **[Deployment Guide](DEPLOYMENT_GUIDE.md):** Steps for production hosting (Render/Railway).
- **[Testing Checklist](TESTING_CHECKLIST.md):** QA procedures for new features.

---

## 🤝 Contributing
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 🎓 Academic Project
This project was developed for a final year university submission, demonstrating a production-grade implementation of a community-focused marketplace.

## ⚖️ License
Distributed under the MIT License. See `LICENSE` for more information.

