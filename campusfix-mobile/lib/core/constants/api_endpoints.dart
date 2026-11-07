/// Complete catalog of verified REST API endpoints on the CampusFix Core PHP backend.
class ApiEndpoints {
  ApiEndpoints._();

  // Health
  static const String health = '/health';

  // Authentication & Session
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String changePassword = '/profile/password';

  // Catalogs (Shared Read Access for Student, Staff, Admin)
  static const String locations = '/locations';
  static const String departments = '/departments';

  // Complaint Management (Student)
  static const String complaints = '/complaints';
  static const String myComplaints = '/complaints/my';
  static const String complaintDetails = '/complaints/show';

  // Staff Complaint Assignments (Staff)
  static const String staffAssignments = '/staff/complaints/my';
  static const String staffUpdateStatus = '/staff/complaints/status';

  // Feedback & Rating (Student)
  static const String feedback = '/feedback';
  static const String myFeedback = '/feedback/my';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationCount = '/notifications/unread-count';
  static const String markNotificationRead = '/notifications/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String deleteNotification = '/notifications/delete';
}
