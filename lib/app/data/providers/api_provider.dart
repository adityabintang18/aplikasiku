import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

class ApiProvider {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<Response> get(String endpoint) async {
    String? token = await StorageService.getToken();
    return _dio.get(
      endpoint,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> post(String endpoint, dynamic data) async {
    String? token = await StorageService.getToken();
    return _dio.post(
      endpoint,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
