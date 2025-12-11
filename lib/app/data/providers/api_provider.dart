import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';
import '../services/base_api_service.dart';

class ApiProvider extends BaseApiService {
  ApiProvider() : super();

  /// GET request with automatic token injection
  Future<Response> get(String endpoint) async {
    return await client.get('$baseUrl$endpoint');
  }

  /// POST request with automatic token injection
  Future<Response> post(String endpoint, dynamic data) async {
    return await client.post(
      '$baseUrl$endpoint',
      data: data,
    );
  }

  /// PUT request with automatic token injection
  Future<Response> put(String endpoint, dynamic data) async {
    return await client.put(
      '$baseUrl$endpoint',
      data: data,
    );
  }

  /// DELETE request with automatic token injection
  Future<Response> delete(String endpoint) async {
    return await client.delete('$baseUrl$endpoint');
  }

  /// PATCH request with automatic token injection
  Future<Response> patch(String endpoint, dynamic data) async {
    return await client.patch(
      '$baseUrl$endpoint',
      data: data,
    );
  }

  /// Upload file with automatic token injection
  Future<Response> uploadFile(
    String endpoint,
    String filePath, {
    String? fieldName,
    Map<String, String>? additionalFields,
  }) async {
    final fileName = filePath.split('/').last;
    final file = await MultipartFile.fromFile(
      filePath,
      filename: fileName,
    );

    final formData = FormData.fromMap({
      if (fieldName != null) fieldName: file,
      if (additionalFields != null) ...additionalFields,
    });

    return await client.post(
      '$baseUrl$endpoint',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }

  /// Download file with automatic token injection
  Future<Response> downloadFile(String endpoint, String savePath) async {
    return await client.download(
      '$baseUrl$endpoint',
      savePath,
    );
  }
}
