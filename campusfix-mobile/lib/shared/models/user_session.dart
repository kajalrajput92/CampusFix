import 'package:flutter/foundation.dart';

/// Immutable representation of an authenticated user session in CampusFix.
@immutable
class UserSession {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String token;

  const UserSession({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isStudent => role.toUpperCase() == 'STUDENT';
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserSession.fromMap(Map<String, dynamic> map, String token) {
    return UserSession(
      userId: map['user_id'] is int
          ? map['user_id'] as int
          : int.tryParse(map['user_id'].toString()) ?? 0,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: (map['role'] as String? ?? 'STUDENT').toUpperCase(),
      token: token,
    );
  }

  factory UserSession.fromAuthMe(
    Map<String, dynamic> data,
    String token, {
    String? cachedFullName,
  }) {
    return UserSession(
      userId: data['user_id'] is int
          ? data['user_id'] as int
          : int.tryParse(data['user_id'].toString()) ?? 0,
      fullName: cachedFullName ?? (data['full_name'] as String? ?? ''),
      email: data['email'] as String? ?? '',
      role: (data['role'] as String? ?? 'STUDENT').toUpperCase(),
      token: token,
    );
  }

  UserSession copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? role,
    String? token,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'token': token,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          role == other.role &&
          token == other.token;

  @override
  int get hashCode =>
      userId.hashCode ^ email.hashCode ^ role.hashCode ^ token.hashCode;

  @override
  String toString() =>
      'UserSession(userId: $userId, fullName: $fullName, email: $email, role: $role)';
}
