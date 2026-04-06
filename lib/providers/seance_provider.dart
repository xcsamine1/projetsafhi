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
  /// Seance IDs whose attendance has been saved in this app session.
  final Set<int> _submittedSeanceIds = {};

  // ─── Cached derived lists (recomputed lazily when state changes) ──────────
  List<Seance>? _cachedAll;
  List<Seance>? _cachedToday;
  List<Seance>? _cachedFiltered;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get selectedDate => _selectedDate;

  /// Returns true if attendance for [seanceId] has been saved.
  bool isSubmitted(int seanceId) => _submittedSeanceIds.contains(seanceId);

  /// Mark a seance as having its attendance saved and notify listeners.
  void markSubmitted(int seanceId) {
    _submittedSeanceIds.add(seanceId);
    notifyListeners();
  }

  /// Full list (prof-filtered only) — cached.
  List<Seance> get allSeances =>
      _cachedAll ??= _service.filterSeances(_allSeances, profId: _profId);

  /// Today's sessions for the current professor — cached.
  List<Seance> get todaySeances => _cachedToday ??= _service.filterSeances(
        _allSeances,
        profId: _profId,
        date: DateTime.now(),
      );

  /// Sessions filtered by the selected date (or all if none selected) — cached.
  List<Seance> get filteredSeances => _cachedFiltered ??= _service.filterSeances(
        _allSeances,
        profId: _profId,
        date: _selectedDate,
      );

  // Invalidate cached lists whenever underlying data changes.
  void _invalidateCache() {
    _cachedAll = null;
    _cachedToday = null;
    _cachedFiltered = null;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Load sessions from the service.
  Future<void> loadSeances({required int profId, String? token}) async {
    _profId = profId;
    _isLoading = true;
    _error = null;
    _submittedSeanceIds.clear();
    _invalidateCache();
    notifyListeners();

    try {
      _allSeances = await _service.getSeances(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Set date filter; pass null to clear.
  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    _invalidateCache();
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
    _invalidateCache();
    notifyListeners();

    try {
      final newSeance = await _service.createSeance(seance, token: token);
      _allSeances.insert(0, newSeance);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _invalidateCache();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
