/// Modèle pour les équipements
class Equipement {
  final int id;
  final String libelle;
  final String? description;
  final String? icone;

  Equipement({
    required this.id,
    required this.libelle,
    this.description,
    this.icone,
  });

  factory Equipement.fromJson(Map<String, dynamic> json) {
    return Equipement(
      id: json['id'] as int,
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
      icone: json['icone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'description': description,
      'icone': icone,
    };
  }
}
