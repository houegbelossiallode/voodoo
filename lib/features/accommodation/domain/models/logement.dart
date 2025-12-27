/// Modèle pour la table 'logements' (hébergements)
class Logement {
  final String id;
  final String titre;
  final String description;
  final String adresse;
  final int paysId;
  final String? paysLibelle; // Depuis la jointure
  final double prixParNuit;
  final int nbChambre;
  final int nbVoyageurMax;
  final int typeLogementId;
  final String? typeLogementLibelle; // Depuis la jointure
  final String userId;
  final String? userNom; // Depuis la jointure
  final String? userPrenom; // Depuis la jointure
  final String? userPhoto; // Depuis la jointure
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final List<Photo>? photos;
  final List<Equipement>? equipements;
  final List<Divinite>? divinites;
  final List<Rituel>? rituels;
  final List<PointFort>? pointForts;
  final double? rating;
  final int? reviewCount;

  Logement({
    required this.id,
    required this.titre,
    required this.description,
    required this.adresse,
    required this.paysId,
    this.paysLibelle,
    required this.prixParNuit,
    required this.nbChambre,
    required this.nbVoyageurMax,
    required this.typeLogementId,
    this.typeLogementLibelle,
    required this.userId,
    this.userNom,
    this.userPrenom,
    this.userPhoto,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
    this.photos,
    this.equipements,
    this.divinites,
    this.rituels,
    this.pointForts,
    this.rating,
    this.reviewCount,
  });

  factory Logement.fromJson(Map<String, dynamic> json) {
    return Logement(
      id: json['id'].toString(),
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      adresse: json['adresse'] as String,
      paysId: json['pays_id'] as int,
      paysLibelle: json['pays']?['libelle'] as String?,
      prixParNuit: (json['prix_par_nuit'] as num).toDouble(),
      nbChambre: json['nb_chambre'] as int,
      nbVoyageurMax: json['nb_voyageur_max'] as int,
      typeLogementId: json['type_logement_id'] as int,
      typeLogementLibelle: json['type_logement']?['libelle'] as String?,
      userId: json['user_id'].toString(),
      userNom: json['user']?['nom'] as String?,
      userPrenom: json['user']?['prenom'] as String?,
      userPhoto: json['user']?['photo'] as String?,
      actif: json['actif'] as String? ?? 'OUI',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List<dynamic>)
                .map((e) => Photo.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      equipements: json['equipements'] != null
          ? (json['equipements'] as List<dynamic>)
                .map((e) => Equipement.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      divinites: json['divinites'] != null
          ? (json['divinites'] as List<dynamic>)
                .map((e) => Divinite.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      rituels: json['rituels'] != null
          ? (json['rituels'] as List<dynamic>)
                .map((e) => Rituel.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      pointForts: json['pointforts'] != null
          ? (json['pointforts'] as List<dynamic>)
                .map((e) => PointFort.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'adresse': adresse,
      'pays_id': paysId,
      'prix_par_nuit': prixParNuit,
      'nb_chambre': nbChambre,
      'nb_voyageur_max': nbVoyageurMax,
      'type_logement_id': typeLogementId,
      'user_id': userId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get hostFullName =>
      userPrenom != null && userNom != null ? '$userPrenom $userNom' : 'Hôte';

  Logement copyWith({
    String? id,
    String? titre,
    String? description,
    String? adresse,
    int? paysId,
    String? paysLibelle,
    double? prixParNuit,
    int? nbChambre,
    int? nbVoyageurMax,
    int? typeLogementId,
    String? typeLogementLibelle,
    String? userId,
    String? userNom,
    String? userPrenom,
    String? userPhoto,
    String? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Photo>? photos,
    List<Equipement>? equipements,
    List<Divinite>? divinites,
    List<Rituel>? rituels,
    List<PointFort>? pointForts,
    double? rating,
    int? reviewCount,
  }) {
    return Logement(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      paysId: paysId ?? this.paysId,
      paysLibelle: paysLibelle ?? this.paysLibelle,
      prixParNuit: prixParNuit ?? this.prixParNuit,
      nbChambre: nbChambre ?? this.nbChambre,
      nbVoyageurMax: nbVoyageurMax ?? this.nbVoyageurMax,
      typeLogementId: typeLogementId ?? this.typeLogementId,
      typeLogementLibelle: typeLogementLibelle ?? this.typeLogementLibelle,
      userId: userId ?? this.userId,
      userNom: userNom ?? this.userNom,
      userPrenom: userPrenom ?? this.userPrenom,
      userPhoto: userPhoto ?? this.userPhoto,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      equipements: equipements ?? this.equipements,
      divinites: divinites ?? this.divinites,
      rituels: rituels ?? this.rituels,
      pointForts: pointForts ?? this.pointForts,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

/// Modèle pour la table 'photos'
class Photo {
  final String id;
  final String logementId;
  final String url;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Photo({
    required this.id,
    required this.logementId,
    required this.url,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'].toString(),
      logementId: json['logement_id'].toString(),
      url: json['url'] as String,
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
      'logement_id': logementId,
      'url': url,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'equipements'
class Equipement {
  final String id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Equipement({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Equipement.fromJson(Map<String, dynamic> json) {
    return Equipement(
      id: json['id'].toString(),
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
}

/// Modèle pour la table 'divinites'
class Divinite {
  final String id;
  final String nom;
  final String description;
  final String image;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Divinite({
    required this.id,
    required this.nom,
    required this.description,
    required this.image,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Divinite.fromJson(Map<String, dynamic> json) {
    return Divinite(
      id: json['id'].toString(),
      nom: json['nom'] as String,
      description: json['description'] as String? ?? '',
      image: json['image'] as String,
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
      'nom': nom,
      'description': description,
      'image': image,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'rituels'
class Rituel {
  final String id;
  final String titre;
  final String description;
  final String symbole;
  final int duree; // en minutes
  final String precautions;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Rituel({
    required this.id,
    required this.titre,
    required this.description,
    required this.symbole,
    required this.duree,
    required this.precautions,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Rituel.fromJson(Map<String, dynamic> json) {
    return Rituel(
      id: json['id'].toString(),
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      symbole: json['symbole'] as String,
      duree: json['duree'] as int,
      precautions: json['precautions'] as String? ?? '',
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
      'titre': titre,
      'description': description,
      'symbole': symbole,
      'duree': duree,
      'precautions': precautions,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'pointforts'
class PointFort {
  final String id;
  final String logementId;
  final String titre;
  final String description;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PointFort({
    required this.id,
    required this.logementId,
    required this.titre,
    required this.description,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory PointFort.fromJson(Map<String, dynamic> json) {
    return PointFort(
      id: json['id'].toString(),
      logementId: json['logement_id'].toString(),
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
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
      'logement_id': logementId,
      'titre': titre,
      'description': description,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
