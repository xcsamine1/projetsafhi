import '../config/app_config.dart';
import '../config/constants.dart';
import '../data/dummy_data.dart';
import '../models/presence.dart';
import 'api_service.dart';

/// Service for attendance (Présence) CRUD operations.
class PresenceService {
  final ApiService _api;

  PresenceService(this._api);

  // ─── READ ─────────────────────────────────────────────────────────────────

  /// Fetch all attendance records for a session.
  Future<List<Presence>> getBySeance(int seanceId, {String? token}) async {
    if (AppConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return DummyData.presences
          .where((p) => p.idSeance == seanceId)
          .toList();
    }

    final data = await _api.get(
      ApiEndpoints.presenceBySeance(seanceId),
      token: token,
    );
    return (data as List)
        .map((e) => Presence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  /// Create a new attendance record.
  Future<Presence> create(Presence presence, {String? token}) async {
    if (AppConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final newId = DummyData.presences.length + 1;
      final saved = presence.copyWith(idPresence: newId);
      DummyData.presences.add(saved);
      return saved;
    }

    final data = await _api.post(
      ApiEndpoints.presence,
      presence.toJson(),
      token: token,
    );
    return Presence.fromJson(data as Map<String, dynamic>);
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  /// Update an existing attendance record.
  Future<Presence> update(Presence presence, {String? token}) async {
    assert(presence.idPresence != null, 'Cannot update a presence without id');

    if (AppConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final idx = DummyData.presences
          .indexWhere((p) => p.idPresence == presence.idPresence);
      if (idx != -1) DummyData.presences[idx] = presence;
      return presence;
    }

    final data = await _api.put(
      ApiEndpoints.presenceById(presence.idPresence!),
      presence.toJson(),
      token: token,
    );
    return Presence.fromJson(data as Map<String, dynamic>);
  }
}
