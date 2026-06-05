import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Permission request and check utilities.
/// Handles all required Android permissions for WeLinked.
class PermissionUtils {
  PermissionUtils._();

  /// Requests all critical permissions needed for the app.
  /// Returns true if all essential permissions are granted.
  static Future<bool> requestAllPermissions() async {
    final statuses = await [
      Permission.notification,
      Permission.location,
      Permission.locationAlways,
    ].request();

    final notificationGranted = statuses[Permission.notification]?.isGranted ?? false;
    final locationGranted = statuses[Permission.location]?.isGranted ?? false;

    return notificationGranted && locationGranted;
  }

  /// Check if notification permission is granted.
  static Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Check if location permission is granted.
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  /// Check if background location permission is granted.
  static Future<bool> isBackgroundLocationPermissionGranted() async {
    return await Permission.locationAlways.isGranted;
  }

  /// Request notification permission.
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request foreground location permission.
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request background location permission.
  /// Must be called AFTER foreground location is granted.
  static Future<bool> requestBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Request to ignore battery optimizations (critical for Xiaomi/Redmi).
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Check if battery optimization is ignored.
  static Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Opens the app settings page for manual permission management.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get a summary of all permission statuses.
  static Future<Map<String, bool>> getPermissionSummary() async {
    return {
      'Notifications': await Permission.notification.isGranted,
      'Location': await Permission.location.isGranted,
      'Background Location': await Permission.locationAlways.isGranted,
      'Battery Optimization': await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  /// Check if the device is likely a Xiaomi/Redmi device.
  static bool isXiaomiDevice() {
    if (Platform.isAndroid) {
      // Manufacturer detection happens at the Android native level.
      // This is a simplified check — the settings screen will show
      // Xiaomi-specific guidance regardless.
      return true; // Show guidance for all devices to be safe.
    }
    return false;
  }
}
