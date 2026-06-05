import 'package:geolocator/geolocator.dart';
import 'package:welinked/core/utils/permission_utils.dart';

class LocationService {
  /// Fetches the current device location (high accuracy).
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await PermissionUtils.isLocationPermissionGranted();
    if (!hasPermission) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculates the distance (in meters) between two coordinates.
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
