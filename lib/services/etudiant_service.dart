import '../config/app_config.dart';
import '../config/constants.dart';
import '../data/dummy_data.dart';
import '../models/etudiant.dart';
import 'api_service.dart';

/// Service for student (Étudiant) queries.
class EtudiantService {
  final ApiService _api;

  EtudiantService(this._api);

  /// Fetch all students in a given filière.
  Future<List<Etudiant>> getByFiliere(int filiereId, {String? token}) async {
    if (AppConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return DummyData.etudiants
          .where((e) => e.idFiliere == filiereId)
          .toList();
    }

    final data = await _api.get(
      ApiEndpoints.etudiantsByFiliere(filiereId),
      token: token,
    );
    return (data as List)
        .map((e) => Etudiant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a brand new Filiere remotely.
  Future<void> createFiliere(String nomFiliere, {String? token}) async {
    if (AppConfig.useDummyData) return;
    await _api.post(
      ApiEndpoints.filieres,
      {'nom_filiere': nomFiliere},
      token: token,
    );
  }

  /// Create a brand new Etudiant remotely.
  Future<void> createEtudiant(
      String nom, String prenom, int idFiliere, {String? token}) async {
    if (AppConfig.useDummyData) return;
    await _api.post(
      ApiEndpoints.etudiants,
      {'nom': nom, 'prenom': prenom, 'id_filiere': idFiliere},
      token: token,
    );
  }
}

