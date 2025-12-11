// Financial service interface
import 'package:image_picker/image_picker.dart';

abstract class IFinancialService {
  Future<List<Map<String, dynamic>>> getAll({String? jenisKategori});
  Future<List<Map<String, dynamic>>> getTransactionsByCategory(
    int jenisKategori,
  );
  Future<Map<String, dynamic>> getSummary({String? kategoriId});
  Future<Map<String, dynamic>> getStatistics({int? month, int? year});
  Future<List<Map<String, dynamic>>> getCategories();
  Future<List<Map<String, dynamic>>> getTransactionTypes();
  Future<Map<String, dynamic>> addBudget({
    required int categoryId,
    required int budget,
  });
  Future<Map<String, dynamic>> createTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String date,
    int? category,
    int? jenisKategori,
    String? description,
    XFile? photo,
  });
  Future<void> deleteTransaction(int id);
}
