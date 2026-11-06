/// Application-wide constant definitions for CampusFix.
class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'CampusFix';
  static const String appTagline =
      'Smart Campus Issue Reporting & Resolution Platform';
  static const String appDescription =
      'Connecting students, staff members, and campus administration for rapid, transparent, and verified facility maintenance.';

  // User Roles (Matching Backend Enum)
  static const String roleStudent = 'STUDENT';
  static const String roleStaff = 'STAFF';
  static const String roleAdmin = 'ADMIN';

  // Secure Storage Keys
  static const String keyJwtToken = 'campusfix_jwt_token';
  static const String keyUserRole = 'campusfix_user_role';
  static const String keyUserId = 'campusfix_user_id';
  static const String keyUserEmail = 'campusfix_user_email';
  static const String keyUserName = 'campusfix_user_name';

  // UI Layout Constants
  static const double defaultPadding = 16.0;
  static const double cardPadding = 20.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonHeight = 52.0;
}
