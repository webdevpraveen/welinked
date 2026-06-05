import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/app.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/services/fcm_service.dart';
import 'package:welinked/services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Set background messaging handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 3. Initialize background foreground service manager
  ForegroundServiceManager.initService();

  runApp(
    const ProviderScope(
      child: AppStartupWrapper(),
    ),
  );
}

class AppStartupWrapper extends ConsumerStatefulWidget {
  const AppStartupWrapper({super.key});

  @override
  ConsumerState<AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends ConsumerState<AppStartupWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAppServices();
  }

  Future<void> _initializeAppServices() async {
    // We initialize FCM message handling and listeners
    final fcmService = ref.read(fcmServiceProvider);
    await fcmService.initialize();
    
    // Monitor user authentication transitions to handle background service activation/deactivation
    ref.listenManual(currentUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        // Start Background Foreground sync updates
        ForegroundServiceManager.start(user.uid);
      } else {
        // Stop updates
        ForegroundServiceManager.stop();
      }
    });

    // Check startup status of current session
    final initialUser = ref.read(currentUserStreamProvider).value;
    if (initialUser != null) {
      ForegroundServiceManager.start(initialUser.uid);
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Wrap with WithForegroundTask so the plugin can monitor task status overlays
    return const WithForegroundTask(
      child: WeLinkedApp(),
    );
  }
}
