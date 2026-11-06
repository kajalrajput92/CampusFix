import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

/// Interceptor that automatically injects the Bearer JWT token into outgoing
/// HTTP requests when an authenticated session exists, and detects 401 token
/// expirations on protected routes.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  void Function()? onSessionExpired;

  AuthInterceptor(this._storageService, {this.onSessionExpired});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthRoute =
          path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/forgot-password') ||
          path.contains('/auth/reset-password');

      if (!isAuthRoute) {
        onSessionExpired?.call();
      }
    }

    return handler.next(err);
  }
}
