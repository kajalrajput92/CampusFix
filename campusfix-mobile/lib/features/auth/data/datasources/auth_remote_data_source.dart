import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/department_model.dart';

/// Remote HTTP data source communicating with Core PHP authentication endpoints.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }

    throw const ApiException(
      message: 'Invalid response format received from authentication server.',
    );
  }

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? departmentId,
    String? enrollmentNumber,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = phone.trim();
    }
    if (departmentId != null && departmentId > 0) {
      payload['department_id'] = departmentId;
    }
    if (enrollmentNumber != null && enrollmentNumber.trim().isNotEmpty) {
      payload['enrollment_number'] = enrollmentNumber.trim();
    }

    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: payload,
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      return body;
    }

    throw const ApiException(
      message: 'Invalid response format received from registration server.',
    );
  }

  /// GET /api/auth/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.me);

    final body = response.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }

    throw const ApiException(
      message: 'Invalid response format received for session verification.',
      statusCode: 401,
    );
  }

  /// POST /api/auth/forgot-password
  Future<String> forgotPassword({required String email}) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim().toLowerCase()},
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['message'] is String) {
      return body['message'] as String;
    }

    return 'If an account exists with this email, password reset instructions will be sent.';
  }

  /// POST /api/auth/reset-password
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {'token': token.trim(), 'new_password': newPassword},
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['message'] is String) {
      return body['message'] as String;
    }

    return 'Password has been reset successfully. Please log in again.';
  }

  /// GET /api/departments
  Future<List<DepartmentModel>> getDepartments() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.departments);
      final body = response.data;

      if (body is Map<String, dynamic> && body['data'] is List) {
        final list = body['data'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(DepartmentModel.fromJson)
            .toList();
      }
      return const [];
    } on ApiException {
      // If unauthenticated or catalog unavailable, return empty list gracefully
      return const [];
    }
  }
}
