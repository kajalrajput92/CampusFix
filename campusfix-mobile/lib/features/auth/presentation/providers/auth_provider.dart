import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/models/user_session.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/department_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider exposing the SecureStorageService instance.
final Provider<SecureStorageService> secureStorageServiceProvider =
    Provider<SecureStorageService>((ref) {
      return SecureStorageService();
    });

/// Provider exposing the configured ApiClient with 401 session expiration handling.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(
    storageService: storageService,
    onSessionExpired: () {
      ref.read(authNotifierProvider.notifier).handleSessionExpired();
    },
  );
});

/// Provider exposing the remote data source.
final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return AuthRemoteDataSource(apiClient);
    });

/// Provider exposing the AuthRepository contract.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
      final storageService = ref.watch(secureStorageServiceProvider);
      return AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

/// State notifier managing user authentication lifecycle and active session.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial());

  /// Attempts to restore an existing session from secure storage using GET /api/auth/me.
  Future<void> restoreSession() async {
    state = AuthState.loading(currentSession: state.session);

    try {
      final session = await _authRepository.restoreSession();
      if (session != null) {
        state = AuthState.authenticated(session);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  /// Authenticates user credentials against the backend and enforces role restrictions.
  Future<bool> login({
    required String email,
    required String password,
    required String targetRole,
  }) async {
    state = AuthState.loading(currentSession: state.session);

    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
        targetRole: targetRole,
      );

      state = AuthState.authenticated(session);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred during login.');
      return false;
    }
  }

  /// Registers a new student account. Does not log in automatically.
  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? departmentId,
    String? enrollmentNumber,
  }) async {
    state = AuthState.loading(currentSession: state.session);

    try {
      final data = await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        departmentId: departmentId,
        enrollmentNumber: enrollmentNumber,
      );

      state = AuthState.unauthenticated();
      return data;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return null;
    } catch (e) {
      state = AuthState.error('Registration failed. Please try again.');
      return null;
    }
  }

  /// Submits forgot password request to POST /api/auth/forgot-password.
  Future<String?> forgotPassword({required String email}) async {
    state = AuthState.loading(currentSession: state.session);

    try {
      final message = await _authRepository.forgotPassword(email: email);
      state = AuthState.unauthenticated();
      return message;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return null;
    } catch (e) {
      state = AuthState.error('Failed to request password reset.');
      return null;
    }
  }

  /// Submits reset password request to POST /api/auth/reset-password.
  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = AuthState.loading(currentSession: state.session);

    try {
      final message = await _authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      state = AuthState.unauthenticated();
      return message;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return null;
    } catch (e) {
      state = AuthState.error('Failed to reset password.');
      return null;
    }
  }

  /// Clears user session and stored credentials.
  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.unauthenticated();
  }

  /// Broadcast handler called when a 401 occurs on a protected endpoint.
  Future<void> handleSessionExpired() async {
    // Avoid re-triggering if already unauthenticated
    if (state.isUnauthenticated) return;

    await _authRepository.logout();
    state = AuthState.unauthenticated(
      message: 'Your session has expired. Please log in again.',
    );
  }

  /// Clears transient error messages.
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Central StateNotifierProvider for authentication state.
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthNotifier(repository);
    });

/// Convenience provider returning the active UserSession or null.
final Provider<UserSession?> currentUserProvider = Provider<UserSession?>((
  ref,
) {
  return ref.watch(authNotifierProvider).session;
});

/// FutureProvider to fetch the Department catalog for student registration.
final FutureProvider<List<DepartmentModel>> departmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) {
      return ref.watch(authRepositoryProvider).getDepartments();
    });
