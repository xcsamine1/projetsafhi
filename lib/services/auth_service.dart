import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/professeur.dart';
import 'api_service.dart';

/// Handles login and local auth-token persistence.
class AuthService {
  final ApiService _api;

  AuthService(this._api);

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

    return prof;
  }

  /// Restore session from local storage.
  /// Returns saved professor id and name if still logged in.
  Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.authToken);
    final id = prefs.getInt(StorageKeys.professorId);
    final name = prefs.getString(StorageKeys.professorName);
    if (token != null && id != null && name != null) {
      return {'token': token, 'id': id, 'name': name};
    }
    return null;
  }

  /// Clear saved session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.professorId);
    await prefs.remove(StorageKeys.professorName);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authToken);
  }
}
