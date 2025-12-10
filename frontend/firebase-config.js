// Firebase Configuration for Crop AI
// Generated: December 10, 2025
// This file contains placeholder values - replace with actual Firebase project credentials

import { initializeApp } from "firebase/app";
import { getAuth, connectAuthEmulator } from "firebase/auth";
import { getDatabase, connectDatabaseEmulator } from "firebase/database";
import { getMessaging, connectMessagingEmulator } from "firebase/messaging";
import { getStorage, connectStorageEmulator } from "firebase/storage";

// Firebase configuration object
// Get these values from Firebase Console > Project Settings
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY || "YOUR_API_KEY_HERE",
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN || "crop-ai-xxxxx.firebaseapp.com",
  databaseURL: process.env.REACT_APP_FIREBASE_DATABASE_URL || "https://crop-ai-xxxxx.firebaseio.com",
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID || "crop-ai-xxxxx",
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET || "crop-ai-xxxxx.appspot.com",
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID || "xxxxxxxxxxxxx",
  appId: process.env.REACT_APP_FIREBASE_APP_ID || "1:xxxxxxxxxxxxx:web:xxxxxxxxxxxxx",
  measurementId: process.env.REACT_APP_FIREBASE_MEASUREMENT_ID || "G-XXXXXXXXXX"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const database = getDatabase(app);
export const messaging = getMessaging(app);
export const storage = getStorage(app);

// Connect to emulators in development
if (process.env.NODE_ENV === 'development' && process.env.REACT_APP_USE_FIREBASE_EMULATOR === 'true') {
  connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
  connectDatabaseEmulator(database, 'localhost', 9000);
  connectMessagingEmulator(messaging, 'localhost', 5001);
  connectStorageEmulator(storage, 'localhost', 5002);
  console.log('✅ Firebase Emulator Suite connected');
}

export default app;
