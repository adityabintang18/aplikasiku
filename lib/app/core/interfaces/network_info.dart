// Network information interface for connectivity checking
import 'dart:async';

/// Network information interface for connectivity checking
abstract class NetworkInfo {
  /// Check if device is connected to network
  Future<bool> get isConnected;

  /// Stream of connectivity status changes
  Stream<bool> get isConnectedStream;

  /// Get current connection type
  Future<ConnectionType> get connectionType;

  /// Stream of connection type changes
  Stream<ConnectionType> get connectionTypeStream;

  /// Check if currently connected via WiFi
  Future<bool> get isConnectedToWiFi;

  /// Check if currently connected via mobile data
  Future<bool> get isConnectedToMobileData;

  /// Check if internet is reachable (actual connectivity test)
  Future<bool> get isInternetReachable;

  /// Stream of internet reachability status
  Stream<bool> get isInternetReachableStream;
}

/// Types of network connections
enum ConnectionType {
  /// No network connection
  none,

  /// Connected via WiFi
  wifi,

  /// Connected via mobile data
  mobile,

  /// Connected via ethernet (desktop platforms)
  ethernet,

  /// Connected via VPN
  vpn,

  /// Unknown connection type
  unknown,
}

/// Network connectivity result
class NetworkConnectivityResult {
  final bool isConnected;
  final ConnectionType connectionType;
  final bool isInternetReachable;
  final DateTime timestamp;

  const NetworkConnectivityResult({
    required this.isConnected,
    required this.connectionType,
    required this.isInternetReachable,
    required this.timestamp,
  });

  /// Create result for connected state
  factory NetworkConnectivityResult.connected(ConnectionType type) {
    return NetworkConnectivityResult(
      isConnected: true,
      connectionType: type,
      isInternetReachable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Create result for disconnected state
  factory NetworkConnectivityResult.disconnected() {
    return NetworkConnectivityResult(
      isConnected: false,
      connectionType: ConnectionType.none,
      isInternetReachable: false,
      timestamp: DateTime.now(),
    );
  }

  /// Check if this is a WiFi connection
  bool get isWiFi => connectionType == ConnectionType.wifi;

  /// Check if this is a mobile data connection
  bool get isMobile => connectionType == ConnectionType.mobile;

  /// Check if this is ethernet connection
  bool get isEthernet => connectionType == ConnectionType.ethernet;

  /// Get human-readable connection description
  String get description {
    if (!isConnected) return 'No connection';
    if (isWiFi) return 'Connected via WiFi';
    if (isMobile) return 'Connected via mobile data';
    if (isEthernet) return 'Connected via ethernet';
    return 'Connected ($connectionType)';
  }

  @override
  String toString() {
    return 'NetworkConnectivityResult(isConnected: $isConnected, type: $connectionType, reachable: $isInternetReachable, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkConnectivityResult &&
        other.isConnected == isConnected &&
        other.connectionType == connectionType &&
        other.isInternetReachable == isInternetReachable;
  }

  @override
  int get hashCode {
    return isConnected.hashCode ^
        connectionType.hashCode ^
        isInternetReachable.hashCode;
  }
}
