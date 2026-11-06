import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/staff/presentation/staff_dashboard_screen.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../constants/app_constants.dart';
import '../widgets/placeholder_screen.dart';
import 'route_constants.dart';

/// Helper ChangeNotifier allowing GoRouter to re-evaluate redirect guards
/// whenever the authentication state changes in Riverpod.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, _) {
      notifyListeners();
    });
  }
}

/// Provider creating the configured, route-protected GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: AppRouter.navigatorKey,
    initialLocation: RouteConstants.welcome,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final session = authState.session;
      final isAuthenticated = authState.isAuthenticated;
      final location = state.uri.path;

      final isAuthRoute =
          location == RouteConstants.welcome ||
          location == RouteConstants.login ||
          location == RouteConstants.register ||
          location == RouteConstants.forgotPassword ||
          location == RouteConstants.resetPassword;

      // 1. Unauthenticated users cannot access protected dashboards
      if (!isAuthenticated) {
        if (!isAuthRoute) {
          return RouteConstants.welcome;
        }
        return null;
      }

      // 2. Authenticated users are redirected away from login/welcome screens to their portal
      if (isAuthRoute) {
        return AppRouter.resolveRoleDestination(session?.role ?? 'STUDENT');
      }

      // 3. Enforce strict role boundary (Students cannot access Staff dashboards and vice versa)
      if (session != null) {
        if (session.isStudent && location.startsWith('/staff')) {
          return RouteConstants.studentDashboard;
        }
        if (session.isStaff && location.startsWith('/student')) {
          return RouteConstants.staffDashboard;
        }
      }

      return null;
    },
    routes: [
      // Entry / Welcome Screen
      GoRoute(
        path: RouteConstants.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Login Entry Point
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) {
          final role =
              state.uri.queryParameters['role'] ?? AppConstants.roleStudent;
          final email = state.uri.queryParameters['email'];
          return LoginScreen(targetRole: role, initialEmail: email);
        },
      ),

      // Student Registration
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Forgot Password Request
      GoRoute(
        path: RouteConstants.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Reset Password with Token
      GoRoute(
        path: RouteConstants.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(initialToken: token);
        },
      ),

      // Student Dashboard
      GoRoute(
        path: RouteConstants.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),

      // Staff Dashboard
      GoRoute(
        path: RouteConstants.staffDashboard,
        builder: (context, state) => const StaffDashboardScreen(),
      ),

      // Fallback Placeholder
      GoRoute(
        path: RouteConstants.placeholder,
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Coming Soon';
          final phase = state.uri.queryParameters['phase'] ?? 'Phase 5+';
          return PlaceholderScreen(title: title, targetPhase: phase);
        },
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(
      title: 'Page Not Found',
      message: 'The requested route "${state.uri}" does not exist.',
      targetPhase: 'N/A',
      icon: Icons.error_outline_rounded,
    ),
  );
});

/// Centralized GoRouter routing configuration reference for CampusFix.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Resolves the landing destination based on an authenticated role.
  static String resolveRoleDestination(String role) {
    switch (role.toUpperCase()) {
      case AppConstants.roleStaff:
        return RouteConstants.staffDashboard;
      case AppConstants.roleStudent:
      default:
        return RouteConstants.studentDashboard;
    }
  }
}
