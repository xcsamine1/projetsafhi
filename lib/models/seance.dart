/// Model representing a study session (Séance).
class Seance {
  final int idSeance;
  final DateTime dateSeance;
  final String heureDebut;
  final String heureFin;
  final int idProf;
  final int idModule;
  final int idFiliere;

  // Optionally populated by the API via joins / eager loading
  final String? nomModule;
  final String? nomFiliere;
  final String? nomProf;

  const Seance({
    required this.idSeance,
    required this.dateSeance,
    required this.heureDebut,
    required this.heureFin,
    required this.idProf,
    required this.idModule,
    required this.idFiliere,
    this.nomModule,
    this.nomFiliere,
    this.nomProf,
  });

  /// Returns true if this session is today.
  bool get isToday {
    final now = DateTime.now();
    return dateSeance.year == now.year &&
        dateSeance.month == now.month &&
        dateSeance.day == now.day;
  }

  factory Seance.fromJson(Map<String, dynamic> json) {
    return Seance(
      idSeance: json['id_seance'] as int,
      dateSeance: DateTime.parse(json['date_seance'] as String),
      heureDebut: json['heure_debut'] as String,
      heureFin: json['heure_fin'] as String,
      idProf: json['id_prof'] as int,
      idModule: json['id_module'] as int,
      idFiliere: json['id_filiere'] as int,
      nomModule: json['nom_module'] as String?,
      nomFiliere: json['nom_filiere'] as String?,
      nomProf: json['nom_prof'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_seance': idSeance,
        'date_seance': dateSeance.toIso8601String().split('T').first,
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
        'id_prof': idProf,
        'id_module': idModule,
        'id_filiere': idFiliere,
      };
}
