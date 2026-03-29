import '../config/constants.dart';

/// Model representing an attendance record (Présence).
class Presence {
  final int? idPresence; // null when creating new record
  final int idSeance;
  final int idEtudiant;
  final Statut statut;
  final String? commentaire;

  const Presence({
    this.idPresence,
    required this.idSeance,
    required this.idEtudiant,
    required this.statut,
    this.commentaire,
  });

  Presence copyWith({
    int? idPresence,
    int? idSeance,
    int? idEtudiant,
    Statut? statut,
    String? commentaire,
  }) {
    return Presence(
      idPresence: idPresence ?? this.idPresence,
      idSeance: idSeance ?? this.idSeance,
      idEtudiant: idEtudiant ?? this.idEtudiant,
      statut: statut ?? this.statut,
      commentaire: commentaire ?? this.commentaire,
    );
  }

  factory Presence.fromJson(Map<String, dynamic> json) {
    return Presence(
      idPresence: json['id_presence'] as int?,
      idSeance: json['id_seance'] as int,
      idEtudiant: json['id_etudiant'] as int,
      statut: StatutExtension.fromString(json['statut'] as String),
      commentaire: json['commentaire'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (idPresence != null) 'id_presence': idPresence,
        'id_seance': idSeance,
        'id_etudiant': idEtudiant,
        'statut': statut.apiValue,
        if (commentaire != null) 'commentaire': commentaire,
      };
}
