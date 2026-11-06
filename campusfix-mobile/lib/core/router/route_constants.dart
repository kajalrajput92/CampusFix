/// Named route paths and route names for GoRouter.
class RouteConstants {
  RouteConstants._();

  // Root / Welcome
  static const String welcome = '/';

  // Authentication Flow
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Role Dashboards
  static const String studentDashboard = '/student/dashboard';
  static const String staffDashboard = '/staff/dashboard';

  // General Fallback
  static const String placeholder = '/placeholder';
}
