import 'package:dio/dio.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:image_picker/image_picker.dart';
import 'base_api_service.dart';

class FinansialService extends BaseApiService {
  Future<Map<String, dynamic>> getSummary([String? kategoriId]) async {
    final queryParameters = <String, dynamic>{};
    if (kategoriId != null && kategoriId.isNotEmpty && kategoriId != 'all') {
      queryParameters['jenis_kategori'] = kategoriId;
    }

    final response = await client.get(
      '$baseUrl/finansial/summary',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    return response.data;
  }

  Future<List<FinansialModel>> getAll({String? jenisKategori}) async {
    final queryParameters = <String, dynamic>{};
    if (jenisKategori != null &&
        jenisKategori.isNotEmpty &&
        jenisKategori != 'all') {
      queryParameters['jenis_kategori'] = jenisKategori;
    }

    final response = await client.get(
      '$baseUrl/finansial',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final data =
        response.data is List ? response.data : (response.data['data'] ?? []);

    return (data as List).map((e) => FinansialModel.fromJson(e)).toList();
  }

  Future<List<FinansialModel>> getTransactionsByCategory(
    int jenisKategori,
  ) async {
    final response = await client.get(
      '$baseUrl/finansial/jenis',
      queryParameters: {'jenis_kategori': jenisKategori},
    );

    final data =
        response.data is List ? response.data : (response.data['data'] ?? []);

    return (data as List).map((e) => FinansialModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getStatistics({
    int? month,
    int? year,
    String? jenisKategori,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (month != null) queryParameters['month'] = month;
    if (year != null) queryParameters['year'] = year;
    if (jenisKategori != null && jenisKategori != 'all')
      queryParameters['jenis_kategori'] = jenisKategori;

    final response = await client.get(
      '$baseUrl/statistics/overview',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    return response.data;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await client.get('$baseUrl/categories');

    final data =
        response.data is List ? response.data : (response.data['data'] ?? []);

    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionTypes() async {
    final response = await client.get('$baseUrl/ref/jenis');

    final data =
        response.data is List ? response.data : (response.data['data'] ?? []);

    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> addBudget({
    required int categoryId,
    required int budget,
  }) async {
    final response = await client.post(
      '$baseUrl/statistics/add-budget',
      data: {'category_id': categoryId, 'budget': budget},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String date,
    int? category,
    int? jenisKategori,
    String? description,
    XFile? photo,
    String? effectiveMonth,
  }) async {
    // Prepare form data
    final formData = FormData.fromMap({
      'title': title,
      'amount': amount.toString(),
      'is_income': isIncome ? '1' : '0',
      'date': date,
      if (category != null) 'category': category.toString(),
      if (jenisKategori != null) 'jenis_kategori': jenisKategori.toString(),
      if (description != null && description.isNotEmpty)
        'description': description,
      if (effectiveMonth != null && effectiveMonth.isNotEmpty)
        'effective_month': effectiveMonth,
    });

    // Add photo if provided
    if (photo != null) {
      final file = await MultipartFile.fromFile(
        photo.path,
        filename: photo.name,
      );
      formData.files.add(MapEntry('photo', file));
    }

    final response = await client.post(
      '$baseUrl/finansial',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    return response.data;
  }

  Future<void> deleteTransaction(int id) async {
    await client.delete('$baseUrl/finansial/$id');
  }

  Future<Map<String, dynamic>> getDailyTip() async {
    final response = await client.get('$baseUrl/finansial/tips/daily');

    return response.data;
  }
}
