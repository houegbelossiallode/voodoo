/// Modèle pour la table 'reservations'
class Reservation {
  final String id;
  final String logementId;
  final String userId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montant;
  final int nbNuits;
  final int nbVoyageurs;
  final String? modePaiement; // kkiapay, mtn, moov, etc.
  final String? reference; // Référence de transaction
  final String? projetId;
  final String statut; // pending, confirmed, cancelled, completed
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? logementTitre;
  final String? projetTitre;
  final List<Paiement>? paiements;

  Reservation({
    required this.id,
    required this.logementId,
    required this.userId,
    required this.dateDebut,
    required this.dateFin,
    required this.montant,
    required this.nbNuits,
    required this.nbVoyageurs,
    this.modePaiement,
    this.reference,
    this.projetId,
    required this.statut,
    required this.createdAt,
    this.updatedAt,
    this.logementTitre,
    this.projetTitre,
    this.paiements,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      logementId: json['logement_id'].toString(),
      userId: json['user_id'].toString(),
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      montant: (json['montant'] as num).toDouble(),
      nbNuits: json['nb_nuits'] as int,
      nbVoyageurs: json['nb_voyageurs'] as int,
      modePaiement: json['mode_paiement'] as String?,
      reference: json['reference'] as String?,
      projetId: json['projet_id']?.toString(),
      statut: json['statut'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      logementTitre: json['logement']?['titre'] as String?,
      projetTitre: json['projet']?['titre'] as String?,
      paiements: json['paiements'] != null
          ? (json['paiements'] as List<dynamic>)
                .map((e) => Paiement.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logement_id': logementId,
      'user_id': userId,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin.toIso8601String().split('T')[0],
      'montant': montant,
      'nb_nuits': nbNuits,
      'nb_voyageurs': nbVoyageurs,
      'mode_paiement': modePaiement,
      'reference': reference,
      'projet_id': projetId,
      'statut': statut,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Reservation copyWith({
    String? id,
    String? logementId,
    String? userId,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? montant,
    int? nbNuits,
    int? nbVoyageurs,
    String? modePaiement,
    String? reference,
    String? projetId,
    String? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logementTitre,
    String? projetTitre,
    List<Paiement>? paiements,
  }) {
    return Reservation(
      id: id ?? this.id,
      logementId: logementId ?? this.logementId,
      userId: userId ?? this.userId,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      montant: montant ?? this.montant,
      nbNuits: nbNuits ?? this.nbNuits,
      nbVoyageurs: nbVoyageurs ?? this.nbVoyageurs,
      modePaiement: modePaiement ?? this.modePaiement,
      reference: reference ?? this.reference,
      projetId: projetId ?? this.projetId,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logementTitre: logementTitre ?? this.logementTitre,
      projetTitre: projetTitre ?? this.projetTitre,
      paiements: paiements ?? this.paiements,
    );
  }
}

/// Modèle pour la table 'paiements'
class Paiement {
  final String id;
  final String reservationId;
  final double montant;
  final String devise;
  final String methode; // card, mtn, paypal
  final String statut; // pending, completed, failed, refunded
  final String reference;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Paiement({
    required this.id,
    required this.reservationId,
    required this.montant,
    required this.devise,
    required this.methode,
    required this.statut,
    required this.reference,
    required this.createdAt,
    this.updatedAt,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: json['id'].toString(),
      reservationId: json['reservation_id'].toString(),
      montant: (json['montant'] as num).toDouble(),
      devise: json['devise'] as String,
      methode: json['methode'] as String,
      statut: json['statut'] as String,
      reference: json['reference'] as String,
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
      'montant': montant,
      'devise': devise,
      'methode': methode,
      'statut': statut,
      'reference': reference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
