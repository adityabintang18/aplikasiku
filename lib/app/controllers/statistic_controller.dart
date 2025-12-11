import 'package:get/get.dart';
import 'package:aplikasiku/app/data/services/financial_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:aplikasiku/app/ui/pages/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateRequiredException implements Exception {
  final String message;
  AppUpdateRequiredException(this.message);
}

class StatisticController extends GetxController {
  final FinansialService _financialService = FinansialService();
  final _logger = Logger();

  // API data structure based on Lumen response
  var statistics = {}.obs;
  var isLoading = false.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxString selectedJenisKategori = 'all'.obs;

  @override
  void onInit() {
    fetchStatistics();
    super.onInit();
  }

  Future<void> fetchStatistics({
    int? month,
    int? year,
    String? jenisKategori,
  }) async {
    final targetMonth = month ?? selectedMonth.value;
    final targetYear = year ?? selectedYear.value;
    final targetJenisKategori = jenisKategori ?? selectedJenisKategori.value;
    try {
      isLoading(true);
      final result = await _financialService.getStatistics(
        month: targetMonth,
        year: targetYear,
        jenisKategori: targetJenisKategori,
      );
      selectedMonth.value = targetMonth;
      selectedYear.value = targetYear;
      selectedJenisKategori.value = targetJenisKategori;
      statistics.value = result;
      _logger.i('Statistics loaded: $result');
    } catch (e, stackTrace) {
      if (e is AppUpdateRequiredException) {
        _showUpdateRequiredDialog();
      } else {
        _logger.e('Error fetchStatistics', error: e, stackTrace: stackTrace);
      }
    } finally {
      isLoading(false);
    }
  }

  // Overview getters
  Map<String, dynamic> get overview => statistics['overview'] ?? {};

  int get totalIncome => overview['total_income'] ?? 0;
  int get totalExpense => overview['total_expense'] ?? 0;
  int get netBalance => overview['net_balance'] ?? 0;

  // Chart data getters
  List<Map<String, dynamic>> get expenseData =>
      (statistics['expenseData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get incomeVsExpenseData =>
      (statistics['incomeVsExpenseData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get savingsTrendData =>
      (statistics['savingsTrendData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get incomeDistributionData =>
      (statistics['incomeDistributionData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get categoryDetails =>
      (statistics['categoryDetails'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get budgetVsSpent =>
      (statistics['budgetVsSpent'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get topSpendingCategories =>
      (statistics['topSpendingCategories'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [];

  String getCategoryLabel(dynamic rawCategory) {
    if (rawCategory is String && rawCategory.isNotEmpty) {
      return rawCategory;
    }
    if (rawCategory is int) {
      final match = _findCategoryById(rawCategory);
      if (match != null) {
        final name = match['category'];
        if (name is String && name.isNotEmpty) {
          return name;
        }
      }
      return 'Kategori $rawCategory';
    }
    return rawCategory?.toString() ?? 'Unknown';
  }

  Map<String, dynamic>? _findCategoryById(int id) {
    for (final item in budgetVsSpent) {
      final categoryId = item['category_id'];
      if (categoryId is int && categoryId == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> refreshStatistics() async {
    await fetchStatistics();
  }

  /// Called when page is entered - refresh data automatically
  Future<void> onPageEnter() async {
    _logger.i('StatisticController: onPageEnter called - refreshing data');
    await refreshStatistics();
  }

  Future<void> changePeriod(int month, int year) async {
    await fetchStatistics(month: month, year: year);
  }

  Future<void> changeJenisKategori(String jenisKategori) async {
    await fetchStatistics(jenisKategori: jenisKategori);
  }

  Future<void> changeFilters(int month, int year, String jenisKategori) async {
    await fetchStatistics(
      month: month,
      year: year,
      jenisKategori: jenisKategori,
    );
  }

  Future<void> addBudget(int categoryId, int budget) async {
    try {
      await _financialService.addBudget(categoryId: categoryId, budget: budget);
      await fetchStatistics(); // Refresh statistics after adding budget
    } catch (e, stackTrace) {
      _logger.e('Error adding budget', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _showUpdateRequiredDialog() {
    Get.defaultDialog(
      title: 'Update Required',
      middleText:
          'Your app version is outdated. Please update to the latest version.',
      textConfirm: 'Update Now',
      textCancel: 'Exit',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        const url = 'https://github.com/adityabintang18/Aplikasiku/releases';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
        Get.offAll(() => LoginPage());
      },
      onCancel: () {
        Get.offAll(() => LoginPage());
      },
      barrierDismissible: false,
    );
  }
}
