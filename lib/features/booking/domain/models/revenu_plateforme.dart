/// Modèle pour la table 'revenu_plateformes'
class RevenuPlateforme {
  final int id;
  final int reservationId;
  final double commission;
  final double partProjet;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RevenuPlateforme({
    required this.id,
    required this.reservationId,
    required this.commission,
    required this.partProjet,
    required this.createdAt,
    this.updatedAt,
  });

  factory RevenuPlateforme.fromJson(Map<String, dynamic> json) {
    return RevenuPlateforme(
      id: json['id'] as int,
      reservationId: json['reservation_id'] as int,
      commission: (json['commission'] as num).toDouble(),
      partProjet: (json['part_projet'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'commission': commission,
      'part_projet': partProjet,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'comptes'
class Compte {
  final int id;
  final int userId;
  final double solde;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Compte({
    required this.id,
    required this.userId,
    required this.solde,
    required this.createdAt,
    this.updatedAt,
  });

  factory Compte.fromJson(Map<String, dynamic> json) {
    return Compte(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      solde: (json['solde'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'solde': solde,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Compte copyWith({
    int? id,
    int? userId,
    double? solde,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Compte(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      solde: solde ?? this.solde,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modèle pour la table 'transactions'
class Transaction {
  final int id;
  final double montant;
  final String type; // credit, debit
  final int compteId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.montant,
    required this.type,
    required this.compteId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      montant: (json['montant'] as num).toDouble(),
      type: json['type'] as String,
      compteId: json['compte_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'montant': montant,
      'type': type,
      'compte_id': compteId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modèle pour la table 'constances'
class Constance {
  final int id;
  final String param;
  final double val;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Constance({
    required this.id,
    required this.param,
    required this.val,
    required this.createdAt,
    this.updatedAt,
  });

  factory Constance.fromJson(Map<String, dynamic> json) {
    return Constance(
      id: json['id'] as int,
      param: json['param'] as String,
      val: (json['val'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'param': param,
      'val': val,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
