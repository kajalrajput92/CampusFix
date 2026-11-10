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
  static const String studentComplaints = '/student/complaints';
  static const String studentNewComplaint = '/student/complaints/new';
  static const String studentComplaintDetails = '/student/complaints/:id';
  static const String studentNotifications = '/student/notifications';
  static const String staffDashboard = '/staff/dashboard';
  static const String staffComplaints = '/staff/complaints';
  static const String staffComplaintDetails = '/staff/complaints/:id';
  static const String staffNotifications = '/staff/notifications';
  static const String adminDashboard = '/admin/dashboard';
  static const String unsupportedRole = '/access/unsupported-role';

  // General Fallback
  static const String placeholder = '/placeholder';
}
