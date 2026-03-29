/// Model representing an educational track (Filière).
class Filiere {
  final int idFiliere;
  final String nomFiliere;

  const Filiere({required this.idFiliere, required this.nomFiliere});

  factory Filiere.fromJson(Map<String, dynamic> json) {
    return Filiere(
      idFiliere: json['id_filiere'] as int,
      nomFiliere: json['nom_filiere'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_filiere': idFiliere,
        'nom_filiere': nomFiliere,
      };
}
