/// Modèle pour la table 'projets' (projets sociaux)
class Projet {
  final String id;
  final String titre;
  final String description;
  final DateTime dateDebut;
  final double pourcentageContribution;
  final int categorieId;
  final String? categorieLibelle; // Depuis la jointure
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Statistiques
  final double? montantTotal;
  final int? nbContributions;

  Projet({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDebut,
    required this.pourcentageContribution,
    required this.categorieId,
    this.categorieLibelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
    this.montantTotal,
    this.nbContributions,
  });

  factory Projet.fromJson(Map<String, dynamic> json) {
    return Projet(
      id: (json['id'] ?? '').toString(),
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'] as String)
          : DateTime.now(),
      pourcentageContribution:
          (json['pourcentage_contribution'] as num?)?.toDouble() ?? 0.0,
      categorieId: json['categorie_id'] as int? ?? 0,
      categorieLibelle: json['categorie']?['libelle'] as String?,
      actif: json['actif'] as String? ?? 'OUI',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      montantTotal: (json['montant_total'] as num?)?.toDouble(),
      nbContributions: json['nb_contributions'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'pourcentage_contribution': pourcentageContribution,
      'categorie_id': categorieId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Projet copyWith({
    String? id,
    String? titre,
    String? description,
    DateTime? dateDebut,
    double? pourcentageContribution,
    int? categorieId,
    String? categorieLibelle,
    String? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? montantTotal,
    int? nbContributions,
  }) {
    return Projet(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      dateDebut: dateDebut ?? this.dateDebut,
      pourcentageContribution:
          pourcentageContribution ?? this.pourcentageContribution,
      categorieId: categorieId ?? this.categorieId,
      categorieLibelle: categorieLibelle ?? this.categorieLibelle,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      montantTotal: montantTotal ?? this.montantTotal,
      nbContributions: nbContributions ?? this.nbContributions,
    );
  }
}

/// Modèle pour la table 'contributions'
class Contribution {
  final String id;
  final String projetId;
  final String reservationId;
  final double montantContribue;
  final DateTime dateContribue;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? projetTitre;
  final String? userName;

  Contribution({
    required this.id,
    required this.projetId,
    required this.reservationId,
    required this.montantContribue,
    required this.dateContribue,
    required this.createdAt,
    this.updatedAt,
    this.projetTitre,
    this.userName,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'].toString(),
      projetId: json['projet_id'].toString(),
      reservationId: json['reservation_id'].toString(),
      montantContribue: (json['montant_contribue'] as num).toDouble(),
      dateContribue: DateTime.parse(json['date_contribue'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      projetTitre: json['projet']?['titre'] as String?,
      userName: json['reservation']?['user']?['prenom'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projet_id': projetId,
      'reservation_id': reservationId,
      'montant_contribue': montantContribue,
      'date_contribue': dateContribue.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'categories'
class Categorie {
  final String id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Categorie({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
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
