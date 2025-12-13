import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:aplikasiku/app/controllers/transaction_controller.dart';
import 'package:aplikasiku/app/data/services/financial_service.dart';
import 'package:aplikasiku/app/controllers/statistic_controller.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/loading_widget.dart';
// import '../widgets/error_widget.dart';
// import '../widgets/error_boundary.dart';
// import '../../core/errors/app_exception.dart';

/// Halaman detail transaksi yang menampilkan semua informasi transaksi termasuk gambar
class TransactionDetailPage extends GetView<TransactionController> {
  final FinansialModel transaction;

  TransactionDetailPage({super.key, required this.transaction});

  // Shadcn-inspired color palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color primary = Color(0xFF0F172A);
  static const Color accent = Color(0xFFF1F5F9);

  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final receiptHeroTag =
        'receipt-${transaction.id}-${transaction.photoUrl ?? ''}';
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: foreground),
          onPressed: () {
            // Navigate back to previous screen
            if (context.canPop()) {
              context.pop();
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          'Transaction Detail',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan ikon dan amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        controller.getCategoryEmoji(transaction.namaKategori),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.namaKategori,
                          style: TextStyle(fontSize: 14, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.isIncome
                            ? '+${currency.format(transaction.amount)}'
                            : currency.format(transaction.amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              transaction.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: transaction.isIncome
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.isIncome ? 'Income' : 'Expense',
                          style: TextStyle(
                            fontSize: 12,
                            color: transaction.isIncome
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detail Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date', _formatDate(transaction.date)),
                  _buildDetailRow('Category', transaction.namaKategori),
                  _buildDetailRow('Type', transaction.namaJenisKategori),
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty)
                    _buildDetailRow('Description', transaction.description!),
                  _buildDetailRow('ID', transaction.id.toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Image Section
            if (transaction.photoUrl != null &&
                transaction.photoUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showImagePreview(
                        context,
                        transaction.photoUrl!,
                        receiptHeroTag,
                      ),
                      child: Hero(
                        tag: receiptHeroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            transaction.photoUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: accent,
                                child: const Center(
                                  child: AppLoadingWidget(
                                    message: 'Loading image...',
                                    type: LoadingType.circular,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              color: accent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: muted,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showImagePreview(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                // Main content area
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Hero(
                          tag: heroTag,
                          child: InteractiveViewer(
                            maxScale: 4,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: AppLoadingWidget(
                                    message: 'Loading image...',
                                    type: LoadingType.circular,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: muted, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Failed to load image',
                                      style:
                                          TextStyle(color: muted, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Close button in top-left corner
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteTransaction(context);
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    try {
      final financialService = FinansialService();
      await financialService.deleteTransaction(transaction.id as int);

      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Berhasil'),
            description: const Text('Transaksi berhasil dihapus'),
          ),
        );
      }

      // Navigate back and refresh statistics
      if (context.canPop()) {
        context.pop();
      } else {
        Get.back();
      }

      // Refresh statistics if statistic controller is available
      try {
        final statisticController = Get.find<StatisticController>();
        statisticController.fetchStatistics();
      } catch (e) {
        // Statistic controller not available, continue
      }

      // Refresh transactions if transaction controller is available
      try {
        final transactionController = Get.find<TransactionController>();
        transactionController.fetchTransactions(showLoader: true);
      } catch (e) {
        // Transaction controller not available, continue
      }
    } catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal menghapus transaksi: $e'),
          ),
        );
      }
    }
  }
}
