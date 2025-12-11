import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/auth_http_client.dart';
import '../services/token_storage.dart';

// ============================================================================
// Infrastructure Providers
// ============================================================================

/// Token storage singleton
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// HTTP client with auth
final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthHttpClient(
    dio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    ),
    tokenStorage: tokenStorage,
  );
});

/// API Service for backend calls
final apiServiceProvider = Provider<ApiService>((ref) {
  final httpClient = ref.watch(authHttpClientProvider);
  return ApiService(
    httpClient: httpClient,
    baseUrl: 'http://localhost:8000', // Change to your backend URL
  );
});

/// Drift Database instance
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  // In a real app, initialize database properly
  // For now, returning null as placeholder
  throw UnimplementedError('Database initialization');
});

// ============================================================================
// Authentication State Providers
// ============================================================================

/// Current authentication state
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? name;
  final String? role;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.name,
    this.role,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? name,
    String? role,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state notifier for login/logout
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    tokenStorage: ref.watch(tokenStorageProvider),
    apiService: ref.watch(apiServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final TokenStorage _tokenStorage;
  final ApiService _apiService;

  AuthNotifier({
    required TokenStorage tokenStorage,
    required ApiService apiService,
  })  : _tokenStorage = tokenStorage,
        _apiService = apiService,
        super(const AuthState()) {
    _checkAuthentication();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkAuthentication() async {
    final isAuthenticated = await _tokenStorage.isAuthenticated();
    if (isAuthenticated) {
      // Restore user data from backend
      // For now, just mark as authenticated
      state = state.copyWith(isAuthenticated: true);
    }
  }

  /// Login with SSO provider
  Future<void> loginWithSSO({
    required String provider,
    required String idToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.loginWithSSO(
        provider: provider,
        idToken: idToken,
        deviceName: 'DLAI Crop Mobile',
      );

      await _tokenStorage.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'] ?? '',
        userId: response['user_id'],
      );

      state = state.copyWith(
        isAuthenticated: true,
        userId: response['user_id'],
        email: response['email'],
        name: response['name'],
        role: response['role'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    state = const AuthState();
  }
}

// ============================================================================
// Farm Data Providers
// ============================================================================

/// Fetch farms for current user
final farmsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getFarms();
});

/// Fetch single farm by ID
final farmDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, farmId) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getFarmById(farmId);
  },
);

// ============================================================================
// Conversation Providers
// ============================================================================

/// Fetch conversations for current user
final conversationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getConversations();
});

/// Fetch messages in conversation
final conversationMessagesProvider =
    FutureProvider.family<List<dynamic>, String>(
  (ref, conversationId) async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getConversationMessages(conversationId);
  },
);

// ============================================================================
// Network Status Provider
// ============================================================================

class NetworkState {
  final bool isOnline;
  final bool isSlowConnection;

  const NetworkState({
    this.isOnline = true,
    this.isSlowConnection = false,
  });
}

final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkState>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<NetworkState> {
  NetworkStatusNotifier() : super(const NetworkState()) {
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    // Placeholder: In real app, use connectivity_plus package
    // For now, assume online
    state = const NetworkState(isOnline: true);
  }
}

// ============================================================================
// Sync Provider
// ============================================================================

/// Global sync state
class SyncState {
  final bool isSyncing;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? error;

  const SyncState({
    this.isSyncing = false,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error ?? this.error,
    );
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  /// Trigger manual sync
  Future<void> syncAll() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      // Placeholder: Implement actual sync logic
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
        pendingChanges: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }
}
