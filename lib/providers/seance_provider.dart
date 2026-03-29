import 'package:flutter/foundation.dart';
import '../models/seance.dart';
import '../models/metadata.dart';
import '../services/seance_service.dart';

/// Manages the list of sessions and optional date filtering.
class SeanceProvider extends ChangeNotifier {
  final SeanceService _service;

  SeanceProvider(this._service);

  // ─── State ────────────────────────────────────────────────────────────────
  List<Seance> _allSeances = [];
  DateTime? _selectedDate;
  int? _profId;
  bool _isLoading = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get selectedDate => _selectedDate;

  /// Today's sessions for the current professor.
  List<Seance> get todaySeances => _service.filterSeances(
        _allSeances,
        profId: _profId,
        date: DateTime.now(),
      );

  /// Sessions filtered by the selected date (or all if none selected).
  List<Seance> get filteredSeances => _service.filterSeances(
        _allSeances,
        profId: _profId,
        date: _selectedDate,
      );

  /// Full list (prof-filtered only).
  List<Seance> get allSeances =>
      _service.filterSeances(_allSeances, profId: _profId);

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Load sessions from the service.
  Future<void> loadSeances({required int profId, String? token}) async {
    _profId = profId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allSeances = await _service.getSeances(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set date filter; pass null to clear.
  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Load metadata (filieres & modules) for creation.
  Future<SeanceMetadata?> fetchMetadata({String? token}) async {
    return _service.fetchMetadata(token: token);
  }

  /// Add a seance locally and remotely.
  Future<void> addSeance(Seance seance, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSeance = await _service.createSeance(seance, token: token);
      _allSeances.insert(0, newSeance);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
