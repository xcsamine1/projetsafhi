import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/professeur.dart';
import 'api_service.dart';

/// Handles login and local auth-token persistence.
class AuthService {
  final ApiService _api;

  AuthService(this._api);

  /// In-memory token cache — avoids repeated SharedPreferences reads.
  String? _cachedToken;

  /// Attempt login with email + password.
  /// Returns the authenticated [Professeur] on success.
  /// Throws [ApiException] on failure.
  Future<Professeur> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    // Parse response — adjust field names to match your backend.
    final token = data['token'] as String;
    final prof = Professeur.fromJson(data['professeur'] as Map<String, dynamic>);

    // Persist token and professor info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.authToken, token);
    await prefs.setInt(StorageKeys.professorId, prof.idProf);
    await prefs.setString(StorageKeys.professorName, prof.fullName);
    await prefs.setString(StorageKeys.professorEmail, prof.email); // store email
    _cachedToken = token; // cache in memory

    return prof;
  }

  /// Restore session from local storage.
  /// Returns saved professor data if still logged in.
  Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.authToken);
    final id = prefs.getInt(StorageKeys.professorId);
    final name = prefs.getString(StorageKeys.professorName);
    final email = prefs.getString(StorageKeys.professorEmail) ?? '';
    if (token != null && id != null && name != null) {
      _cachedToken = token; // warm the in-memory cache on restore
      return {'token': token, 'id': id, 'name': name, 'email': email};
    }
    return null;
  }

  /// Clear saved session.
  Future<void> logout() async {
    _cachedToken = null; // evict in-memory cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.professorId);
    await prefs.remove(StorageKeys.professorName);
    await prefs.remove(StorageKeys.professorEmail);
  }

  /// Return the token — from memory if available, otherwise from SharedPreferences.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authToken);
  }
}
