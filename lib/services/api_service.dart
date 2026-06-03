import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'navigation_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  VoidCallback? _onUnauthorized;
  bool _isRefreshing = false;

  void setOnUnauthorized(VoidCallback callback) {
    _onUnauthorized = callback;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          final hasToken = await _storage.read(key: 'jwt_token') != null;
          if (hasToken) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final retryResponse = await _retry(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            }
            _onUnauthorized?.call();
          }
          handler.next(error);
          return;
        }

        _showErrorMessage(error);
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final oldToken = await _storage.read(key: 'jwt_token');
      if (oldToken == null) return false;

      final response = await Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      )).post('/api/auth/refresh', data: {'token': oldToken});

      final data = response.data;
      if (data['status'] == 200) {
        final newToken = data['data']['token'] as String;
        await _storage.write(key: 'jwt_token', value: newToken);

        if (data['data']['user'] != null) {
          final userData = data['data']['user'];
          _onTokenRefreshed?.call(userData);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void Function(Map<String, dynamic> userData)? _onTokenRefreshed;

  void setOnTokenRefreshed(void Function(Map<String, dynamic> userData) callback) {
    _onTokenRefreshed = callback;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: 'jwt_token');
    final options = Options(
      method: requestOptions.method,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  void _showErrorMessage(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Koneksi timeout. Silakan coba lagi.';
        break;
      case DioExceptionType.connectionError:
        message = 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401) return;
        message = error.response?.data?['message'] ?? 'Terjadi kesalahan.';
        break;
      default:
        message = 'Terjadi kesalahan jaringan.';
    }
    NavigationService.showError(message);
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) =>
      _dio.post(path, data: data);

  Future<Response> get(String path) => _dio.get(path);

  Future<Response> uploadFile(String path, String filePath, String fieldName) async {
    final token = await _storage.read(key: 'jwt_token');
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData, options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  Future<void> saveToken(String token) async =>
      await _storage.write(key: 'jwt_token', value: token);

  Future<String?> getToken() async =>
      await _storage.read(key: 'jwt_token');

  Future<void> clearToken() async =>
      await _storage.delete(key: 'jwt_token');
}
