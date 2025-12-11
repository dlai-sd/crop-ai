import 'package:dio/dio.dart';
import 'token_storage.dart';

/// HTTP client with JWT authentication
/// Automatically adds Authorization header to all requests
class AuthHttpClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthHttpClient({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      await _tokenStorage.clearTokens();
      // In a real app, trigger logout/re-authentication
    }
    handler.next(err);
  }

  Dio get dio => _dio;
}
