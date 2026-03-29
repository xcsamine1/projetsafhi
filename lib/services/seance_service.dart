import '../config/app_config.dart';
import '../config/constants.dart';
import '../data/dummy_data.dart';
import '../models/seance.dart';
import '../models/metadata.dart';
import 'api_service.dart';

/// Service for session (Séance) CRUD operations.
class SeanceService {
  final ApiService _api;

  SeanceService(this._api);

  /// Fetch all sessions for a professor.
  /// If [AppConfig.useDummyData] is true, returns mock data.
  Future<List<Seance>> getSeances({String? token}) async {
    if (AppConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 600)); // simulate delay
      return DummyData.seances;
    }

    final data = await _api.get(ApiEndpoints.seances, token: token);
    return (data as List)
        .map((e) => Seance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Filter sessions by professor id and optional date.
  List<Seance> filterSeances(
    List<Seance> all, {
    int? profId,
    DateTime? date,
  }) {
    return all.where((s) {
      final profMatch = profId == null || s.idProf == profId;
      final dateMatch = date == null ||
          (s.dateSeance.year == date.year &&
              s.dateSeance.month == date.month &&
              s.dateSeance.day == date.day);
      return profMatch && dateMatch;
    }).toList();
  }

  /// Fetches options for creating a Seance.
  Future<SeanceMetadata?> fetchMetadata({String? token}) async {
    if (AppConfig.useDummyData) return null;
    final data = await _api.get(ApiEndpoints.seancesMetadata, token: token);
    if (data == null) return null;
    return SeanceMetadata.fromJson(data);
  }

  /// Creates a requested Seance remotely.
  Future<Seance> createSeance(Seance seance, {String? token}) async {
    if (AppConfig.useDummyData) return seance; // Mock return
    final response = await _api.post(
      ApiEndpoints.seances,
      seance.toJson(),
      token: token,
    );
    // Returns the ID assigned by MySQL, construct a new assigned object
    return Seance(
      idSeance: response['id_seance'],
      dateSeance: seance.dateSeance,
      heureDebut: seance.heureDebut,
      heureFin: seance.heureFin,
      idProf: seance.idProf,
      idModule: seance.idModule,
      idFiliere: seance.idFiliere,
      nomModule: seance.nomModule,
      nomFiliere: seance.nomFiliere,
      nomProf: seance.nomProf,
    );
  }
}

