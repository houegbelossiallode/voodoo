import 'package:vodou/features/home/domain/models/photo.dart';

/// Modèle pour les logements
class Logement {
  final int id;
  final String titre;
  final String? description;
  final String? adresse;
  final double prixParNuit;
  final int? nbChambre;
  final int? nbVoyageurMax;
  final int? typeLogementId;
  final int userId;
  final bool disponibilite; // Disponibilité générale du logement
  final int? quartierId; // ID du quartier
  final double? latitude; // Latitude pour Google Maps
  final double? longitude; // Longitude pour Google Maps
  final String actif;
  final List<Photo> photos; // Liste des photos du logement
  final DateTime createdAt;
  final DateTime? updatedAt;

  Logement({
    required this.id,
    required this.titre,
    this.description,
    required this.prixParNuit,
    this.adresse,
    this.nbChambre,
    this.nbVoyageurMax,
    this.typeLogementId,
    required this.userId,
    this.disponibilite = true,
    this.quartierId,
    this.latitude,
    this.longitude,
    this.actif = 'OUI',
    this.photos = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Logement.fromJson(Map<String, dynamic> json) {
    // Parse les photos si elles sont incluses dans la réponse
    List<Photo> photosList = [];
    if (json['photos'] != null) {
      photosList = (json['photos'] as List)
          .map((photoJson) => Photo.fromJson(photoJson as Map<String, dynamic>))
          .toList();
    }

    return Logement(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      prixParNuit: (json['prix_par_nuit'] as num).toDouble(),
      adresse: json['adresse'] as String?,
      nbChambre: json['nb_chambre'] as int?,
      nbVoyageurMax: json['nb_voyageur_max'] as int?,
      typeLogementId: json['type_logement_id'] as int?,
      userId: json['user_id'] as int,
      disponibilite: json['disponibilite'] as bool? ?? true,
      quartierId: json['quartier_id'] as int?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      actif: json['actif'] as String? ?? 'OUI',
      photos: photosList,
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
      'prix_par_nuit': prixParNuit,
      'adresse': adresse,
      'nb_chambre': nbChambre,
      'nb_voyageur_max': nbVoyageurMax,
      'type_logement_id': typeLogementId,
      'user_id': userId,
      'disponibilite': disponibilite,
      'quartier_id': quartierId,
      'latitude': latitude,
      'longitude': longitude,
      'actif': actif,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Logement copyWith({
    int? id,
    String? titre,
    String? description,
    double? prixParNuit,
    String? adresse,
    int? nbChambre,
    int? nbVoyageurMax,
    int? typeLogementId,
    int? userId,
    bool? disponibilite,
    int? quartierId,
    double? latitude,
    double? longitude,
    String? actif,
    List<Photo>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Logement(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      prixParNuit: prixParNuit ?? this.prixParNuit,
      adresse: adresse ?? this.adresse,
      nbChambre: nbChambre ?? this.nbChambre,
      nbVoyageurMax: nbVoyageurMax ?? this.nbVoyageurMax,
      typeLogementId: typeLogementId ?? this.typeLogementId,
      userId: userId ?? this.userId,
      disponibilite: disponibilite ?? this.disponibilite,
      quartierId: quartierId ?? this.quartierId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      actif: actif ?? this.actif,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne la première photo active ou null
  String? get firstPhotoUrl {
    final activePhotos = photos.where((p) => p.actif == 'OUI').toList();
    return activePhotos.isNotEmpty ? activePhotos.first.url : null;
  }

  /// Retourne toutes les photos actives
  List<Photo> get activePhotos {
    return photos.where((p) => p.actif == 'OUI').toList();
  }
}
