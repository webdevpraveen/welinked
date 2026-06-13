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
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
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
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    await localNotifications.show(
      id: alertId.hashCode,
      title: '$alertType ALERT RECEIVED!',
      body: '$senderName sent you an alert. Tap to view.',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({'alertId': alertId}),
    );

    // Save alert ID to be handled when app opens
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_alert_id', alertId);

    // Force app to foreground (Truecaller-like popup)
    FlutterForegroundTask.wakeUpScreen();
    
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'com.wdp.welinked.ACTION_WAKE_ALARM',
        package: 'com.wdp.welinked',
      );
      try {
        await intent.sendBroadcast();
      } catch (e) {
        debugPrint('Failed to send broadcast intent: $e');
        FlutterForegroundTask.launchApp();
      }
    } else {
      FlutterForegroundTask.launchApp();
    }
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
      final prevUid = previous?.value?.uid;
      final nextUid = next.value?.uid;
      
      // ONLY start/stop the service if the authentication state (UID) actually changed!
      if (prevUid != nextUid) {
        if (nextUid != null) {
          // Start Background Foreground sync updates
          ForegroundServiceManager.start(nextUid);
        } else {
          // Stop updates
          ForegroundServiceManager.stop();
        }
      }
    });

    // Check startup status of current session
    final initialUser = ref.read(currentUserStreamProvider).value;
    if (initialUser != null) {
      ForegroundServiceManager.start(initialUser.uid);
    }

    // Check for any pending alerts from background wakeups
    final prefs = await SharedPreferences.getInstance();
    final pendingAlertId = prefs.getString('pending_alert_id');
    if (pendingAlertId != null) {
      await prefs.remove('pending_alert_id');
      Future.delayed(const Duration(milliseconds: 800), () {
        fcmService.launchAlertOverlay(pendingAlertId);
      });
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
