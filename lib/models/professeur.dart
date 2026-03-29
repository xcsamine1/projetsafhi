/// Model representing a professor (Professeur).
class Professeur {
  final int idProf;
  final String nom;
  final String prenom;
  final String email;

  const Professeur({
    required this.idProf,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  String get fullName => '$prenom $nom';

  factory Professeur.fromJson(Map<String, dynamic> json) {
    return Professeur(
      idProf: json['id_prof'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_prof': idProf,
        'nom': nom,
        'prenom': prenom,
        'email': email,
      };
}
