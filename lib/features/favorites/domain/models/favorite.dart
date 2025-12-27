/// Modèle pour la table 'favorites' (listes de favoris)
class Favorite {
  final int id;
  final String userId;
  final String libelle;
  final String lienPartage;
  final bool estPartage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final List<FavoriLogement>? logements;
  final int? nbLogements;

  Favorite({
    required this.id,
    required this.userId,
    required this.libelle,
    required this.lienPartage,
    required this.estPartage,
    required this.createdAt,
    this.updatedAt,
    this.logements,
    this.nbLogements,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as int,
      userId: json['user_id'].toString(),
      libelle: json['libelle'] as String,
      lienPartage: json['lien_partage'] as String? ?? '',
      estPartage: json['est_partage'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      logements: json['logements'] != null
          ? (json['logements'] as List<dynamic>)
                .map((e) => FavoriLogement.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      nbLogements: json['nb_logements'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'libelle': libelle,
      'lien_partage': lienPartage,
      'est_partage': estPartage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Favorite copyWith({
    int? id,
    String? userId,
    String? libelle,
    String? lienPartage,
    bool? estPartage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FavoriLogement>? logements,
    int? nbLogements,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      libelle: libelle ?? this.libelle,
      lienPartage: lienPartage ?? this.lienPartage,
      estPartage: estPartage ?? this.estPartage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logements: logements ?? this.logements,
      nbLogements: nbLogements ?? this.nbLogements,
    );
  }
}

/// Modèle pour la table 'favori_logements' (table pivot)
class FavoriLogement {
  final String id;
  final String logementId;
  final String favoriteId;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? logementTitre;
  final String? logementPhoto;
  final double? logementPrix;

  FavoriLogement({
    required this.id,
    required this.logementId,
    required this.favoriteId,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
    this.logementTitre,
    this.logementPhoto,
    this.logementPrix,
  });

  factory FavoriLogement.fromJson(Map<String, dynamic> json) {
    return FavoriLogement(
      id: json['id'].toString(),
      logementId: json['logement_id'].toString(),
      favoriteId: json['favorite_id'].toString(),
      actif: json['actif'] as String? ?? 'OUI',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      logementTitre: json['logement']?['titre'] as String?,
      logementPhoto: json['logement']?['photos']?[0]?['url'] as String?,
      logementPrix: (json['logement']?['prix_par_nuit'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logement_id': logementId,
      'favorite_id': favoriteId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
