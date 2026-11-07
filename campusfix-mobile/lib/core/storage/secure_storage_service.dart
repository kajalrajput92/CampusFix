import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Secure token and session storage wrapper utilizing platform-level secure storage
/// (Keychain on iOS, Keystore/EncryptedSharedPreferences on Android).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Saves the authenticated JWT access token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyJwtToken, value: token);
  }

  /// Retrieves the stored JWT access token, or null if unauthenticated.
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyJwtToken);
  }

  /// Deletes the stored JWT access token upon logout.
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.keyJwtToken);
  }

  /// Saves the active user role (STUDENT, STAFF, or ADMIN).
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: AppConstants.keyUserRole, value: role);
  }

  /// Retrieves the active user role.
  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.keyUserRole);
  }

  /// Persists full user profile details upon successful login.
  Future<void> saveSessionDetails({
    required int userId,
    required String fullName,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: AppConstants.keyUserId, value: userId.toString());
    await _storage.write(key: AppConstants.keyUserName, value: fullName);
    await _storage.write(key: AppConstants.keyUserEmail, value: email);
    await _storage.write(key: AppConstants.keyUserRole, value: role);
  }

  /// Retrieves the stored session identity.
  Future<Map<String, String?>> getSessionDetails() async {
    final token = await getToken();
    final role = await getUserRole();
    final userId = await _storage.read(key: AppConstants.keyUserId);
    final fullName = await _storage.read(key: AppConstants.keyUserName);
    final email = await _storage.read(key: AppConstants.keyUserEmail);

    return {
      'token': token,
      'role': role,
      'userId': userId,
      'fullName': fullName,
      'email': email,
    };
  }

  /// Clears all stored credentials and user session data.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
