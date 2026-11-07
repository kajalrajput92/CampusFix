import 'package:flutter_test/flutter_test.dart';
import 'package:campusfix/core/network/api_exception.dart';
import 'package:campusfix/core/network/auth_interceptor.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:campusfix/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:campusfix/features/auth/data/models/department_model.dart';
import 'package:campusfix/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';

/// In-memory fake implementation of SecureStorageService for test isolation.
class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveToken(String token) async {
    _storage['jwt_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _storage['jwt_token'];
  }

  @override
  Future<void> deleteToken() async {
    _storage.remove('jwt_token');
  }

  @override
  Future<void> saveUserRole(String role) async {
    _storage['user_role'] = role;
  }

  @override
  Future<String?> getUserRole() async {
    return _storage['user_role'];
  }

  @override
  Future<void> saveSessionDetails({
    required int userId,
    required String fullName,
    required String email,
    required String role,
  }) async {
    _storage['user_id'] = userId.toString();
    _storage['user_name'] = fullName;
    _storage['user_email'] = email;
    _storage['user_role'] = role;
  }

  @override
  Future<Map<String, String?>> getSessionDetails() async {
    return {
      'token': _storage['jwt_token'],
      'role': _storage['user_role'],
      'userId': _storage['user_id'],
      'fullName': _storage['user_name'],
      'email': _storage['user_email'],
    };
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }
}

/// Fake Remote Data Source simulating Core PHP REST responses.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Map<String, dynamic>? mockLoginResult;
  ApiException? mockLoginException;

  Map<String, dynamic>? mockRegisterResult;
  ApiException? mockRegisterException;

  Map<String, dynamic>? mockMeResult;
  ApiException? mockMeException;

  String? mockForgotPasswordResult;
  ApiException? mockForgotPasswordException;

  String? mockResetPasswordResult;
  ApiException? mockResetPasswordException;

  List<DepartmentModel> mockDepartments = [];

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (mockLoginException != null) throw mockLoginException!;
    return mockLoginResult ??
        {
          'access_token': 'fake.jwt.token',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': {
            'user_id': 1,
            'full_name': 'Test User',
            'email': email,
            'role': 'STUDENT',
          },
        };
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
    if (mockRegisterException != null) throw mockRegisterException!;
    return mockRegisterResult ??
        {
          'user_id': 2,
          'full_name': fullName,
          'email': email,
          'role': 'STUDENT',
        };
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    if (mockMeException != null) throw mockMeException!;
    return mockMeResult ??
        {'user_id': 1, 'email': 'test@campus.edu', 'role': 'STUDENT'};
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    if (mockForgotPasswordException != null) {
      throw mockForgotPasswordException!;
    }
    return mockForgotPasswordResult ??
        'If an account exists with this email, password reset instructions will be sent.';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (mockResetPasswordException != null) {
      throw mockResetPasswordException!;
    }
    return mockResetPasswordResult ??
        'Password has been reset successfully. Please log in again.';
  }

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    return mockDepartments;
  }
}

class FakeErrorInterceptorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}

void main() {
  group('AuthRepository Unit Tests', () {
    late FakeSecureStorageService fakeStorage;
    late FakeAuthRemoteDataSource fakeRemote;
    late AuthRepositoryImpl repository;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      fakeRemote = FakeAuthRemoteDataSource();
      repository = AuthRepositoryImpl(
        remoteDataSource: fakeRemote,
        storageService: fakeStorage,
      );
    });

    test(
      'login success persists token, saves session, and returns UserSession',
      () async {
        fakeRemote.mockLoginResult = {
          'access_token': 'token_abc_123',
          'user': {
            'user_id': 42,
            'full_name': 'Alice Student',
            'email': 'alice@campus.edu',
            'role': 'STUDENT',
          },
        };

        final session = await repository.login(
          email: 'alice@campus.edu',
          password: 'Password123',
          targetRole: 'STUDENT',
        );

        expect(session.userId, 42);
        expect(session.fullName, 'Alice Student');
        expect(session.email, 'alice@campus.edu');
        expect(session.role, 'STUDENT');
        expect(session.token, 'token_abc_123');
        expect(session.isStudent, true);

        // Verify stored in secure storage
        expect(await fakeStorage.getToken(), 'token_abc_123');
        final details = await fakeStorage.getSessionDetails();
        expect(details['fullName'], 'Alice Student');
        expect(details['role'], 'STUDENT');
      },
    );

    test('login failure propagates ApiException', () async {
      fakeRemote.mockLoginException = const ApiException(
        message: 'Invalid email or password.',
        statusCode: 401,
      );

      expect(
        () => repository.login(
          email: 'wrong@campus.edu',
          password: 'BadPassword',
          targetRole: 'STUDENT',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password.',
          ),
        ),
      );

      // Verify nothing saved to storage
      expect(await fakeStorage.getToken(), isNull);
    });

    test(
      'role mismatch throws AuthRoleMismatchException without saving token',
      () async {
        fakeRemote.mockLoginResult = {
          'access_token': 'token_student_only',
          'user': {
            'user_id': 10,
            'full_name': 'Bob Student',
            'email': 'bob@campus.edu',
            'role': 'STUDENT',
          },
        };

        // Trying to enter Staff portal with a Student account
        expect(
          () => repository.login(
            email: 'bob@campus.edu',
            password: 'Password123',
            targetRole: 'STAFF',
          ),
          throwsA(
            isA<AuthRoleMismatchException>().having(
              (e) => e.message,
              'message',
              contains('Access denied: This account is registered as STUDENT'),
            ),
          ),
        );

        // Verify token was rejected and not persisted
        expect(await fakeStorage.getToken(), isNull);
      },
    );

    test('registration success returns created user data', () async {
      fakeRemote.mockRegisterResult = {
        'user_id': 99,
        'full_name': 'Charlie New',
        'email': 'charlie@campus.edu',
        'role': 'STUDENT',
      };

      final result = await repository.register(
        fullName: 'Charlie New',
        email: 'charlie@campus.edu',
        password: 'Password123',
        departmentId: 1,
      );

      expect(result['user_id'], 99);
      expect(result['full_name'], 'Charlie New');
      expect(result['email'], 'charlie@campus.edu');
    });

    test('registration validation failure throws ApiException', () async {
      fakeRemote.mockRegisterException = const ApiException(
        message: 'Email is already registered.',
        statusCode: 422,
      );

      expect(
        () => repository.register(
          fullName: 'Duplicate User',
          email: 'existing@campus.edu',
          password: 'Password123',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Email is already registered.',
          ),
        ),
      );
    });

    test('forgotPassword returns server confirmation message', () async {
      final msg = await repository.forgotPassword(email: 'user@campus.edu');
      expect(msg, contains('password reset instructions will be sent'));
    });

    test('resetPassword success returns success message', () async {
      final msg = await repository.resetPassword(
        token: 'a' * 64,
        newPassword: 'NewPassword123',
      );
      expect(msg, contains('Password has been reset successfully'));
    });

    test('resetPassword with invalid token throws ApiException', () async {
      fakeRemote.mockResetPasswordException = const ApiException(
        message: 'Invalid or expired password reset token.',
        statusCode: 422,
      );

      expect(
        () => repository.resetPassword(
          token: 'invalid_token',
          newPassword: 'NewPassword123',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid or expired password reset token.',
          ),
        ),
      );
    });

    test(
      'restoreSession restores session when token and /me are valid',
      () async {
        await fakeStorage.saveToken('valid_stored_token');
        await fakeStorage.saveSessionDetails(
          userId: 15,
          fullName: 'Cached Full Name',
          email: 'cached@campus.edu',
          role: 'STAFF',
        );

        fakeRemote.mockMeResult = {
          'user_id': 15,
          'email': 'cached@campus.edu',
          'role': 'STAFF',
        };

        final session = await repository.restoreSession();

        expect(session, isNotNull);
        expect(session!.userId, 15);
        expect(session.fullName, 'Cached Full Name');
        expect(session.role, 'STAFF');
        expect(session.isStaff, true);
      },
    );

    test(
      'restoreSession clears storage and returns null when token expired (401)',
      () async {
        await fakeStorage.saveToken('expired_token');
        fakeRemote.mockMeException = const ApiException(
          message: 'Unauthorized. Invalid or expired token.',
          statusCode: 401,
        );

        final session = await repository.restoreSession();

        expect(session, isNull);
        expect(await fakeStorage.getToken(), isNull);
      },
    );

    test('logout clears all secure storage', () async {
      await fakeStorage.saveToken('active_token');
      await fakeStorage.saveUserRole('STUDENT');

      await repository.logout();

      expect(await fakeStorage.getToken(), isNull);
      expect(await fakeStorage.getUserRole(), isNull);
    });

    test(
      'AuthInterceptor triggers onSessionExpired on 401 for protected routes',
      () {
        bool sessionExpiredFired = false;
        final interceptor = AuthInterceptor(
          fakeStorage,
          onSessionExpired: () {
            sessionExpiredFired = true;
          },
        );

        // Protected route (e.g. /complaints) receiving 401
        final protectedError = DioException(
          requestOptions: RequestOptions(path: '/complaints'),
          response: Response(
            requestOptions: RequestOptions(path: '/complaints'),
            statusCode: 401,
          ),
        );

        interceptor.onError(protectedError, FakeErrorInterceptorHandler());
        expect(sessionExpiredFired, true);

        // Auth route (e.g. /auth/login) receiving 401 should NOT trigger session expired
        sessionExpiredFired = false;
        final loginError = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );

        interceptor.onError(loginError, FakeErrorInterceptorHandler());
        expect(sessionExpiredFired, false);
      },
    );
  });
}
