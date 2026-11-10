import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfix/core/theme/app_theme.dart';
import 'package:campusfix/features/auth/data/models/department_model.dart';
import 'package:campusfix/features/auth/presentation/forgot_password_screen.dart';
import 'package:campusfix/features/auth/presentation/login_screen.dart';
import 'package:campusfix/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusfix/features/auth/presentation/register_screen.dart';
import 'package:campusfix/features/auth/presentation/reset_password_screen.dart';
import 'package:campusfix/features/auth/presentation/welcome_screen.dart';
import 'package:campusfix/shared/models/user_session.dart';

import '../unit/auth_notifier_test.dart';

void main() {
  Widget createTestWidget(
    Widget child, {
    MockAuthRepository? repo,
    List<DepartmentModel>? departments,
  }) {
    return ProviderScope(
      overrides: [
        if (repo != null) authRepositoryProvider.overrideWithValue(repo),
        departmentsProvider.overrideWith(
          (ref) => Future.value(departments ?? const []),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  group('WelcomeScreen role portals', () {
    testWidgets('offers student, staff, and admin sign-in portals', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Student Portal'), findsOneWidget);
      expect(find.text('Staff Portal'), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders Student Login elements properly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Login'), findsOneWidget);
      expect(find.text('STUDENT PORTAL'), findsOneWidget);
      expect(find.byKey(const Key('loginEmailField')), findsOneWidget);
      expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
      expect(find.text('Register as Student'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('renders Staff Login without student registration link', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STAFF')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Member Login'), findsOneWidget);
      expect(find.text('STAFF PORTAL'), findsOneWidget);
      expect(find.text('Register as Student'), findsNothing);
    });

    testWidgets('renders Admin Login without student-only links', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'ADMIN')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrator Login'), findsOneWidget);
      expect(find.text('ADMIN PORTAL'), findsOneWidget);
      expect(find.text('Register as Student'), findsNothing);
      expect(find.text('Switch to Staff Portal'), findsNothing);
    });

    testWidgets('displays validation messages on empty submit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('displays validation message on invalid email format', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('displays validation message on short password', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'valid@campus.edu',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'short',
      );
      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('toggles password visibility when icon clicked', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT')),
      );
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.byKey(const Key('loginPasswordField'));
      TextField textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, true);

      await tester.tap(find.byKey(const Key('loginPasswordVisibilityToggle')));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, false);
    });

    testWidgets('shows loading state on valid submit', (tester) async {
      final repo = MockAuthRepository();
      repo.loginCompleter = Completer<UserSession>();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(targetRole: 'STUDENT'), repo: repo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'user@campus.edu',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'Password123',
      );

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pump(); // Frame when loading starts

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete login
      repo.loginCompleter!.complete(
        const UserSession(
          userId: 1,
          fullName: 'Student',
          email: 'user@campus.edu',
          role: 'STUDENT',
          token: 'token',
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all student registration fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Student Registration'), findsOneWidget);
      expect(find.byKey(const Key('registerFullNameField')), findsOneWidget);
      expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
      expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);
      expect(
        find.byKey(const Key('registerConfirmPasswordField')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('registerEnrollmentField')), findsOneWidget);
      expect(find.byKey(const Key('registerPhoneField')), findsOneWidget);
      expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    });

    testWidgets('validates required fields and password mismatch', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('registerSubmitButton')));
      await tester.tap(find.byKey(const Key('registerSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Email address is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);

      // Now enter mismatched passwords
      await tester.enterText(
        find.byKey(const Key('registerFullNameField')),
        'John Doe',
      );
      await tester.enterText(
        find.byKey(const Key('registerEmailField')),
        'john@campus.edu',
      );
      await tester.enterText(
        find.byKey(const Key('registerPasswordField')),
        'Password123',
      );
      await tester.enterText(
        find.byKey(const Key('registerConfirmPasswordField')),
        'DifferentPassword',
      );

      await tester.ensureVisible(find.byKey(const Key('registerSubmitButton')));
      await tester.tap(find.byKey(const Key('registerSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('renders email input and submit button', (tester) async {
      await tester.pumpWidget(createTestWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.byKey(const Key('forgotPasswordEmailField')), findsOneWidget);
      expect(
        find.byKey(const Key('forgotPasswordSubmitButton')),
        findsOneWidget,
      );
      expect(find.text('I Have a Reset Token'), findsOneWidget);
    });

    testWidgets('validates email on submit', (tester) async {
      await tester.pumpWidget(createTestWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forgotPasswordSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required.'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('renders token and new password fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('resetPasswordTokenField')), findsOneWidget);
      expect(find.byKey(const Key('resetPasswordNewField')), findsOneWidget);
      expect(
        find.byKey(const Key('resetPasswordConfirmField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('resetPasswordSubmitButton')),
        findsOneWidget,
      );
    });

    testWidgets('validates 64-character token requirement', (tester) async {
      await tester.pumpWidget(createTestWidget(const ResetPasswordScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('resetPasswordTokenField')),
        'short_token',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordNewField')),
        'NewPassword123',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordConfirmField')),
        'NewPassword123',
      );

      await tester.tap(find.byKey(const Key('resetPasswordSubmitButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Token must be a valid 64-character hexadecimal code.'),
        findsOneWidget,
      );
    });
  });
}
