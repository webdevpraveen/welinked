import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBleKSaFJ_moLFpRV8uXmWoLoTcWh4fe-g',
    appId: '1:957540187053:android:957dfc29e86095867dff24',
    messagingSenderId: '957540187053',
    projectId: 'wdp-welinked',
    storageBucket: 'wdp-welinked.firebasestorage.app',
  );
}
