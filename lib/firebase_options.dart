import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDDZXacUJyTKWm6t04lWvix4_WO1qrlgXM",
    authDomain: "lexup-knth.firebaseapp.com",
    projectId: "lexup-knth",
    storageBucket: "lexup-knth.firebasestorage.app",
    messagingSenderId: "1091391650743",
    appId: "1:1091391650743:web:d6780bc521373ef4ec4632",
    measurementId: "G-YEXT795GTL",
  );
}
