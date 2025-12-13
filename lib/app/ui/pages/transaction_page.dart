import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/controllers/transaction_controller.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:aplikasiku/app/ui/widgets/loading_widget.dart';
import 'package:aplikasiku/app/ui/widgets/error_widget.dart';
import 'package:aplikasiku/app/ui/widgets/error_boundary.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';

class TransactionPage extends GetView<TransactionController> {
  final logger = Logger();

  // Shadcn-inspired color palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Buffer filter state untuk modal filter UI (sementara, diterapkan saat tekan Terapkan)
  final RxString filterTypeBuffer = 'all'.obs;
  final RxString transactionTypeFilterBuffer = 'all'.obs;

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildFilterBar(context),
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 16),
                _buildTabContent(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('TransactionPage build called');

    // Auto trigger data loading when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageEnter();
    });

    return SafeArea(
      child: ErrorBoundary(
        onError: (context, error, stack) => AppErrorWidget(
          error: error as AppException,
          onRetry: () => controller.refreshTransactions(),
        ),
        child: Obx(() {
          // Initial loading state
          if (controller.isInitialLoading.value) {
            return const AppLoadingWidget(
              message: 'Loading transactions...',
              type: LoadingType.transactionPage,
            );
          }

          logger.i(
            'TransactionPage Obx rebuild - isLoading: ${controller.isLoading.value}, transactions: ${controller.transactions.length}, transactionTypes: ${controller.transactionTypes.length}',
          );

          // Show loading only if we're actively loading and have no data yet
          if (controller.isLoading.value && controller.transactions.isEmpty) {
            logger.i('Showing initial loading state');
            return const Center(
              child: AppLoadingWidget(
                message: 'Loading transactions...',
                type: LoadingType.circular,
              ),
            );
          }

          // If we have transactions but still loading (refresh), show content with refresh indicator
          if (controller.isLoading.value &&
              controller.transactions.isNotEmpty) {
            logger.i('Showing content with refresh indicator');
            return Stack(
              children: [
                _buildMainContent(context),
                Positioned(
                  top: 10,
                  left: MediaQuery.of(context).size.width / 2 - 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          logger.i('Showing main content');
          return _buildMainContent(context);
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Transactions',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        // Month Selector
        Expanded(
          child: GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(
                      () => Text(
                        DateFormat(
                          'MMMM yyyy',
                          'id_ID',
                        ).format(controller.selectedMonth.value),
                        style: TextStyle(
                          fontSize: 14,
                          color: foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter Button
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(() {
            final isTypesLoading = controller.isTransactionTypesLoading.value;
            return IconButton(
              onPressed:
                  isTypesLoading ? null : () => _showFilterModal(context),
              icon: isTypesLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: AppLoadingWidget(
                        type: LoadingType.button,
                        size: 16,
                      ),
                    )
                  : Icon(Icons.filter_list_rounded, color: foreground),
              padding: const EdgeInsets.all(12),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Obx(
      () => ShadTabs<String>(
        value: controller.currentTabIndex.value == 0 ? 'daily' : 'monthly',
        onChanged: (value) {
          final index = value == 'daily' ? 0 : 1;
          controller.changeTab(index);
        },
        tabs: const [
          ShadTab(value: 'daily', child: Text('Daily')),
          ShadTab(value: 'monthly', child: Text('Monthly')),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Obx(() {
      final currentTab = controller.currentTabIndex.value;
      if (currentTab == 0) {
        return _buildDailyView(context);
      } else {
        return _buildMonthlyView();
      }
    });
  }

  Widget _buildDailyView(BuildContext context) {
    // always wrap in Obx to listen to transactionTypeFilter changes
    return Obx(() {
      final groupedTransactions = controller.groupedTransactionsByDate;

      if (groupedTransactions.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Text(
            "No transactions found",
            style: TextStyle(color: muted, fontSize: 16),
          ),
        );
      }

      return Column(
        children: controller.groupedTransactionsByDate.entries.map((entry) {
          return _buildTransactionGroup(entry.key, entry.value, context);
        }).toList(),
      );
    });
  }

  Widget _buildTransactionGroup(
    DateTime date,
    List<FinansialModel> transactions,
    BuildContext context,
  ) {
    final total = transactions.fold<double>(
      0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(date),
              style: TextStyle(fontSize: 14, color: muted),
            ),
            Text(
              total >= 0
                  ? '+${currency.format(total)}'
                  : currency.format(total),
              style: TextStyle(
                fontSize: 14,
                color: total >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(transactions.length, (index) {
              final transaction = transactions[index];
              final isLast = index == transactions.length - 1;
              return Column(
                children: [
                  _buildTransactionItem(context, transaction),
                  if (!isLast)
                    Container(
                      height: 1,
                      color: border,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Di detail: baris kedua mengganti jam menjadi kategori
  /// dan badge menjadi jenis transaksi-nya
  Widget _buildTransactionItem(
    BuildContext context,
    FinansialModel transaction,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail page with transaction data; push agar bisa back
        context.push('/transaction-detail', extra: transaction);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  controller.getCategoryEmoji(transaction.namaKategori),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Kategori transaksi: tampilkan namaKategori
                      Text(
                        transaction.namaKategori,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 80),
              child: Text(
                transaction.isIncome
                    ? '+${currency.format(transaction.amount)}'
                    : currency.format(transaction.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final breakdown = controller.getMonthlyCategoryBreakdown();
    final categories = breakdown['categories'] as List<Map<String, dynamic>>;
    final totalExpenses = breakdown['totalExpenses'] as double;

    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoadingWidget(
          message: 'Loading monthly data...',
          type: LoadingType.transactionPage,
        );
      }

      return Column(
        children: [
          // Total Expenses Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(totalExpenses),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'vs Last Month',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                    // Untuk production, hitung persentase naik/turun dibanding bulan sebelumnya (TODO).
                    const Text(
                      '-',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Category Breakdown
          if (categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Text(
                "No expenses found for this month",
                style: TextStyle(color: muted, fontSize: 16),
              ),
            )
          else
            ...categories.map((category) => _buildCategoryItem(category)),
        ],
      );
    });
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                category['icon'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category['category'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                    Text(
                      currency.format(category['amount']),
                      style: TextStyle(fontSize: 14, color: foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (category['percentage'] / 100).clamp(
                            0.0,
                            1.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category['percentage']}%',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Month Picker menggunakan StatefulBuilder agar picker berubah interaktif
  Future<void> _showMonthPicker(BuildContext context) async {
    final int initialYear = controller.selectedMonth.value.year;
    final int initialMonth = controller.selectedMonth.value.month;
    int selectedYear = initialYear;
    int selectedMonth = initialMonth;
    final List<int> years = List.generate(2030 - 2020 + 1, (i) => 2020 + i);
    final List<int> months = List.generate(12, (i) => i + 1);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Bulan dan Tahun'),
          content: StatefulBuilder(
            builder: (ctx, setState) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Month Dropdown
                DropdownButton<int>(
                  value: selectedMonth,
                  onChanged: (month) {
                    if (month != null) {
                      setState(() {
                        selectedMonth = month;
                      });
                    }
                  },
                  items: months.map((m) {
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text(
                        DateFormat.MMMM('id_ID').format(DateTime(0, m)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                // Year Dropdown
                DropdownButton<int>(
                  value: selectedYear,
                  onChanged: (y) {
                    if (y != null) {
                      setState(() {
                        selectedYear = y;
                      });
                    }
                  },
                  items: years.map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.setMonth(DateTime(selectedYear, selectedMonth));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }

  // MODIFIED: Buffer, Terapkan hanya setelah klik Terapkan
  void _showFilterModal(BuildContext context) {
    if (!context.mounted) return;

    filterTypeBuffer.value = controller.filterType.value;
    transactionTypeFilterBuffer.value = controller.transactionTypeFilter.value;

    if (controller.transactionTypes.isEmpty &&
        !controller.isTransactionTypesLoading.value) {
      controller.fetchTransactionTypes();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: muted),
                  ),
                ],
              ),

              // Transaction Type Filter (Income/Expense)
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipe Transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              filterTypeBuffer.value = 'all';
                            },
                            child: _buildModalFilterChipBuffered(
                              'all',
                              'Semua',
                              filterTypeBuffer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              filterTypeBuffer.value = 'income';
                            },
                            child: _buildModalFilterChipBuffered(
                              'income',
                              'Income',
                              filterTypeBuffer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              filterTypeBuffer.value = 'expense';
                            },
                            child: _buildModalFilterChipBuffered(
                              'expense',
                              'Expense',
                              filterTypeBuffer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transaction Category Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jenis Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (controller.isTransactionTypesLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: AppLoadingWidget(
                            type: LoadingType.circular,
                            message: 'Loading transaction types...',
                          ),
                        ),
                      );
                    }
                    final types = controller.transactionTypes;
                    if (types.isEmpty) {
                      return const Text(
                        'Jenis transaksi belum tersedia. Coba kembali nanti.',
                      );
                    }
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildModalTransactionTypeChipBuffered(
                          'all',
                          'Semua',
                          transactionTypeFilterBuffer,
                        ),
                        ...types.map(
                          (type) => _buildModalTransactionTypeChipBuffered(
                            type['id'].toString(),
                            type['nama'] ?? type['name'] ?? 'Unknown',
                            transactionTypeFilterBuffer,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset buffer ke kondisi awal
                        filterTypeBuffer.value = 'all';
                        transactionTypeFilterBuffer.value = 'all';

                        // Untuk UX: reset filter utama juga dan bulan ke bulan sekarang
                        controller.resetFilters();
                        controller.setMonth(DateTime.now());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Reset', style: TextStyle(color: foreground)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      onPressed: () {
                        // Saat klik Terapkan, baru copy buffer ke filter utama
                        controller.setFilterType(filterTypeBuffer.value);
                        controller.setTransactionTypeFilter(
                          transactionTypeFilterBuffer.value,
                        );
                        // Don't call refreshTransactions here as setTransactionTypeFilter doesn't fetch from backend
                        // The filtering happens client-side in filteredTransactions getter
                        Navigator.pop(context);
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CHIP VERSI BUFFER untuk filterType
  Widget _buildModalFilterChipBuffered(
    String value,
    String label,
    RxString bufferValue,
  ) {
    final bool isSelected = bufferValue.value == value;
    return GestureDetector(
      onTap: () {
        bufferValue.value = value;
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 0, maxWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : background,
          border: Border.all(color: isSelected ? primary : border),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? primaryForeground : foreground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // CHIP VERSI BUFFER untuk transactionTypeFilter
  Widget _buildModalTransactionTypeChipBuffered(
    String value,
    String label,
    RxString bufferValue,
  ) {
    final isSelected = bufferValue.value == value;
    return GestureDetector(
      onTap: () {
        bufferValue.value = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : background,
          border: Border.all(color: isSelected ? primary : border),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? primary : foreground,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey == today) {
      return "Today, ${DateFormat('MMM d').format(date)}";
    } else if (dateKey == yesterday) {
      return "Yesterday, ${DateFormat('MMM d').format(date)}";
    } else {
      return "${DateFormat('EEEE').format(date)}, ${DateFormat('MMM d').format(date)}";
    }
  }
}
