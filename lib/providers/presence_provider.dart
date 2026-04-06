import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/etudiant.dart';
import '../models/presence.dart';
import '../services/etudiant_service.dart';
import '../services/presence_service.dart';

/// Manages attendance state for a single session.
class PresenceProvider extends ChangeNotifier {
  final EtudiantService _etudiantService;
  final PresenceService _presenceService;

  PresenceProvider(this._etudiantService, this._presenceService);

  // ─── State ────────────────────────────────────────────────────────────────
  List<Etudiant> _students = [];
  /// Map from student id → current Presence record (may be null if not yet recorded).
  final Map<int, Presence?> _presenceMap = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _submitted = false;
  int? _currentSeanceId;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Etudiant> get students => _students;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get submitted => _submitted;

  /// Get current statut for a student (defaults to Absent).
  Statut getStatut(int studentId) =>
      _presenceMap[studentId]?.statut ?? Statut.absent;

  /// Whether a presence record already exists for this student.
  bool hasRecord(int studentId) => _presenceMap[studentId]?.idPresence != null;

  /// Get current commentaire for a student (null if none).
  String? getCommentaire(int studentId) => _presenceMap[studentId]?.commentaire;

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Load students for the filière and existing records for the session.
  Future<void> loadForSession({
    required int seanceId,
    required int filiereId,
    String? token,
  }) async {
    _currentSeanceId = seanceId;
    _submitted = false;
    _isLoading = true;
    _error = null;
    _presenceMap.clear();
    notifyListeners();

    try {
      // Fetch students and existing presence records in parallel
      final results = await Future.wait([
        _etudiantService.getByFiliere(filiereId, token: token),
        _presenceService.getBySeance(seanceId, token: token),
      ]);

      _students = results[0] as List<Etudiant>;
      final presences = results[1] as List<Presence>;

      // Seed map with defaults (absent) for all students
      for (final s in _students) {
        _presenceMap[s.idEtudiant] = null;
      }
      // Override with existing records
      for (final p in presences) {
        _presenceMap[p.idEtudiant] = p;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a student's statut locally (no API call yet).
  void updateStatut(int studentId, Statut statut) {
    final existing = _presenceMap[studentId];
    if (existing != null) {
      _presenceMap[studentId] = existing.copyWith(statut: statut);
    } else {
      _presenceMap[studentId] = Presence(
        idSeance: _currentSeanceId!,
        idEtudiant: studentId,
        statut: statut,
      );
    }
    notifyListeners();
  }

  /// Update a student's commentaire locally.
  void updateCommentaire(int studentId, String commentaire) {
    final existing = _presenceMap[studentId];
    if (existing != null) {
      _presenceMap[studentId] = existing.copyWith(commentaire: commentaire);
    }
    notifyListeners();
  }

  /// Submit all attendance records in parallel (create new or update existing).
  Future<bool> submitAll({String? token}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Collect all pending records (skip null / absent-by-default entries)
      final entries = _presenceMap.entries
          .where((e) => e.value != null)
          .toList();

      // Fire all API calls concurrently
      final futures = entries.map((e) {
        final p = e.value!;
        return p.idPresence != null
            ? _presenceService.update(p, token: token)
            : _presenceService.create(p, token: token);
      });

      final results = await Future.wait(futures);

      // Write results back into the map atomically
      for (var i = 0; i < entries.length; i++) {
        _presenceMap[entries[i].key] = results[i];
      }

      _submitted = true;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  /// Number of students with a given statut.
  int countByStatut(Statut statut) =>
      _presenceMap.values.where((p) => p?.statut == statut).length;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
