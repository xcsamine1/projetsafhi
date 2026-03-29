/// Model representing an educational module.
class Module {
  final int idModule;
  final String nomModule;

  const Module({required this.idModule, required this.nomModule});

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      idModule: json['id_module'] as int,
      nomModule: json['nom_module'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_module': idModule,
        'nom_module': nomModule,
      };
}
