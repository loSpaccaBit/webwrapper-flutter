import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Stream of connectivity status
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Initialize connectivity monitoring
  void initialize() {
    // Check initial connectivity
    checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      return _updateConnectionStatus(results);
    } catch (e) {
      return false;
    }
  }

  /// Update connection status based on connectivity results
  bool _updateConnectionStatus(List<ConnectivityResult> results) {
    // Considera connesso se c'è almeno un tipo di connessione diverso da "none"
    final bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn ||
      result == ConnectivityResult.bluetooth ||
      result == ConnectivityResult.other
    );

    _connectionStatusController.add(isConnected);
    return isConnected;
  }

  /// Check if currently connected
  Future<bool> get isConnected async {
    return await checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}
