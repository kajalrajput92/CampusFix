import 'package:flutter/foundation.dart';

import '../../../../shared/models/user_session.dart';

/// Lifecycle statuses for user authentication state.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Immutable state model representing authentication, session details, and error notifications.
@immutable
class AuthState {
  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading({UserSession? currentSession}) =>
      AuthState(status: AuthStatus.loading, session: currentSession);

  factory AuthState.authenticated(UserSession session) =>
      AuthState(status: AuthStatus.authenticated, session: session);

  factory AuthState.unauthenticated({String? message}) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: message);

  factory AuthState.error(String message, {UserSession? currentSession}) =>
      AuthState(
        status: AuthStatus.error,
        session: currentSession,
        errorMessage: message,
      );

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          session == other.session &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^ session.hashCode ^ errorMessage.hashCode;
}
