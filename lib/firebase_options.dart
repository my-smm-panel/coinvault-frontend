import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Fallback Firebase options - prevents white screen when google-services.json missing.
/// Real config is in android/app/google-services.json (Firebase console: coinvault-be301)
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
    apiKey: 'AIzaSyDummy_CoinVault_Fallback_Key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'coinvault-be301',
    storageBucket: 'coinvault-be301.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummy_CoinVault_Fallback_Key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'coinvault-be301',
    storageBucket: 'coinvault-be301.appspot.com',
    iosBundleId: 'com.coinvault.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummy_CoinVault_Fallback_Key',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'coinvault-be301',
    authDomain: 'coinvault-be301.firebaseapp.com',
    storageBucket: 'coinvault-be301.appspot.com',
  );
}
