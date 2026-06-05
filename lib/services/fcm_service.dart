import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/app_constants.dart';
import 'package:welinked/core/router/app_router.dart';
import 'package:welinked/features/alerts/data/alert_repository.dart';
import 'package:welinked/features/alerts/presentation/screens/full_screen_alert_screen.dart';
import 'package:welinked/features/auth/data/auth_repository.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Background message handler for FCM. Must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Just log or handle data. The Android Native BootReceiver and ForegroundService
  // handle waking the app.
}

class FcmService {
  final FirebaseMessaging _fcm;
  final AuthRepository _authRepo;
  final AlertRepository _alertRepo;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FcmService(this._fcm, this._authRepo, this._alertRepo);

  Future<void> initialize() async {
    // 1. Request notifications permission
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // 2. Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;
          _handleMessagePayload(data);
        }
      },
    );

    // 3. Register token updates
    _setupTokenSync();

    // 4. Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 5. App opened from background notification tap listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 6. Check if app was opened from terminated state by notification tap
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _setupTokenSync() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _authRepo.updateFcmToken(token);
    }

    _fcm.onTokenRefresh.listen((newToken) async {
      await _authRepo.updateFcmToken(newToken);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final alertId = data['alertId'];

    if (alertId != null) {
      // It is a partner alert! Trigger Full Screen overlay immediately.
      _launchAlertOverlay(alertId);
    } else {
      // Ordinary notification (e.g. acknowledgment)
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'WeLinked Notification',
          body: notification.body ?? '',
          payload: jsonEncode(data),
        );
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handleMessagePayload(message.data);
  }

  void _handleMessagePayload(Map<String, dynamic> data) {
    final alertId = data['alertId'];
    if (alertId != null) {
      _launchAlertOverlay(alertId);
    }
  }

  void _launchAlertOverlay(String alertId) async {
    final alert = await _alertRepo.getAlert(alertId);
    if (alert == null) return;

    // Fetch sender profile details to display their name
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(alert.senderUid)
        .get();
    final senderName = senderDoc.data()?['name'] ?? 'Partner';

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullScreenAlertScreen(
            alert: alert,
            senderName: senderName,
          ),
        ),
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.ackChannelId,
      AppConstants.ackChannelName,
      channelDescription: AppConstants.ackChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(alertRepositoryProvider),
  );
});
