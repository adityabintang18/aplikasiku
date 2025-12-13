import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class DebugHelper {
  static final Logger _logger = Logger();

  static Future<void> debugAPIConnectivity() async {
    _logger.w('=== DEBUGGING API CONNECTIVITY ===');

    try {
      // 1. Check environment variables
      final apiUrl = dotenv.env['API_BASE_URL'];
      _logger.i('API_BASE_URL: $apiUrl');

      if (apiUrl == null || apiUrl.isEmpty) {
        _logger.e('API_BASE_URL is null or empty');
        return;
      }

      // 2. Test basic connectivity
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      _logger.i('Testing connection to: $apiUrl');

      final response = await dio.get('$apiUrl/health');
      _logger.i('Health check response: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('DioException occurred:');
      _logger.e('Message: ${e.message}');
      _logger.e('Response: ${e.response}');
      _logger.e('Request: ${e.requestOptions}');
    } catch (e) {
      _logger.e('General exception: $e');
    }

    _logger.w('=== END API DEBUG ===');
  }

  static Future<void> debugAuthentication() async {
    _logger.w('=== DEBUGGING AUTHENTICATION ===');

    try {
      // Check if token exists
      final token = await _getStoredToken();
      _logger.i(
          'Stored token: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}');

      if (token != null) {
        _logger.i(
            'Token preview: ${token.substring(0, _min(20, token.length))}...');
      }
    } catch (e) {
      _logger.e('Error debugging auth: $e');
    }

    _logger.w('=== END AUTH DEBUG ===');
  }

  static Future<String?> _getStoredToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'token');
  }

  static void debugTransactionController() {
    _logger.w('=== DEBUGGING TRANSACTION CONTROLLER ===');
    _logger.i('Controller methods to check:');
    _logger.i('- onInit() - fetches transaction types and transactions');
    _logger.i('- onReady() - calls _loadInitialData()');
    _logger.i('- fetchTransactions() - main data fetching method');
    _logger
        .i('- fetchTransactionTypes() - fetches available transaction types');
    _logger.w('=== END CONTROLLER DEBUG ===');
  }

  static void debugStatisticController() {
    _logger.w('=== DEBUGGING STATISTIC CONTROLLER ===');
    _logger.i('Controller methods to check:');
    _logger.i('- onInit() - immediately calls fetchStatistics()');
    _logger.i('- fetchStatistics() - fetches overview data from API');
    _logger.i(
        '- getStatistics() in FinansialService - calls /statistics/overview endpoint');
    _logger.w('=== END STATISTIC DEBUG ===');
  }

  static int _min(int a, int b) => a < b ? a : b;
}
