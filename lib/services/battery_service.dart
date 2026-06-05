import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  static final Battery _battery = Battery();

  /// Gets the current battery level (percentage).
  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 100; // Default fallback
    }
  }
}
