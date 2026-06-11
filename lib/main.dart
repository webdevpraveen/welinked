import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/app.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/services/fcm_service.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:welinked/core/constants/app_constants.dart';
import 'package:welinked/services/foreground_service.dart';
import 'package:welinked/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final alertId = message.data['alertId'];
  if (alertId != null) {
    final alertType = message.data['alertType']?.toString().toUpperCase() ?? 'ATTENTION';
    final senderName = message.data['senderName'] ?? 'Duo';

    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = const InitializationSettings(android: androidSettings);
    await localNotifications.initialize(settings: initSettings);

    final androidDetails = AndroidNotificationDetails(
      AppConstants.alertChannelId,
      AppConstants.alertChannelName,
      channelDescription: AppConstants.alertChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
    );

    await localNotifications.show(
      id: alertId.hashCode,
      title: '$alertType ALERT RECEIVED!',
      body: '$senderName sent you an alert. Tap to view.',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({'alertId': alertId}),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
