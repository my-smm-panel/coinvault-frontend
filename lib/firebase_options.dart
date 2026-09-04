import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Firebase options from google-services.json (coinvault-be301, package come.coinvaukt.in)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcyqXjbwtCkwd_FdEbJndHfA6Gk0B8mjI',
    appId: '1:839337325039:android:a147ed9b25c65268fc861a',
    messagingSenderId: '839337325039',
    projectId: 'coinvault-be301',
    storageBucket: 'coinvault-be301.firebasestorage.app',
    databaseURL: 'https://coinvault-be301-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcyqXjbwtCkwd_FdEbJndHfA6Gk0B8mjI',
    appId: '1:839337325039:ios:0000000000000000',
    messagingSenderId: '839337325039',
    projectId: 'coinvault-be301',
    storageBucket: 'coinvault-be301.firebasestorage.app',
    databaseURL: 'https://coinvault-be301-default-rtdb.firebaseio.com',
    iosBundleId: 'come.coinvaukt.in',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcyqXjbwtCkwd_FdEbJndHfA6Gk0B8mjI',
    appId: '1:839337325039:web:0000000000000000',
    messagingSenderId: '839337325039',
    projectId: 'coinvault-be301',
    authDomain: 'coinvault-be301.firebaseapp.com',
    storageBucket: 'coinvault-be301.firebasestorage.app',
    measurementId: 'G-XXXXXXX',
  );
}
