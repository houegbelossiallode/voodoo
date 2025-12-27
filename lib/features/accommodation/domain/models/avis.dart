/// Modèle pour les avis et évaluations
class Avis {
  final int id;
  final int logementId;
  final int userId;
  final String userName;
  final String? userPhoto;
  final double note;
  final String? commentaire;
  final DateTime dateCreation;
  final String? reponseHote;
  final DateTime? dateReponse;

  Avis({
    required this.id,
    required this.logementId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.note,
    this.commentaire,
    required this.dateCreation,
    this.reponseHote,
    this.dateReponse,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'] as int,
      logementId: json['logement_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? 'Utilisateur',
      userPhoto: json['user_photo'] as String?,
      note: (json['note'] as num).toDouble(),
      commentaire: json['commentaire'] as String?,
      dateCreation: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      reponseHote: json['reponse_hote'] as String?,
      dateReponse: json['date_reponse'] != null
          ? DateTime.parse(json['date_reponse'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logement_id': logementId,
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'note': note,
      'commentaire': commentaire,
      'date_creation': dateCreation.toIso8601String(),
      'reponse_hote': reponseHote,
      'date_reponse': dateReponse?.toIso8601String(),
    };
  }
}

/// Statistiques des avis pour un logement
class AvisStats {
  final double moyenneNote;
  final int totalAvis;
  final Map<int, int> repartitionNotes; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  AvisStats({
    required this.moyenneNote,
    required this.totalAvis,
    required this.repartitionNotes,
  });

  factory AvisStats.fromJson(Map<String, dynamic> json) {
    return AvisStats(
      moyenneNote: (json['moyenne_note'] as num?)?.toDouble() ?? 0.0,
      totalAvis: json['total_avis'] as int? ?? 0,
      repartitionNotes: Map<int, int>.from(json['repartition_notes'] ?? {}),
    );
  }
}
