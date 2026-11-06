import '../../../../shared/models/user_session.dart';
import '../../data/models/department_model.dart';

/// Abstract contract for authentication and session management in CampusFix.
abstract class AuthRepository {
  /// Authenticates user against POST /api/auth/login and validates portal role.
  Future<UserSession> login({
    required String email,
    required String password,
    required String targetRole,
  });

  /// Registers a new student via POST /api/auth/register.
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? departmentId,
    String? enrollmentNumber,
  });

  /// Restores active session on app startup via GET /api/auth/me.
  Future<UserSession?> restoreSession();

  /// Logs out active user, clearing local secure storage.
  Future<void> logout();

  /// Requests password reset email via POST /api/auth/forgot-password.
  Future<String> forgotPassword({required String email});

  /// Resets user password using 64-char token via POST /api/auth/reset-password.
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Retrieves department catalog from GET /api/departments.
  Future<List<DepartmentModel>> getDepartments();
}
