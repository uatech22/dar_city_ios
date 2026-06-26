import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:dar_city_app/services/push_notification_service.dart';

class SessionManager {
  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  static final SessionManager _instance = SessionManager._internal();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'api_token';
  static const _roleKey = 'user_role';
  static const _personIdKey = 'person_id';
  static const _teamIdKey = 'team_id';
  static const _userIdKey = 'user_id';

  String? _token;
  String? _role;
  int? _personId;
  int? _teamId;
  int? _userId;

  Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  Future<void> loadRole() async {
    _role = await _storage.read(key: _roleKey);
  }

  Future<void> loadPersonId() async {
    final value = await _storage.read(key: _personIdKey);
    _personId = value == null ? null : int.tryParse(value);
  }

  Future<void> loadTeamId() async {
    final value = await _storage.read(key: _teamIdKey);
    _teamId = value == null ? null : int.tryParse(value);
  }

  Future<void> loadUserId() async {
    final value = await _storage.read(key: _userIdKey);
    _userId = value == null ? null : int.tryParse(value);
  }

  /// Load all session fields from secure storage.
  Future<void> loadSession() async {
    await Future.wait([
      loadToken(),
      loadRole(),
      loadPersonId(),
      loadTeamId(),
      loadUserId(),
    ]);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveRole(String role) async {
    _role = role;
    await _storage.write(key: _roleKey, value: role);
  }

  Future<void> savePersonId(int? personId) async {
    _personId = personId;
    if (personId == null) {
      await _storage.delete(key: _personIdKey);
    } else {
      await _storage.write(key: _personIdKey, value: personId.toString());
    }
  }

  Future<void> saveTeamId(int? teamId) async {
    _teamId = teamId;
    if (teamId == null) {
      await _storage.delete(key: _teamIdKey);
    } else {
      await _storage.write(key: _teamIdKey, value: teamId.toString());
    }
  }

  Future<void> saveUserId(int? userId) async {
    _userId = userId;
    if (userId == null) {
      await _storage.delete(key: _userIdKey);
    } else {
      await _storage.write(key: _userIdKey, value: userId.toString());
    }
  }

  String? getToken() => _token;

  String? getRole() => _role;

  int? getPersonId() => _personId;

  int? getTeamId() => _teamId;

  int? getUserId() => _userId;

  Future<void> clearToken() async {
    await PushNotificationService.instance.unregisterDeviceToken();
    _token = null;
    _role = null;
    _personId = null;
    _teamId = null;
    _userId = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _personIdKey);
    await _storage.delete(key: _teamIdKey);
    await _storage.delete(key: _userIdKey);
  }
}
