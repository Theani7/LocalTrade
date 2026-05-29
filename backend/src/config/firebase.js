const admin = require('firebase-admin');

/**
 * Firebase Admin SDK Initialization
 * This setup uses environment variables to initialize the Admin SDK.
 * If credentials are missing, it logs a warning but allows the backend 
 * to continue running (graceful degradation).
 */

try {
  const firebaseConfig = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY 
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') 
      : undefined,
  };

  // Only initialize if all core credentials are present
  if (firebaseConfig.projectId && firebaseConfig.clientEmail && firebaseConfig.privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert(firebaseConfig),
    });
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.warn('⚠️ Firebase credentials incomplete. Push notifications will be disabled.');
  }
} catch (error) {
  console.error('❌ Firebase Admin initialization error:', error.message);
}

module.exports = admin;
