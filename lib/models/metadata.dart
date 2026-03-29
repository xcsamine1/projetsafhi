/// Model representing a Filière (Program/Major).
class Filiere {
  final int idFiliere;
  final String nomFiliere;

  const Filiere({
    required this.idFiliere,
    required this.nomFiliere,
  });

  factory Filiere.fromJson(Map<String, dynamic> json) {
    return Filiere(
      idFiliere: json['id_filiere'] as int,
      nomFiliere: json['nom_filiere'] as String,
    );
  }
}

/// Model representing a Module (Course snippet).
class Module {
  final int idModule;
  final String nomModule;

  const Module({
    required this.idModule,
    required this.nomModule,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      idModule: json['id_module'] as int,
      nomModule: json['nom_module'] as String,
    );
  }
}

/// A wrapper for the metadata retrieved at once.
class SeanceMetadata {
  final List<Module> modules;
  final List<Filiere> filieres;

  const SeanceMetadata({
    required this.modules,
    required this.filieres,
  });

  factory SeanceMetadata.fromJson(Map<String, dynamic> json) {
    return SeanceMetadata(
      modules: (json['modules'] as List)
          .map((e) => Module.fromJson(e as Map<String, dynamic>))
          .toList(),
      filieres: (json['filieres'] as List)
          .map((e) => Filiere.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
