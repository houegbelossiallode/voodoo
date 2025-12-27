/// Modèle pour les divinités du Vodoun
class Divinite {
  final int id;
  final String nom;
  final String? description;
  final String? image;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Divinite({
    required this.id,
    required this.nom,
    this.description,
    this.image,
    required this.createdAt,
    this.updatedAt,
  });

  factory Divinite.fromJson(Map<String, dynamic> json) {
    return Divinite(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Divinite copyWith({
    int? id,
    String? nom,
    String? description,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Divinite(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
