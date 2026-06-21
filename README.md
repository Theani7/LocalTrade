# LocalTrade: Nepal's Community Marketplace

LocalTrade is a full-stack mobile marketplace platform designed to empower micro and small businesses in Nepal. It connects local producers — vegetable sellers, handicraft makers, dairy farmers, tailors — directly with their community through a reservation-based ordering system.

## Project Architecture

### Backend (Node.js/Express)
- **Architecture:** Model-View-Controller (MVC)
- **Database:** MongoDB Atlas with Mongoose ODM
- **Security:** JWT-based Authentication, Role-Based Access Control (RBAC), Password Hashing (bcrypt), Helmet security headers
- **Storage:** Cloudinary for image hosting
- **Notifications:** Firebase Admin SDK for push notifications

### Frontend (Flutter)
- **Framework:** Flutter (Material 3)
- **State Management:** Provider pattern
- **Networking:** HTTP package with interceptors for JWT handling
- **Local Storage:** Flutter Secure Storage for tokens, Shared Preferences for user settings

## Technical Setup

### 1. Environment Configuration
1. Navigate to the `backend` directory.
2. Create a `.env` file from `.env.example`:
   ```bash
   cp .env.example .env
   ```
3. Fill in your credentials in the `.env` file (see `backend/.env.example` for details).

### 2. Database Setup (MongoDB Atlas)
1. Create a free cluster at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
2. Under "Network Access", allow access from anywhere (`0.0.0.0/0`).
3. Create a database user with Read and Write permissions.
4. Copy the connection URI (Connect > Drivers) and add it to `.env` as `MONGODB_URI`.

### 3. Image Storage (Cloudinary)
1. Sign up at [Cloudinary](https://cloudinary.com).
2. Copy your Cloud Name, API Key, and API Secret from the dashboard.
3. Add them to your `.env` file.

### 4. Push Notifications (Firebase)
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Go to Project Settings > Service Accounts > Generate New Private Key.
3. Map the JSON values to your `.env` file (Project ID, Client Email, Private Key).
4. Configure the Flutter app:
   ```bash
   flutterfire configure
   ```

## Installation & Running

### Backend
```bash
cd backend
npm install
cp .env.example .env   # then fill in secrets
npm run dev             # runs on http://localhost:5000
```

### Frontend
```bash
cd frontend/localtrade_app
flutter pub get
flutter run              # Chrome for web dev, or connected device
```

Update the API base URL in `lib/core/constants/app_constants.dart` to match your backend.

### Seed Data
```bash
cd backend
node seed-data.js        # populate mock vendors + products
npm run clear:data       # reset database
npm test                 # run tests (in-memory MongoDB)
```

**Default Admin Credentials:**
- Email: `admin@gmail.com`
- Password: `admin123`

## Key Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start backend dev server |
| `npm test` | Run backend tests |
| `npm run clear:data` | Reset database |
| `node seed-data.js` | Seed mock data |
| `flutter run` | Run frontend |
| `flutter analyze` | Lint check frontend |
| `flutter build apk` | Build Android APK |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter, Dart, Provider |
| Backend | Node.js, Express 5, Mongoose |
| Database | MongoDB Atlas |
| Auth | JWT (JSON Web Tokens) |
| Storage | Cloudinary |
| Notifications | Firebase Cloud Messaging |
| Deployment | Render (backend), Flutter build (frontend) |

## License

Distributed under the MIT License. See `LICENSE` for more information.
