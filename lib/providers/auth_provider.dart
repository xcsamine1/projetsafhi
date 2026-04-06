import 'package:flutter/foundation.dart';
import '../models/professeur.dart';
import '../services/auth_service.dart';

/// Authentication state for the app.
///
/// Holds the currently logged-in [Professeur] and manages
/// login / logout lifecycle.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  // ─── State ────────────────────────────────────────────────────────────────
  Professeur? _professor;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────
  Professeur? get professor => _professor;
  String? get token => _token;
  bool get isAuthenticated => _professor != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Try to restore session from local storage.
  Future<void> tryRestoreSession() async {
    final session = await _authService.restoreSession();
    if (session != null) {
      _token = session['token'] as String;
      final fullName = session['name'] as String;
      final parts = fullName.split(' ');
      // Build a Professeur from stored data — email is now also persisted.
      _professor = Professeur(
        idProf: session['id'] as int,
        nom: parts.length > 1 ? parts.sublist(1).join(' ') : fullName,
        prenom: parts.first,
        email: session['email'] as String? ?? '',
      );
      notifyListeners();
    }
  }

  /// Perform login. Sets loading state and clears previous errors.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _professor = await _authService.login(email, password);
      _token = await _authService.getToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mock login for dummy-data mode — no real API call.
  void mockLogin() {
    _professor = const Professeur(
      idProf: 1,
      nom: 'Benali',
      prenom: 'Ahmed',
      email: 'ahmed.benali@univ.ma',
    );
    _token = 'mock-token-123';
    notifyListeners();
  }

  /// Logout: clear state and local storage.
  Future<void> logout() async {
    await _authService.logout();
    _professor = null;
    _token = null;
    notifyListeners();
  }
}
