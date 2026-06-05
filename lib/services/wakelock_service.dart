import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockService {
  /// Enables the screen wake lock.
  static Future<void> acquire() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      // Wakelock acquisition exception handled silently
    }
  }

  /// Disables the screen wake lock.
  static Future<void> release() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      // Wakelock release exception handled silently
    }
  }
}
