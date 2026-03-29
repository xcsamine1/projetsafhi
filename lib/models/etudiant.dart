/// Model representing a student (Etudiant).
class Etudiant {
  final int idEtudiant;
  final String nom;
  final String prenom;
  final int idFiliere;

  const Etudiant({
    required this.idEtudiant,
    required this.nom,
    required this.prenom,
    required this.idFiliere,
  });

  /// Full display name
  String get fullName => '$prenom $nom';

  factory Etudiant.fromJson(Map<String, dynamic> json) {
    return Etudiant(
      idEtudiant: json['id_etudiant'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      idFiliere: json['id_filiere'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_etudiant': idEtudiant,
        'nom': nom,
        'prenom': prenom,
        'id_filiere': idFiliere,
      };
}
