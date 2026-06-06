import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:welinked/core/constants/app_constants.dart';
import 'package:welinked/firebase_options.dart';
import 'package:welinked/services/battery_service.dart';
import 'package:welinked/services/location_service.dart';
import 'package:welinked/services/network_service.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground Service task handler for background execution.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundUpdateTaskHandler());
}

class BackgroundUpdateTaskHandler extends TaskHandler {
  String? _uid;
  double? _lastLat;
  double? _lastLng;

  int _secondsPassed = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Read user ID from system storage
    final uidData = await FlutterForegroundTask.getData<String>(key: 'uid');
    _uid = uidData;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      // Firebase initialization in background isolate handled safely
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_uid == null) return;

    _secondsPassed += 5; // Repeat interval is 5 seconds

    // 1. Heartbeat check (every 1 minute)
    if (_secondsPassed % AppConstants.heartbeatIntervalSeconds == 0) {
      await _syncHeartbeat();
    }

    // 2. Device status sync (every 2 minutes)
    if (_secondsPassed % AppConstants.statusSyncIntervalSeconds == 0) {
      await _syncDeviceStatus();
    }

    // 3. Location sync (every 5 minutes or 50m movement)
    if (_secondsPassed % AppConstants.locationSyncIntervalSeconds == 0) {
      await _syncLocation(force: true);
    } else if (_secondsPassed % 15 == 0) {
      // Check location movement every 15s
      await _syncLocation(force: false);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Safe fail
      }
    }
  }

  Future<void> _syncHeartbeat() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silent
    }
  }

  Future<void> _syncDeviceStatus() async {
    try {
      final battery = await BatteryService.getBatteryLevel();
      final gps = await Geolocator.isLocationServiceEnabled();
      final internet = await NetworkService.isConnected();

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'batteryPercentage': battery,
        'gpsEnabled': gps,
        'internetConnected': internet,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silent
    }
  }

  Future<void> _syncLocation({required bool force}) async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) return;

      bool shouldUpdate = force;

      if (!shouldUpdate && _lastLat != null && _lastLng != null) {
        final distance = LocationService.calculateDistance(
          _lastLat!,
          _lastLng!,
          position.latitude,
          position.longitude,
        );
        if (distance >= AppConstants.locationMovementThresholdMeters) {
          shouldUpdate = true;
        }
      } else if (!shouldUpdate) {
        shouldUpdate = true; // First lock
      }

      if (shouldUpdate) {
        _lastLat = position.latitude;
        _lastLng = position.longitude;

        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Fail silent
    }
  }
}

class ForegroundServiceManager {
  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.serviceChannelId,
        channelName: AppConstants.serviceChannelName,
        channelDescription: AppConstants.serviceChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000,
        ), // Repeat every 5 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(String uid) async {
    // Write user id to service memory
    await FlutterForegroundTask.saveData(key: 'uid', value: uid);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'WL Active',
        notificationText: 'Everything is Good.',
        callback: startCallback,
      );
    }
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
