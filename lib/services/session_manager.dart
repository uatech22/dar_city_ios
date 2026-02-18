import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  static final SessionManager _instance = SessionManager._internal();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'api_token';

  // In-memory token for quick, synchronous access
  String? _token;

  /// Load token from secure storage into memory.
  Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  /// Save token to memory and secure storage.
  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get token from memory. IMPORTANT: `loadToken` must be called first.
  String? getToken() {
    return _token;
  }

  /// Clear token from memory and secure storage.
  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }
}
