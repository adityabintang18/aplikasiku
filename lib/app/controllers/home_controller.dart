import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:aplikasiku/app/data/services/financial_service.dart';
import 'package:aplikasiku/app/data/services/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:aplikasiku/app/utils/exceptions.dart';
import 'package:aplikasiku/app/core/services/error_handler_service.dart';
import 'package:aplikasiku/app/core/services/update_handler_service.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';
import 'package:aplikasiku/app/ui/widgets/update_required_page.dart';

class HomeController extends GetxController with UpdateRequiredMixin {
  final _logger = Logger();
  final FinansialService _financialService = FinansialService();
  final AuthService _authService = AuthService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService.to;

  // Core reactive variables
  var summary = {}.obs;
  var allTransaksiList = <FinansialModel>[].obs;
  var filteredTransaksiList = <FinansialModel>[].obs;

  // Enhanced loading states for better UX
  var isInitialLoading = true.obs;
  var isUserInfoLoading = false.obs;
  var isTransactionTypesLoading = false.obs;
  var isCategoriesLoading = false.obs;
  var isDailyTipLoading = false.obs;
  var isSummaryLoading = false.obs;
  var isTransactionsLoading = false.obs;

  // User data
  var userInfo = {}.obs;
  var transactionTypes = <Map<String, dynamic>>[].obs;
  var categories = <Map<String, dynamic>>[].obs;
  var selectedTransactionTypeId = 'all'.obs;
  var dailyTip = ''.obs;

  // Error states
  var userInfoError = Rxn<AppException>();
  var transactionTypesError = Rxn<AppException>();
  var categoriesError = Rxn<AppException>();
  var transactionsError = Rxn<AppException>();

  @override
  void onInit() {
    super.onInit();
    // Force update check when controller initializes
    checkForUpdatesOnInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    isInitialLoading.value = true;
    try {
      // Load data with individual error handling to prevent cascade failures
      await _safeFetchUserInfo();
      await _safeFetchTransactionTypes();
      await _safeFetchCategories();
      await _safeFetchDailyTip();
      await _safeFetchSummary();
      await _safeFetchAllTransaksi();
      await _safeFilterTransaksiList();
    } catch (e) {
      _logger.e("Error onInit: $e");
    } finally {
      isInitialLoading.value = false;
    }
  }

  /// Safe fetch methods that handle update exceptions specifically
  Future<void> _safeFetchUserInfo() async {
    try {
      await fetchUserInfo();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w('UserInfo: Update required, re-throwing to trigger dialog');
        rethrow; // Re-throw to trigger update dialog
      } else {
        _logger.w('UserInfo failed: $e');
        userInfo.value = {'name': 'Demo User', 'email': 'demo@example.com'};
      }
    }
  }

  Future<void> _safeFetchTransactionTypes() async {
    try {
      await fetchTransactionTypes();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w(
            'TransactionTypes: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('TransactionTypes failed: $e');
        transactionTypes.value = [
          {'id': '1', 'name': 'Income', 'type': 'income'},
          {'id': '2', 'name': 'Expense', 'type': 'expense'},
          {'id': '3', 'name': 'Transfer', 'type': 'transfer'},
        ];
      }
    }
  }

  Future<void> _safeFetchCategories() async {
    try {
      await fetchCategories();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w('Categories: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('Categories failed: $e');
        categories.value = [
          {'id': 14, 'nama': 'Gaji', 'deskripsi': 'Pemasukan'},
          {'id': 18, 'nama': 'Makanan & Minuman', 'deskripsi': 'Pengeluaran'},
        ];
      }
    }
  }

  Future<void> _safeFetchDailyTip() async {
    try {
      await fetchDailyTip();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w('DailyTip: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('DailyTip failed: $e');
        dailyTip.value = 'Welcome to Aplikasiku!';
      }
    }
  }

  Future<void> _safeFetchSummary() async {
    try {
      await fetchSummary();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w('Summary: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('Summary failed: $e');
        summary.value = {'pemasukan': 0, 'pengeluaran': 0, 'saldo': 0};
      }
    }
  }

  Future<void> _safeFetchAllTransaksi() async {
    try {
      await fetchAllTransaksi();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger
            .w('Transactions: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('Transactions failed: $e');
        allTransaksiList.value = [];
      }
    }
  }

  Future<void> _safeFilterTransaksiList() async {
    try {
      await filterTransaksiList();
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        _logger.w('Filter: Update required, re-throwing to trigger dialog');
        rethrow;
      } else {
        _logger.w('Filter failed: $e');
        filteredTransaksiList.value = [];
      }
    }
  }

  Future<void> fetchUserInfo() async {
    isUserInfoLoading.value = true;
    userInfoError.value = null;

    try {
      final result = await _errorHandler.handleError(
        () => _authService.getUserInfo(),
        showSnackbar: true,
      );
      userInfo.value = result;
      _logger.i('User info loaded: $result');
    } catch (e) {
      _logger.e('Error in fetchUserInfo: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isUserInfoLoading.value = false;
    }
  }

  Future<void> fetchTransactionTypes() async {
    isTransactionTypesLoading.value = true;
    transactionTypesError.value = null;

    try {
      final result = await _errorHandler.handleError(
        () => _authService.getTransactionTypes(),
        showSnackbar: true,
      );

      if (result != null) {
        transactionTypes.value = result;
        _logger.i(
          'Transaction types loaded: ${result.length} items | JSON: $result',
        );
        if (result.isNotEmpty &&
            (selectedTransactionTypeId.value.isEmpty ||
                selectedTransactionTypeId.value == '')) {
          selectedTransactionTypeId.value = 'all';
        }
      }
    } catch (e) {
      _logger.e('Error in fetchTransactionTypes: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isTransactionTypesLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    isCategoriesLoading.value = true;
    categoriesError.value = null;

    try {
      final result = await _errorHandler.handleError(
        () => _authService.getCategories(),
        showSnackbar: true,
      );

      if (result != null) {
        categories.value = result;
        _logger.i('Categories loaded: ${result.length} items | JSON: $result');
      }
    } catch (e) {
      _logger.e('Error in fetchCategories: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> fetchDailyTip() async {
    isDailyTipLoading.value = true;

    try {
      final result = await _errorHandler.handleError(
        () => _financialService.getDailyTip(),
        showSnackbar: false, // Don't show snackbar for tips
      );

      if (result['success'] == true) {
        dailyTip.value = result['tip'] ?? '';
        _logger.i('Daily tip loaded: ${dailyTip.value}');
      }
    } catch (e) {
      _logger.e('Error in fetchDailyTip: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isDailyTipLoading.value = false;
    }
  }

  Future<void> fetchSummary([String? typeId]) async {
    isSummaryLoading.value = true;

    try {
      String? valueToUse;
      if (typeId != null && typeId.isNotEmpty && typeId != 'all') {
        valueToUse = typeId;
      } else if (selectedTransactionTypeId.value.isNotEmpty &&
          selectedTransactionTypeId.value != 'all') {
        valueToUse = selectedTransactionTypeId.value;
      } else {
        valueToUse = null;
      }

      final result = await _errorHandler.handleError(
        () => _financialService.getSummary(valueToUse),
        showSnackbar: true,
      );

      summary.value = result;
      _logger.i('Summary Loaded: $result');
    } catch (e) {
      _logger.e('Error in fetchSummary: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isSummaryLoading.value = false;
    }
  }

  Future<void> fetchAllTransaksi() async {
    isTransactionsLoading.value = true;
    transactionsError.value = null;

    try {
      final result = await _errorHandler.handleError(
        () => _financialService.getAll(jenisKategori: null),
        showSnackbar: true,
      );

      allTransaksiList.value = result;
      _logger.i('All Transactions loaded: ${allTransaksiList.length} items');
    } catch (e) {
      _logger.e('Error in fetchAllTransaksi: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  Future<void> filterTransaksiList() async {
    final filterId = selectedTransactionTypeId.value;
    isTransactionsLoading.value = true;

    try {
      List<FinansialModel> transactions;
      if (filterId.isEmpty || filterId == 'all') {
        transactions = await _errorHandler.handleError(
              () => _financialService.getAll(jenisKategori: null),
              showSnackbar: false,
            ) ??
            [];
      } else {
        transactions = await _errorHandler.handleError(
              () => _financialService.getAll(jenisKategori: filterId),
              showSnackbar: false,
            ) ??
            [];
      }

      transactions.sort((a, b) {
        try {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1900);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1900);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      filteredTransaksiList.value = transactions;
    } catch (e) {
      _logger.e('Error filterTransaksiList', error: e);
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
      filteredTransaksiList.value = [];
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  Future<void> fetchTransactionsByCategory(int jenisKategori) async {
    isTransactionsLoading.value = true;

    try {
      final result = await _errorHandler.handleError(
        () => _financialService.getTransactionsByCategory(jenisKategori),
        showSnackbar: true,
      );

      List<FinansialModel> transactions = result;

      transactions.sort((a, b) {
        try {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1900);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1900);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      filteredTransaksiList.value = transactions;
      _logger.i(
        'Transactions by category loaded: ${filteredTransaksiList.length} items for jenis_kategori: $jenisKategori',
      );
    } catch (e) {
      _logger.e('Error in fetchTransactionsByCategory: $e');
      if (e is AppUpdateRequiredException) {
        rethrow; // Re-throw to trigger update dialog
      }
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  void setTransactionTypeFilter(String typeId) async {
    selectedTransactionTypeId.value = typeId;
    _logger.i(
      'Transaction type filter changed to: $typeId - refreshing entire page',
    );

    // Refresh the entire page data with the selected filter applied
    try {
      isInitialLoading.value = true;

      // Clear previous data
      summary.value = {};
      allTransaksiList.value = [];
      filteredTransaksiList.value = [];

      // Load all data with the filter applied
      await _safeFetchUserInfo();
      await _safeFetchTransactionTypes();
      await _safeFetchCategories();
      await _safeFetchDailyTip();
      await _safeFetchSummary();
      await _safeFetchAllTransaksi();
      await _safeFilterTransaksiList();
    } catch (e) {
      _logger.e('Error in setTransactionTypeFilter', error: e);
    } finally {
      isInitialLoading.value = false;
      updateFilteredData();
    }
  }

  List<FinansialModel> get filteredTransactions => filteredTransaksiList;

  List<FinansialModel> get allTransactions => allTransaksiList;

  void updateFilteredData() {
    update();
  }

  Future<void> refreshData() async {
    await _initializeData();
  }

  /// Called when page is entered - refresh data automatically
  Future<void> onPageEnter() async {
    _logger.i('HomeController: onPageEnter called - refreshing data');
    // Force update check on page enter
    forceUpdateCheck();
    await refreshData();
  }

  /// Add new transaction type (jenis transaksi) to /ref/jenis endpoint
  Future<void> addJenisKategori(String nama, {String? deskripsi}) async {
    final result = await _errorHandler.handleError(
      () => _authService.addTransactionTypesLegacy(nama, deskripsi: deskripsi),
      showSnackbar: true,
    );

    if (result['success'] == true) {
      await refreshData();
      _errorHandler.showSuccessSnackbar('Transaction type added successfully');
    }
  }

  /// Add new transaction category (kategori transaksi) to /ref/kategori endpoint
  Future<void> addCategory(String nama, {String? deskripsi}) async {
    final result = await _errorHandler.handleError(
      () => _authService.addCategoryLegacy(nama: nama, deskripsi: deskripsi),
      showSnackbar: true,
    );

    if (result['success'] == true) {
      await refreshData();
      _errorHandler.showSuccessSnackbar('Category added successfully');
    }
  }
}
