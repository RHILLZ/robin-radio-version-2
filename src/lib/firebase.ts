import { initializeApp } from 'firebase/app';
import { getStorage } from 'firebase/storage';

/**
 * Web client config for the existing `robin-radio` Firebase project
 * (ported from the Flutter app's firebase_options.dart). These values are
 * public client identifiers, not secrets; access is governed by Storage
 * security rules.
 */
export const STORAGE_BUCKET = 'robin-radio.appspot.com';

const firebaseConfig = {
  apiKey: 'AIzaSyDlbLmYeHkIPOX2JELO7rqlKXmkZrfAsnM',
  authDomain: 'robin-radio.firebaseapp.com',
  projectId: 'robin-radio',
  storageBucket: STORAGE_BUCKET,
  messagingSenderId: '275246812933',
  appId: '1:275246812933:web:0490a71d657c7bf66c316c',
};

export const firebaseApp = initializeApp(firebaseConfig);
export const storage = getStorage(firebaseApp);
