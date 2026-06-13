import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/app_constants.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/core/router/app_router.dart';
import 'package:welinked/features/alerts/data/alert_repository.dart';
import 'package:welinked/features/alerts/domain/alert_model.dart';
import 'package:welinked/features/alerts/presentation/providers/alert_providers.dart';
import 'package:welinked/features/alerts/presentation/screens/full_screen_alert_screen.dart';
import 'package:welinked/features/auth/data/auth_repository.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';

class FcmService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track processed alert IDs to prevent duplicate sound/vibration/notification triggers
  final Set<String> _processedAlertIds = {};
  final Set<String> _notifiedAckAlertIds = {};

  FcmService(this._ref);

  Future<void> initialize() async {
    // 1. Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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

    // 2. Register FCM token and listen for refreshes
    _setupFcmTokenHandling();

    // 3. FCM foreground message handler (app is open)
    FirebaseMessaging.onMessage.listen((message) {
      final alertId = message.data['alertId'];
      if (alertId != null) {
        launchAlertOverlay(alertId);
      }
    });

    // 4. FCM background-tap handler (user tapped notification while app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final alertId = message.data['alertId'];
      if (alertId != null) {
        launchAlertOverlay(alertId);
      }
    });

    // 5. Start client-side Firestore listeners for alerts when authenticated
    _setupClientSideListener();
  }

  void _setupFcmTokenHandling() async {
    final authRepo = _ref.read(authRepositoryProvider);

    // Fetch and store the current FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await authRepo.updateFcmToken(token);
    }

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await authRepo.updateFcmToken(newToken);
    });
  }

  void _setupClientSideListener() {
    _ref.listen<AsyncValue<List<AlertModel>>>(activeAlertsProvider, (
      prevAlerts,
      nextAlerts,
    ) {
      final user = _ref.read(currentUserStreamProvider).value;
      if (user == null) return;

      final alerts = nextAlerts.value;
      if (alerts == null) return;

      for (final alert in alerts) {
        // Case A: Incoming alert from partner in 'created' state
        if (alert.receiverUid == user.uid &&
            alert.status == AlertStatus.created) {
          if (_processedAlertIds.add(alert.alertId)) {
            _triggerIncomingAlert(alert);
          }
        }

        // Case B: Outgoing alert sent by us which is acknowledged by partner
        if (alert.senderUid == user.uid &&
            alert.status == AlertStatus.acknowledged) {
          if (_notifiedAckAlertIds.add(alert.alertId)) {
            _triggerAcknowledgementNotification(alert);
          }
        }
      }
    });
  }

  void _triggerIncomingAlert(AlertModel alert) async {
    // 1. Mark as delivered in Firestore (BUG 2 fix: was markSeen)
    await _ref
        .read(alertControllerProvider)
        .markDelivered(alert.alertId);

    // 2. Trigger local notification
    await _showLocalNotification(
      id: alert.alertId.hashCode,
      title: '${alert.alertType.title} RECEIVED!',
      body: 'Tap to view attention alert.',
      payload: jsonEncode({'alertId': alert.alertId}),
      channelId: AppConstants.alertChannelId,
      channelName: AppConstants.alertChannelName,
      channelDescription: AppConstants.alertChannelDescription,
    );

    // 3. Launch full screen overlay immediately (if app context is available)
    launchAlertOverlay(alert.alertId);
  }

  void _triggerAcknowledgementNotification(AlertModel alert) async {
    // Fetch partner name
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(alert.receiverUid)
        .get();
    final partnerName = senderDoc.data()?['name'] ?? 'Duo';

    await _showLocalNotification(
      id: alert.alertId.hashCode + 1,
      title: 'Alert Acknowledged!',
      body:
          '$partnerName acknowledged your ${alert.alertType.name.toUpperCase()} alert.',
      payload: jsonEncode({'alertId': alert.alertId}),
      channelId: AppConstants.ackChannelId,
      channelName: AppConstants.ackChannelName,
      channelDescription: AppConstants.ackChannelDescription,
    );
  }

  void _handleMessagePayload(Map<String, dynamic> data) {
    final alertId = data['alertId'];
    if (alertId != null) {
      launchAlertOverlay(alertId);
    }
  }

  void launchAlertOverlay(String alertId) async {
    final alert = await _ref.read(alertRepositoryProvider).getAlert(alertId);
    if (alert == null) return;

    // Fetch sender profile details to display their name
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(alert.senderUid)
        .get();
    final senderName = senderDoc.data()?['name'] ?? 'Duo';

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          fullscreenDialog: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              FullScreenAlertScreen(alert: alert, senderName: senderName),
        ),
      );
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final isAlert = channelId == AppConstants.alertChannelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      category: isAlert ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.msg,
      audioAttributesUsage: isAlert ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      additionalFlags: isAlert ? Int32List.fromList(<int>[4]) : null, // FLAG_INSISTENT
    );
    final details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});
