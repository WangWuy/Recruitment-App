import 'package:dio/dio.dart';
import '../core/constants.dart';

class ProfileService {
  late final Dio _dio;

  ProfileService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor to log requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 [DIO REQUEST] ${options.method} ${options.uri}');
        print('🔑 [DIO HEADERS] ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ [DIO RESPONSE] ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ [DIO ERROR] ${error.message}');
        print('❌ [DIO ERROR HEADERS] ${error.requestOptions.headers}');
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>?> getMine(String token) async {
    print('🔍 ProfileService.getMine called');
    print('📝 Token: ${token.isEmpty ? "EMPTY" : "${token.substring(0, 10)}..."}');
    print('🌐 URL: ${AppConstants.apiBaseUrl}/api/profile');

    try {
      final response = await _dio.get(
        '/api/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>?;
      }
      throw Exception('Lỗi tải hồ sơ');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Headers sent: ${e.requestOptions.headers}');

      if (e.response != null) {
        final data = e.response!.data as Map<String, dynamic>?;
        throw Exception(data?['message'] ?? 'Lỗi tải hồ sơ');
      }
      throw Exception('Không thể kết nối đến server');
    }
  }

  Future<void> upsertMine(String token, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(
        '/api/profile',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      }
      throw Exception('Lỗi lưu hồ sơ');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response != null) {
        final data = e.response!.data as Map<String, dynamic>?;
        throw Exception(data?['message'] ?? 'Lỗi lưu hồ sơ');
      }
      throw Exception('Không thể kết nối đến server');
    }
  }
}

