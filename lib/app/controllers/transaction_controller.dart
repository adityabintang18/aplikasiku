import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:aplikasiku/app/data/services/financial_service.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aplikasiku/app/utils/exceptions.dart';

class TransactionController extends GetxController {
  final FinansialService _financialService = FinansialService();
  final _logger = Logger();

  var transactions = <FinansialModel>[].obs;
  var isLoading = false.obs;
  var isInitialLoading = true.obs;
  var isTransactionTypesLoading = false.obs;

  // For tab management (daily/monthly)
  var currentTabIndex = 0.obs;

  // For filtering
  var selectedMonth = DateTime.now().obs;
  var filterType = 'all'.obs; // "income", "expense", or "all"
  var transactionTypeFilter =
      'all'.obs; // id jenis kategori transaksi, or "all"

  // Transaction types from API (list of available jenis transaksi)
  var transactionTypes = <Map<String, dynamic>>[].obs;

  // Filtered transactions according to month, type, and jenis transaksi
  List<FinansialModel> get filteredTransactions {
    _logger.i(
      'filteredTransactions called - total transactions: ${transactions.length}',
    );
    _logger.i(
      'Filters - filterType: ${filterType.value}, transactionTypeFilter: ${transactionTypeFilter.value}, selectedMonth: ${selectedMonth.value}',
    );

    var filtered = transactions.where((t) {
      // Filter berdasarkan bulan
      final transactionDate = DateTime.parse(t.date);
      if (transactionDate.year != selectedMonth.value.year ||
          transactionDate.month != selectedMonth.value.month) {
        return false;
      }

      // Filter berdasarkan tipe transaksi (income/expense)
      if (filterType.value != 'all') {
        if (filterType.value == 'income' && !t.isIncome) return false;
        if (filterType.value == 'expense' && t.isIncome) return false;
      }

      // Filter berdasarkan jenis transaksi (kategori utama: Personal, Bulanan, Dinas, Organisasi, dll)
      if (transactionTypeFilter.value != 'all') {
        final jenisKategori = t.namaJenisKategori;
        final selectedJenis = transactionTypeFilter.value;
        _logger.i(
          'Checking transaction ${t.title} - namaJenisKategori: "$jenisKategori", selectedJenis: "$selectedJenis"',
        );

        // namaJenisKategori appears to be the NAME (like "Bulanan"), not the ID
        // But transactionTypeFilter.value is the ID (like "1")
        // We need to find the transaction type that matches the selected ID and compare the name
        final selectedType = transactionTypes.firstWhereOrNull(
          (type) => type['id'].toString() == selectedJenis,
        );
        if (selectedType != null) {
          final selectedTypeName = selectedType['nama']?.toString() ??
              selectedType['name']?.toString() ??
              '';
          _logger.i('  Selected type name: "$selectedTypeName"');
          if (jenisKategori != selectedTypeName) {
            _logger.i('  Transaction filtered out - no match');
            return false;
          } else {
            _logger.i('  Transaction matches filter');
          }
        } else {
          _logger.i('  Selected type not found in transactionTypes');
          return false;
        }
      }

      return true;
    }).toList();

    _logger.i('Filtered transactions before date sort: ${filtered.length}');

    // Urutkan berdasarkan tanggal turun (paling baru di atas)
    filtered.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    _logger.i('Final filtered transactions: ${filtered.length}');
    return filtered;
  }

  @override
  void onInit() {
    _logger.i('TransactionController onInit called');
    super.onInit();
  }

  @override
  void onReady() async {
    _logger.i('TransactionController onReady called');
    super.onReady();
    // Preload transaction types first, then transactions
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isInitialLoading(true);
    try {
      await fetchTransactionTypes();
      await fetchTransactions(showLoader: false);
    } finally {
      isInitialLoading(false);
    }
  }

  /// Modified: now accepts optional jenisKategori param for backend filtering
  Future<void> fetchTransactions({
    String? jenisKategori,
    bool showLoader = true,
  }) async {
    try {
      if (showLoader) isLoading(true);
      _logger.i('fetchTransactions called with jenisKategori: $jenisKategori');

      final result = await _financialService.getAll(
        jenisKategori: jenisKategori,
      );

      transactions.value = List<FinansialModel>.from(result);
      _logger.i('Transactions loaded: ${transactions.length} items');

      if (transactions.isNotEmpty) {
        _logger.i(
          'First transaction sample: ${transactions.first.namaJenisKategori}, ${transactions.first.title}',
        );
      } else {
        _logger.w(
          'No transactions found - this might indicate empty data or API issue',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetchTransactions', error: e, stackTrace: stackTrace);
      transactions.clear(); // Clear transactions on error to show empty state
      rethrow; // Re-throw to let UI handle the error
    } finally {
      if (showLoader) isLoading(false);
    }
  }

  Future<void> fetchTransactionTypes() async {
    try {
      isTransactionTypesLoading(true);
      final result = await _financialService.getTransactionTypes();
      transactionTypes.value = result;
      _logger.i('Transaction types loaded: ${transactionTypes.length} items');

      if (transactionTypes.isNotEmpty) {
        _logger.i('TransactionTypes structure:');
        for (var i = 0; i < transactionTypes.length; i++) {
          _logger.i('  [$i]: ${transactionTypes[i]}');
        }
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error fetchTransactionTypes',
        error: e,
        stackTrace: stackTrace,
      );
      transactionTypes.clear(); // Clear on error
    } finally {
      isTransactionTypesLoading(false);
    }
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
    _logger.i('Tab changed to index: $index');
  }

  void setMonth(DateTime month) {
    selectedMonth.value = month;
    _logger.i('Month changed to: $month');
  }

  /// Rewrite: When filterType changes, get the corresponding jenisKategori id and fetch from API
  void setFilterType(String type) async {
    filterType.value = type;
    _logger.i('Filter type changed to: $type');

    String? jenisKategori;
    if (type != 'all') {
      // Find the transaction type ID from transactionTypes, checking both id & name or type field
      final foundType = transactionTypes.firstWhereOrNull((item) {
        // If your API provides 'type' field (income/expense) use this
        // else if it's 'name' (case-insensitive) or needs mapping, handle here.
        if (item.containsKey('type')) {
          return (item['type'] as String).toLowerCase() == type;
        }
        if (item.containsKey('nama')) {
          return (item['nama'] as String).toLowerCase() == type;
        }
        if (item.containsKey('name')) {
          return (item['name'] as String).toLowerCase() == type;
        }
        return false;
      });

      if (foundType != null) {
        // Usually id is int or string
        jenisKategori = foundType['id']?.toString();
      }
    }

    await fetchTransactions(jenisKategori: jenisKategori);
  }

  void setTransactionTypeFilter(String type) async {
    _logger.i('setTransactionTypeFilter called with: $type');
    transactionTypeFilter.value = type;
    _logger.i('Transaction type filter changed to: $type');
    _logger.i('Current transactionTypes length: ${transactionTypes.length}');
    if (transactionTypes.isNotEmpty) {
      _logger.i('Sample transactionTypes: ${transactionTypes.first}');
      // If type is not 'all', find the corresponding name
      if (type != 'all') {
        final selectedType = transactionTypes.firstWhereOrNull(
          (t) => t['id'].toString() == type,
        );
        if (selectedType != null) {
          _logger.i('Selected transaction type: $selectedType');
        } else {
          _logger.i('Selected transaction type not found for ID: $type');
        }
      }
    }
    // Check if any transactions match this filter (using the new logic)
    final matchingTransactions = transactions.where((t) {
      if (type == 'all') return true;
      final selectedType = transactionTypes.firstWhereOrNull(
        (tt) => tt['id'].toString() == type,
      );
      if (selectedType != null) {
        final typeName = selectedType['nama']?.toString() ??
            selectedType['name']?.toString() ??
            '';
        return t.namaJenisKategori == typeName;
      }
      return false;
    }).toList();
    _logger.i(
      'Transactions matching jenisKategori $type: ${matchingTransactions.length}',
    );
    // Optionally: fetch filtered from backend too? Leave as is for now.
  }

  void resetFilters() async {
    filterType.value = 'all';
    transactionTypeFilter.value = 'all';
    _logger.i('Filters reset');
    await fetchTransactions();
  }

  List<FinansialModel> get dailyTransactions {
    return filteredTransactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      final today = DateTime.now();
      return transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day;
    }).toList();
  }

  List<FinansialModel> get monthlyTransactions {
    return filteredTransactions;
  }

  // Group transactions by date for the selected month
  Map<DateTime, List<FinansialModel>> get groupedTransactionsByDate {
    final grouped = <DateTime, List<FinansialModel>>{};
    for (final transaction in monthlyTransactions) {
      final date = DateTime.parse(transaction.date);
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }
    return grouped;
  }

  // Calculate monthly category breakdown
  Map<String, dynamic> getMonthlyCategoryBreakdown() {
    final monthlyData = monthlyTransactions;
    final totalExpenses = monthlyData
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = monthlyData
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Group by category
    final categoryMap = <String, double>{};
    for (final transaction in monthlyData.where((t) => !t.isIncome)) {
      categoryMap[transaction.namaKategori] =
          (categoryMap[transaction.namaKategori] ?? 0) + transaction.amount;
    }

    final categories = categoryMap.entries.map((entry) {
      final percentage =
          totalExpenses > 0 ? (entry.value / totalExpenses * 100).round() : 0;
      return {
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
        'icon': getCategoryEmoji(entry.key),
      };
    }).toList();

    categories.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'categories': categories,
    };
  }

  String getCategoryEmoji(String category) {
    final emojiMap = {
      'Belanja': '🛍️',
      'Bonus': '🎁',
      'Gaji': '💰',
      'Hiburan': '🎬',
      'Investasi': '📈',
      'Kesehatan': '🩺',
      'Lain-lain': '📋',
      'Makanan & Minuman': '🍽️',
      'Pendidikan': '🎓',
      'Tabungan': '🏦',
      'Tagihan & Utilitas': '💡',
      'Transportasi': '🚗',
    };
    return emojiMap[category] ?? '📦';
  }

  Future<void> refreshTransactions() async {
    await fetchTransactions();
  }

  Future<void> addTransaction(
    FinansialModel transaction, {
    XFile? photo,
  }) async {
    try {
      isLoading(true);

      final result = await _financialService.createTransaction(
        title: transaction.title,
        amount: transaction.amount,
        isIncome: transaction.isIncome,
        date: transaction.date,
        category: transaction.category,
        jenisKategori: int.tryParse(transaction.namaJenisKategori),
        description: transaction.description,
        photo: photo,
        effectiveMonth: transaction.effectiveMonth,
      );

      _logger.i('Transaction created successfully: $result');
      _logger.i(
        'Request data sent: title=${transaction.title}, amount=${transaction.amount}, is_income=${transaction.isIncome}, date=${transaction.date}, category=${transaction.category}, jenis_kategori=${transaction.namaJenisKategori}, description=${transaction.description}, effective_month=${transaction.effectiveMonth}, photo=${photo?.path}',
      );

      // Refresh transactions list
      await fetchTransactions();

      _logger.i('Transaction added with image support and effective month');
    } catch (e) {
      _logger.e('Error addTransaction', error: e);
      rethrow; // Re-throw so UI can handle the error
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateTransaction(String id, FinansialModel transaction) async {
    try {
      // Implementasi update transaksi
      await fetchTransactions();
      _logger.i('Transaction updated: $id');
    } catch (e) {
      _logger.e('Error updateTransaction', error: e);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // Implementasi hapus transaksi
      await fetchTransactions();
      _logger.i('Transaction deleted: $id');
    } catch (e) {
      _logger.e('Error deleteTransaction', error: e);
    }
  }

  /// Called when page is entered - refresh data automatically
  Future<void> onPageEnter() async {
    _logger.i('TransactionController: onPageEnter called - refreshing data');
    await fetchTransactions();
  }
}
