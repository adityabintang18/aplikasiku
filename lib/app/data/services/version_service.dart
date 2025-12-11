import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'base_api_service.dart';

class VersionService extends BaseApiService {
  final Logger _logger = Logger();
  static String? _cachedVersion;

  /// Check if app update is required
  Future<Map<String, dynamic>> checkForUpdate({
    required String platform,
    required String currentVersion,
  }) async {
    try {
      _logger.i('VersionService: Checking for updates');
      _logger.i(
        'VersionService: Platform: $platform, Current version: $currentVersion',
      );

      final response = await client.get(
        '$baseUrl/api/version/check',
        queryParameters: {'platform': platform, 'version': currentVersion},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _logger.i(
          'VersionService: Update check result: ${data['requiredUpdate']}',
        );

        return {
          'success': true,
          'requiredUpdate': data['requiredUpdate'] ?? false,
          'storeUrl': data['storeUrl'] ?? '',
          'apkUrl': data['apkUrl'] ?? '',
          'message': data['message'] ?? '',
        };
      } else {
        _logger.w(
          'VersionService: Update check failed with status ${response.statusCode}',
        );
        return {
          'success': false,
          'requiredUpdate': false,
          'message': 'Failed to check for updates',
        };
      }
    } catch (e) {
      _logger.e('VersionService: Error checking for updates: $e');
      return {
        'success': false,
        'requiredUpdate': false,
        'message': 'Error checking for updates: ${e.toString()}',
      };
    }
  }

  /// Get current app version from pubspec.yaml (canonical source)
  Future<String> getCurrentVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = '${packageInfo.version}+${packageInfo.buildNumber}';

      _logger.d('VersionService: Current version from pubspec: $version');
      _logger.d('VersionService: Version name: ${packageInfo.version}');
      _logger.d('VersionService: Build number: ${packageInfo.buildNumber}');

      _cachedVersion = version;
      return version;
    } catch (e) {
      _logger.e('VersionService: Error getting current version: $e');
      // Fallback to a default version
      const fallbackVersion = '1.0.0+1';
      _logger.w('VersionService: Using fallback version: $fallbackVersion');
      _cachedVersion = fallbackVersion;
      return fallbackVersion;
    }
  }

  /// Get just the version name (without build number) for API compatibility
  Future<String> getVersionName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      _logger.e('VersionService: Error getting version name: $e');
      return '1.0.0';
    }
  }

  /// Get just the build number for display
  Future<String> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      _logger.e('VersionService: Error getting build number: $e');
      return '1';
    }
  }

  /// Clear cached version (useful for testing or when version might change)
  static void clearCachedVersion() {
    _cachedVersion = null;
  }

  static Map<String, String> parseVersion(String version) {
    final parts = version.split('+');
    return {
      'versionName': parts[0],
      'buildNumber': parts.length > 1 ? parts[1] : '1',
    };
  }

  /// Compare versions
  static int compareVersions(String version1, String version2) {
    final v1Parts = parseVersion(version1);
    final v2Parts = parseVersion(version2);

    final v1Name = v1Parts['versionName']!;
    final v2Name = v2Parts['versionName']!;

    final v1Build = int.parse(v1Parts['buildNumber']!);
    final v2Build = int.parse(v2Parts['buildNumber']!);

    // Compare version name first
    final nameComparison = v1Name.compareTo(v2Name);
    if (nameComparison != 0) {
      return nameComparison;
    }

    // If version names are equal, compare build numbers
    return v1Build.compareTo(v2Build);
  }
}
