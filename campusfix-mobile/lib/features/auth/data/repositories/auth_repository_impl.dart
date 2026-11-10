import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/models/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/department_model.dart';

/// Concrete implementation of AuthRepository backed by AuthRemoteDataSource and SecureStorageService.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<UserSession> login({
    required String email,
    required String password,
    required String targetRole,
  }) async {
    final data = await remoteDataSource.login(email: email, password: password);

    final token = data['access_token'] as String?;
    final userMap = data['user'] as Map<String, dynamic>?;

    if (token == null || token.isEmpty || userMap == null) {
      throw const ApiException(
        message:
            'Malformed authentication response: missing token or user data.',
      );
    }

    final actualRole = (userMap['role'] as String? ?? 'STUDENT').toUpperCase();
    final expectedRole = targetRole.toUpperCase();

    // Verify user role matches portal entry point
    if (actualRole != expectedRole) {
      throw AuthRoleMismatchException(
        actualRole: actualRole,
        expectedRole: expectedRole,
      );
    }

    final userId = userMap['user_id'] is int
        ? userMap['user_id'] as int
        : int.tryParse(userMap['user_id'].toString()) ?? 0;
    final fullName = userMap['full_name'] as String? ?? '';
    final userEmail = userMap['email'] as String? ?? email;

    // Securely persist credentials and session identity
    await storageService.saveToken(token);
    await storageService.saveSessionDetails(
      userId: userId,
      fullName: fullName,
      email: userEmail,
      role: actualRole,
    );

    return UserSession(
      userId: userId,
      fullName: fullName,
      email: userEmail,
      role: actualRole,
      token: token,
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? departmentId,
    String? enrollmentNumber,
  }) async {
    return await remoteDataSource.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      departmentId: departmentId,
      enrollmentNumber: enrollmentNumber,
    );
  }

  @override
  Future<UserSession?> restoreSession() async {
    final token = await storageService.getToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final meData = await remoteDataSource.getMe();
      final cachedDetails = await storageService.getSessionDetails();
      final cachedFullName = cachedDetails['fullName'];

      final session = UserSession.fromAuthMe(
        meData,
        token,
        cachedFullName: cachedFullName,
      );

      return session;
    } on ApiException catch (e) {
      // If token is invalid (401), expired, or rejected, clear local storage
      if (e.statusCode == 401 || e.statusCode == 403) {
        await storageService.clearAll();
      }
      return null;
    } catch (_) {
      // In case of transient connection errors, fallback gracefully
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // The local session must still be cleared if the network is unavailable.
    } finally {
      await storageService.clearAll();
    }
  }

  @override
  Future<void> clearLocalSession() async {
    await storageService.clearAll();
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return await remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    return await remoteDataSource.getDepartments();
  }
}
