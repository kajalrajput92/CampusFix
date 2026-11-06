import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:campusfix/core/network/api_exception.dart';
import 'package:campusfix/features/auth/data/models/department_model.dart';
import 'package:campusfix/features/auth/domain/repositories/auth_repository.dart';
import 'package:campusfix/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusfix/features/auth/presentation/providers/auth_state.dart';
import 'package:campusfix/shared/models/user_session.dart';

class MockAuthRepository implements AuthRepository {
  Completer<UserSession>? loginCompleter;
  UserSession? mockLoginSession;
  ApiException? mockLoginError;

  Map<String, dynamic>? mockRegisterResult;
  ApiException? mockRegisterError;

  UserSession? mockRestoreSession;
  String? mockForgotMessage;
  String? mockResetMessage;

  bool logoutCalled = false;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
    required String targetRole,
  }) async {
    if (loginCompleter != null) {
      return await loginCompleter!.future;
    }
    if (mockLoginError != null) throw mockLoginError!;
    return mockLoginSession ??
        UserSession(
          userId: 1,
          fullName: 'Test User',
          email: email,
          role: targetRole,
          token: 'mock.token',
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
    if (mockRegisterError != null) throw mockRegisterError!;
    return mockRegisterResult ?? {'user_id': 1};
  }

  @override
  Future<UserSession?> restoreSession() async {
    return mockRestoreSession;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return mockForgotMessage ?? 'Success';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return mockResetMessage ?? 'Success';
  }

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    return const [];
  }
}

void main() {
  group('AuthNotifier Unit Tests', () {
    late MockAuthRepository mockRepo;
    late AuthNotifier notifier;

    setUp(() {
      mockRepo = MockAuthRepository();
      notifier = AuthNotifier(mockRepo);
    });

    test('initial state is AuthStatus.initial', () {
      expect(notifier.state.status, AuthStatus.initial);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.session, isNull);
    });

    test(
      'restoreSession transitions to authenticated when session exists',
      () async {
        mockRepo.mockRestoreSession = const UserSession(
          userId: 5,
          fullName: 'Existing User',
          email: 'exist@campus.edu',
          role: 'STUDENT',
          token: 'token.123',
        );

        await notifier.restoreSession();

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.isAuthenticated, true);
        expect(notifier.state.session!.fullName, 'Existing User');
      },
    );

    test(
      'restoreSession transitions to unauthenticated when no session exists',
      () async {
        mockRepo.mockRestoreSession = null;

        await notifier.restoreSession();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.isAuthenticated, false);
      },
    );

    test('login success sets state to authenticated', () async {
      final success = await notifier.login(
        email: 'user@campus.edu',
        password: 'Password123',
        targetRole: 'STUDENT',
      );

      expect(success, true);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.session!.email, 'user@campus.edu');
    });

    test('login failure sets state to error with message', () async {
      mockRepo.mockLoginError = const ApiException(
        message: 'Invalid email or password.',
        statusCode: 401,
      );

      final success = await notifier.login(
        email: 'wrong@campus.edu',
        password: 'Password123',
        targetRole: 'STUDENT',
      );

      expect(success, false);
      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.hasError, true);
      expect(notifier.state.errorMessage, 'Invalid email or password.');
    });

    test('logout clears session and sets state to unauthenticated', () async {
      // First log in
      await notifier.login(
        email: 'user@campus.edu',
        password: 'Password123',
        targetRole: 'STUDENT',
      );
      expect(notifier.state.isAuthenticated, true);

      // Now logout
      await notifier.logout();

      expect(mockRepo.logoutCalled, true);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.session, isNull);
    });

    test(
      'handleSessionExpired sets unauthenticated state with expiration message',
      () async {
        await notifier.login(
          email: 'user@campus.edu',
          password: 'Password123',
          targetRole: 'STUDENT',
        );

        await notifier.handleSessionExpired();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.isAuthenticated, false);
        expect(
          notifier.state.errorMessage,
          'Your session has expired. Please log in again.',
        );
      },
    );
  });
}
