/// Modèle pour les rôles utilisateur
class Role {
  final int id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Role({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      libelle: json['libelle'] as String,
      actif: json['actif'] as String? ?? 'OUI',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Role copyWith({
    int? id,
    String? libelle,
    String? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      libelle: libelle ?? this.libelle,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
