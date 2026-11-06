import 'package:dio/dio.dart';

/// Structured application exception representing API network and business errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic rawData;

  const ApiException({required this.message, this.statusCode, this.rawData});

  /// Factory translating DioException into clean user-facing error messages.
  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message:
              'Connection timed out. Please check your internet connectivity.',
          statusCode: 408,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to the CampusFix server. Please verify your connection.',
          statusCode: 503,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        final responseData = response?.data;

        String extractedMessage = 'An unexpected server error occurred.';

        if (responseData is Map<String, dynamic>) {
          if (responseData['message'] is String &&
              (responseData['message'] as String).trim().isNotEmpty) {
            extractedMessage = responseData['message'] as String;
          }
        } else if (responseData is String && responseData.trim().isNotEmpty) {
          extractedMessage = responseData;
        } else {
          switch (statusCode) {
            case 400:
              extractedMessage = 'Bad request. Please verify your input.';
              break;
            case 401:
              extractedMessage = 'Unauthorized. Invalid email or password.';
              break;
            case 403:
              extractedMessage = 'Access forbidden for this account role.';
              break;
            case 404:
              extractedMessage = 'The requested endpoint was not found.';
              break;
            case 422:
              extractedMessage =
                  'Validation failed. Please verify submitted fields.';
              break;
            case 500:
            default:
              extractedMessage =
                  'Internal server error. Please try again later.';
              break;
          }
        }

        return ApiException(
          message: extractedMessage,
          statusCode: statusCode,
          rawData: responseData,
        );

      case DioExceptionType.cancel:
        return const ApiException(message: 'The network request was canceled.');

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'SSL certificate verification failed.',
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message:
              dioException.message ?? 'A network communication error occurred.',
          rawData: dioException.error,
        );
    }
  }

  @override
  String toString() => message;
}

/// Custom exception thrown when the authenticated user role does not match
/// the selected portal (e.g. Student trying to log into Staff portal).
class AuthRoleMismatchException extends ApiException {
  final String actualRole;
  final String expectedRole;

  AuthRoleMismatchException({
    required this.actualRole,
    required this.expectedRole,
  }) : super(
         message:
             'Access denied: This account is registered as $actualRole. Please use the $actualRole Portal.',
         statusCode: 403,
       );
}
