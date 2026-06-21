# Deployment Guide - LocalTrade

This guide outlines the steps to deploy the LocalTrade full-stack application to a production environment.

## 1. Backend Deployment (Render / Railway)

### Environment Variables
Ensure the following variables are configured in your hosting dashboard:
- `NODE_ENV`: `production`
- `PORT`: `5000` (or as per host)
- `MONGODB_URI`: Your MongoDB Atlas connection string.
- `JWT_SECRET`: A long, complex string for token signing.
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`: From your Cloudinary dashboard.
- `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL`, etc.: From your Firebase service account JSON.

### Deployment Steps
1. Push the `/backend` folder to a new GitHub repository (or use the monorepo).
2. Connect the repository to **Render** (Web Service) or **Railway**.
3. Set the build command: `npm install`
4. Set the start command: `npm start`

## 2. Database (MongoDB Atlas)
1. Create a new cluster on MongoDB Atlas.
2. Go to "Network Access" and allow your backend IP (or `0.0.0.0/0` for initial setup).
3. Create a database user and copy the connection string.
4. Replace `<password>` in the string with your actual user password.

## 3. Storage (Cloudinary)
1. Sign up for a free account at [Cloudinary](https://cloudinary.com).
2. Copy your **Cloud Name**, **API Key**, and **API Secret** from the dashboard.
3. These are required for the backend image upload middleware to function.

## 4. Notifications (Firebase)
1. Create a new project in the [Firebase Console](https://console.firebase.google.com).
2. Navigate to **Project Settings** > **Service Accounts**.
3. Generate a new private key and download the JSON.
4. Extract the values and add them to your backend environment variables.
5. In the **Firebase Console**, enable **Cloud Messaging**.

## 5. Frontend Deployment (Web)
1. Build the Flutter web app:
   ```bash
   flutter build web
   ```
2. The output will be in `build/web`.
3. Deploy this folder to **Netlify**, **Vercel**, or **GitHub Pages**.

## 6. Frontend Deployment (Android/iOS)
1. Ensure your backend URL in `lib/core/constants/app_constants.dart` is updated to the production URL.
2. Generate an APK/App Bundle:
   ```bash
   flutter build apk --release
   ```
3. Distribute the APK for testing or upload to the Play Store.

