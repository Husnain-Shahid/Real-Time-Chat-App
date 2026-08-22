import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'YOUR_ANDROID_API_KEY',
          appId: '1:000000000000:android:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_IOS_API_KEY',
          appId: '1:000000000000:ios:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
          iosBundleId: 'com.example.firebaseIntegration',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_MACOS_API_KEY',
          appId: '1:000000000000:macos:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
          iosBundleId: 'com.example.firebaseIntegration',
        );
      case TargetPlatform.windows:
        return const FirebaseOptions(
          apiKey: 'YOUR_WINDOWS_API_KEY',
          appId: '1:000000000000:windows:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
        );
      case TargetPlatform.linux:
        return const FirebaseOptions(
          apiKey: 'YOUR_LINUX_API_KEY',
          appId: '1:000000000000:linux:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'YOUR_WEB_API_KEY',
          appId: '1:000000000000:web:0000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-project',
          storageBucket: 'demo-project.appspot.com',
        );
    }
  }
}
