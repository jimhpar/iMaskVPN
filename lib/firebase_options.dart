import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7PIQZ_3ADDhlMsmDG0OsYfPbHFjT0zOw',
    appId: '1:987280937545:web:7d853a362ceb7e9b196598',
    messagingSenderId: '987280937545',
    projectId: 'imaskvpn',
    authDomain: 'imaskvpn.firebaseapp.com',
    storageBucket: 'imaskvpn.firebasestorage.app',
    measurementId: 'G-VC4PC06YY1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD7PIQZ_3ADDhlMsmDG0OsYfPbHFjT0zOw',
    appId: '1:987280937545:web:7d853a362ceb7e9b196598',
    messagingSenderId: '987280937545',
    projectId: 'imaskvpn',
    authDomain: 'imaskvpn.firebaseapp.com',
    storageBucket: 'imaskvpn.firebasestorage.app',
    measurementId: 'G-VC4PC06YY1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7PIQZ_3ADDhlMsmDG0OsYfPbHFjT0zOw',
    appId: '1:987280937545:web:7d853a362ceb7e9b196598',
    messagingSenderId: '987280937545',
    projectId: 'imaskvpn',
    authDomain: 'imaskvpn.firebaseapp.com',
    storageBucket: 'imaskvpn.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD7PIQZ_3ADDhlMsmDG0OsYfPbHFjT0zOw',
    appId: '1:987280937545:ios:7d853a362ceb7e9b',
    messagingSenderId: '987280937545',
    projectId: 'imaskvpn',
    authDomain: 'imaskvpn.firebaseapp.com',
    storageBucket: 'imaskvpn.firebasestorage.app',
    iosBundleId: 'com.imask.vpn.imaskVpn',
  );
}

