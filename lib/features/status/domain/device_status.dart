/// Device status data for monitoring.
/// Read from local device for self, streamed from Firestore for partner.
class DeviceStatus {
  final int batteryPercentage;
  final bool gpsEnabled;
  final bool internetConnected;
  final bool isOnline;
  final DateTime? lastSeen;

  const DeviceStatus({
    required this.batteryPercentage,
    required this.gpsEnabled,
    required this.internetConnected,
    required this.isOnline,
    this.lastSeen,
  });

  factory DeviceStatus.fromMap(Map<String, dynamic> data) {
    return DeviceStatus(
      batteryPercentage: (data['batteryPercentage'] as num?)?.toInt() ?? 0,
      gpsEnabled: data['gpsEnabled'] as bool? ?? false,
      internetConnected: data['internetConnected'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  factory DeviceStatus.empty() {
    return const DeviceStatus(
      batteryPercentage: 0,
      gpsEnabled: false,
      internetConnected: false,
      isOnline: false,
    );
  }
}
