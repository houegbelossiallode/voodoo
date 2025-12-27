/// Modèle pour un rituel vaudou
class Ritual {
  final int id;
  final String titre;
  final String description;
  final String? symbole; // Icône ou symbole représentant le rituel
  final String? photo;
  final String? signification; // Signification spirituelle du rituel
  final String? deroulement; // Description du déroulement du rituel
  final int? duree; // Durée en minutes
  final String? precautions; // Précautions à prendre
  final bool disponible;
  final double? prix; // Prix du rituel (optionnel)
  final int? diviniteId; // Divinité associée au rituel
  final String? diviniteNom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ritual({
    required this.id,
    required this.titre,
    required this.description,
    this.symbole,
    this.photo,
    this.signification,
    this.deroulement,
    this.duree,
    this.precautions,
    required this.disponible,
    this.prix,
    this.diviniteId,
    this.diviniteNom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ritual.fromJson(Map<String, dynamic> json) {
    return Ritual(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String,
      symbole: json['symbole'] as String?,
      photo: json['photo'] as String?,
      signification: json['signification'] as String?,
      deroulement: json['deroulement'] as String?,
      duree: json['duree'] as int?,
      precautions: json['precautions'] as String?,
      disponible:
          json['disponible'] == true ||
          json['disponible'] == 'OUI' ||
          json['disponible'] == 1,
      prix: json['prix'] != null ? (json['prix'] as num).toDouble() : null,
      diviniteId: json['divinite_id'] as int?,
      diviniteNom: json['divinite_nom'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'symbole': symbole,
      'photo': photo,
      'signification': signification,
      'deroulement': deroulement,
      'duree': duree,
      'precautions': precautions,
      'disponible': disponible,
      'prix': prix,
      'divinite_id': diviniteId,
      'divinite_nom': diviniteNom,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Retourne la durée formatée (ex: "1h 30min")
  String get dureeFormatee {
    if (duree == null) return 'Non spécifiée';

    final heures = duree! ~/ 60;
    final minutes = duree! % 60;

    if (heures > 0 && minutes > 0) {
      return '${heures}h ${minutes}min';
    } else if (heures > 0) {
      return '${heures}h';
    } else {
      return '${minutes}min';
    }
  }

  /// Retourne le prix formaté
  String get prixFormate {
    if (prix == null) return 'Gratuit';
    return '${prix!.toStringAsFixed(0)} XOF';
  }

  Ritual copyWith({
    int? id,
    String? titre,
    String? description,
    String? symbole,
    String? photo,
    String? signification,
    String? deroulement,
    int? duree,
    String? precautions,
    bool? disponible,
    double? prix,
    int? diviniteId,
    String? diviniteNom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ritual(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      symbole: symbole ?? this.symbole,
      photo: photo ?? this.photo,
      signification: signification ?? this.signification,
      deroulement: deroulement ?? this.deroulement,
      duree: duree ?? this.duree,
      precautions: precautions ?? this.precautions,
      disponible: disponible ?? this.disponible,
      prix: prix ?? this.prix,
      diviniteId: diviniteId ?? this.diviniteId,
      diviniteNom: diviniteNom ?? this.diviniteNom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
