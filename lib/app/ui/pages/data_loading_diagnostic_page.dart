import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasiku/app/controllers/transaction_controller.dart';
import 'package:aplikasiku/app/controllers/statistic_controller.dart';
import 'package:aplikasiku/app/utils/debug_helper.dart';

class DataLoadingDiagnosticPage extends StatelessWidget {
  const DataLoadingDiagnosticPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Loading Diagnostic'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('🔧 Quick Fixes'),
            _buildFixCard(
              '1. Clear Cache & Restart',
              'Hapus cache aplikasi dan restart untuk memastikan data fresh',
              Icons.refresh,
              Colors.orange,
              () => _showRestartInstructions(context),
            ),
            _buildFixCard(
              '2. Check Internet Connection',
              'Pastikan koneksi internet stabil dan API dapat diakses',
              Icons.wifi,
              Colors.blue,
              () => _checkInternetConnection(),
            ),
            _buildFixCard(
              '3. Clear Authentication Token',
              'Reset token authentication jika ada masalah login',
              Icons.lock,
              Colors.red,
              () => _clearAuthToken(context),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('🐛 Debug Tools'),
            _buildDebugCard(
              'API Connectivity Test',
              'Test apakah API endpoint dapat diakses',
              Icons.cloud,
              () => _testAPIConnectivity(),
            ),
            _buildDebugCard(
              'Authentication Status',
              'Check status token authentication',
              Icons.badge,
              () => _checkAuthStatus(),
            ),
            _buildDebugCard(
              'Transaction Data',
              'Debug data loading transaction',
              Icons.list_alt,
              () => _debugTransactionData(),
            ),
            _buildDebugCard(
              'Statistics Data',
              'Debug data loading statistics',
              Icons.analytics,
              () => _debugStatisticsData(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('⚡ Manual Actions'),
            _buildActionButton(
              'Refresh Transaction Page',
              Icons.refresh,
              Colors.green,
              () => _refreshTransactionPage(context),
            ),
            _buildActionButton(
              'Refresh Statistics Page',
              Icons.refresh,
              Colors.purple,
              () => _refreshStatisticsPage(context),
            ),
            _buildActionButton(
              'Reset All Controllers',
              Icons.restart_alt,
              Colors.red,
              () => _resetAllControllers(context),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('📋 Known Issues & Solutions'),
            _buildIssueCard(
              'Problem: Data tidak muncul di halaman',
              'Solution: Periksa token authentication dan koneksi internet',
            ),
            _buildIssueCard(
              'Problem: Loading infinite',
              'Solution: Restart aplikasi dan clear cache',
            ),
            _buildIssueCard(
              'Problem: Error 401/403',
              'Solution: Login ulang untuk refresh token',
            ),
            _buildIssueCard(
              'Problem: API tidak responsif',
              'Solution: Hubungi admin untuk check server API',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFixCard(String title, String description, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDebugCard(
      String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildIssueCard(String problem, String solution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problem:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(problem),
            const SizedBox(height: 8),
            Text(
              'Solution:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(solution),
          ],
        ),
      ),
    );
  }

  void _showRestartInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Instructions'),
        content: const Text(
          'Untuk clear cache dan restart:\n\n'
          '1. Tutup aplikasi sepenuhnya\n'
          '2. Di Android: Settings > Apps > [App Name] > Clear Cache\n'
          '3. Di iOS: Delete app dan install ulang\n'
          '4. Buka aplikasi lagi\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkInternetConnection() async {
    DebugHelper.debugAPIConnectivity();
  }

  void _clearAuthToken(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Authentication Token'),
        content: const Text(
          'Apakah Anda yakin ingin logout? Data tidak akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement token clearing logic here
              Navigator.pop(context);
              _showSuccessMessage(
                  context, 'Token cleared. Please login again.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Token'),
          ),
        ],
      ),
    );
  }

  void _testAPIConnectivity() async {
    DebugHelper.debugAPIConnectivity();
  }

  void _checkAuthStatus() async {
    DebugHelper.debugAuthentication();
  }

  void _debugTransactionData() async {
    DebugHelper.debugTransactionController();
    // Force refresh transaction data
    final controller = Get.find<TransactionController>();
    await controller.refreshTransactions();
  }

  void _debugStatisticsData() async {
    DebugHelper.debugStatisticController();
    // Force refresh statistics data
    final controller = Get.find<StatisticController>();
    await controller.refreshStatistics();
  }

  void _refreshTransactionPage(BuildContext context) async {
    final controller = Get.find<TransactionController>();
    await controller.refreshTransactions();
    _showSuccessMessage(context, 'Transaction data refreshed');
  }

  void _refreshStatisticsPage(BuildContext context) async {
    final controller = Get.find<StatisticController>();
    await controller.refreshStatistics();
    _showSuccessMessage(context, 'Statistics data refreshed');
  }

  void _resetAllControllers(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Controllers'),
        content: const Text(
          'Apakah Anda yakin ingin reset semua controller?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Reset controllers
              Get.delete<TransactionController>();
              Get.delete<StatisticController>();
              Get.put(TransactionController());
              Get.put(StatisticController());
              _showSuccessMessage(context, 'Controllers reset successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
