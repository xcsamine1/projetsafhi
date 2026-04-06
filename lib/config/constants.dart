// Shared constants used across the app.

// ─── Statut Enum ─────────────────────────────────────────────────────────────

/// Represents the attendance status of a student in a session.
enum Statut { present, absent, retard, justifie }

extension StatutExtension on Statut {
  /// Human-readable label
  String get label {
    switch (this) {
      case Statut.present:
        return 'Présent';
      case Statut.absent:
        return 'Absent';
      case Statut.retard:
        return 'Retard';
      case Statut.justifie:
        return 'Justifié';
    }
  }

  /// Value sent to / received from the API
  String get apiValue {
    switch (this) {
      case Statut.present:
        return 'Present';
      case Statut.absent:
        return 'Absent';
      case Statut.retard:
        return 'Retard';
      case Statut.justifie:
        return 'Justifie';
    }
  }

  /// Parse from API string
  static Statut fromString(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return Statut.present;
      case 'absent':
        return Statut.absent;
      case 'retard':
        return Statut.retard;
      case 'justifie':
        return Statut.justifie;
      default:
        return Statut.absent;
    }
  }
}

// ─── API Endpoints ────────────────────────────────────────────────────────────

class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String seances = '/seances';
  static const String seancesMetadata = '/seances/metadata';
  static String etudiantsByFiliere(int filiereId) =>
      '/etudiants/byFiliere/$filiereId';
  static const String etudiants = '/etudiants';
  static String etudiantById(int id) => '/etudiants/$id';
  static const String filieres = '/filieres';
  static String filiereById(int id) => '/filieres/$id';
  static String presenceBySeance(int seanceId) => '/presence/$seanceId';
  static const String presence = '/presence';
  static String presenceById(int id) => '/presence/$id';
}

// ─── Storage Keys ─────────────────────────────────────────────────────────────

class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String professorId = 'professor_id';
  static const String professorName = 'professor_name';
  static const String professorEmail = 'professor_email';
  static const String baseUrl = 'base_url';
}
