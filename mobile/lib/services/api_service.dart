import 'package:dio/dio.dart';
import 'auth_http_client.dart';
import 'token_storage.dart';

/// API Service for backend integration
/// Handles: Registration, Login, Farm operations, Conversations
class ApiService {
  final AuthHttpClient _httpClient;
  final String baseUrl;

  ApiService({
    required AuthHttpClient httpClient,
    required this.baseUrl,
  }) : _httpClient = httpClient;

  Dio get _dio => _httpClient.dio;

  // ========================================================================
  // Registration APIs
  // ========================================================================

  Future<Map<String, dynamic>> registerStart({
    required String email,
    required String role, // farmer, partner, customer
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/register/start',
        data: {
          'email': email,
          'role': role,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // Login APIs (SSO)
  // ========================================================================

  Future<Map<String, dynamic>> loginWithSSO({
    required String provider, // google, microsoft, facebook
    required String idToken,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/login/sso',
        data: {
          'provider': provider,
          'id_token': idToken,
          'device_name': deviceName,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithCredentials({
    required String emailOrUsername,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/login',
        data: {
          'email_or_username': emailOrUsername,
          'password': password,
          'device_name': deviceName,
          'remember_me': true,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // User Profile APIs
  // ========================================================================

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/users/me',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // Farm APIs
  // ========================================================================

  Future<List<dynamic>> getFarms() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/farms',
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFarmById(String farmId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/farms/$farmId',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createFarm({
    required String name,
    required String location,
    required double latitude,
    required double longitude,
    required double areaAcres,
    required String cropType,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v1/farms',
        data: {
          'name': name,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'area_acres': areaAcres,
          'crop_type': cropType,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // Conversation APIs
  // ========================================================================

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/conversations',
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getConversationMessages(String conversationId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/conversations/$conversationId/messages',
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // Health Check
  // ========================================================================

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('$baseUrl/api/health/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
