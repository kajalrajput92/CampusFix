import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_mobile_landing_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/staff/presentation/staff_dashboard_screen.dart';
import '../../features/staff/presentation/staff_complaint_screens.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/student/presentation/complaint_screens.dart';
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

  final router = GoRouter(
    navigatorKey: AppRouter.navigatorKey,
    initialLocation: RouteConstants.welcome,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      return AppRouter.redirectForAccess(
        isAuthenticated: authState.isAuthenticated,
        role: authState.session?.role,
        path: state.uri.path,
      );
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
      GoRoute(path: RouteConstants.studentComplaints, builder: (context, state) => const MyComplaintsScreen()),
      GoRoute(path: RouteConstants.studentNewComplaint, builder: (context, state) => const SubmitComplaintScreen()),
      GoRoute(path: RouteConstants.studentComplaintDetails, builder: (context, state) => ComplaintDetailsScreen(complaintId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),
      GoRoute(path: RouteConstants.studentNotifications, builder: (context, state) => const StudentNotificationsScreen()),

      // Staff Dashboard
      GoRoute(
        path: RouteConstants.staffDashboard,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: RouteConstants.staffComplaints,
        builder: (context, state) => const StaffAssignmentsScreen(),
      ),
      GoRoute(
        path: RouteConstants.staffComplaintDetails,
        builder: (context, state) => StaffComplaintDetailsScreen(
          complaintId:
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: RouteConstants.staffNotifications,
        builder: (context, state) => const StaffNotificationsScreen(),
      ),
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const AdminMobileLandingScreen(),
      ),
      GoRoute(
        path: RouteConstants.unsupportedRole,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Unsupported Account Role',
          message:
              'This account role does not have access to the mobile application.',
          targetPhase: 'Contact CampusFix administration',
          icon: Icons.no_accounts_outlined,
        ),
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
  ref.onDispose(() {
    router.dispose();
    notifier.dispose();
  });
  return router;
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
      case AppConstants.roleAdmin:
        return RouteConstants.adminDashboard;
      case AppConstants.roleStudent:
        return RouteConstants.studentDashboard;
      default:
        return RouteConstants.unsupportedRole;
    }
  }

  /// Redirects protected, authentication, and role-specific routes safely.
  static String? redirectForAccess({
    required bool isAuthenticated,
    required String? role,
    required String path,
  }) {
    final isAuthRoute = {
      RouteConstants.welcome,
      RouteConstants.login,
      RouteConstants.register,
      RouteConstants.forgotPassword,
      RouteConstants.resetPassword,
    }.contains(path);

    if (!isAuthenticated) {
      return isAuthRoute ? null : RouteConstants.welcome;
    }
    if (isAuthRoute) {
      return resolveRoleDestination(role ?? '');
    }
    return roleGuardRedirect(role ?? '', path);
  }

  /// Returns a safe landing route when [path] is outside [role]'s portal.
  static String? roleGuardRedirect(String role, String path) {
    final normalizedRole = role.toUpperCase();
    final isStudentRoute = path.startsWith('/student');
    final isStaffRoute = path.startsWith('/staff');
    final isAdminRoute = path.startsWith('/admin');

    switch (normalizedRole) {
      case AppConstants.roleStudent:
        return isStaffRoute || isAdminRoute
            ? RouteConstants.studentDashboard
            : null;
      case AppConstants.roleStaff:
        return isStudentRoute || isAdminRoute
            ? RouteConstants.staffDashboard
            : null;
      case AppConstants.roleAdmin:
        return isStudentRoute || isStaffRoute
            ? RouteConstants.adminDashboard
            : null;
      default:
        return path == RouteConstants.unsupportedRole
            ? null
            : RouteConstants.unsupportedRole;
    }
  }
}
