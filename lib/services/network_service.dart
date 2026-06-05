import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();

  /// Checks if the device has an active network connection.
  static Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return false;
      return results.first != ConnectivityResult.none;
    } catch (e) {
      return true; // Default fallback to allow operation attempt
    }
  }

  /// Stream of network connectivity change updates.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
