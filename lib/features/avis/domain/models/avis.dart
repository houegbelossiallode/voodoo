/// Modèle pour la table 'avis' (reviews/commentaires)
class Avis {
  final String id;
  final int notes; // Note de 1 à 5
  final String commentaire;
  final String logementId;
  final String userId;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? userName;
  final String? userPhoto;
  final String? logementTitre;

  Avis({
    required this.id,
    required this.notes,
    required this.commentaire,
    required this.logementId,
    required this.userId,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userPhoto,
    this.logementTitre,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'].toString(),
      notes: json['notes'] as int,
      commentaire: json['commentaire'] as String? ?? '',
      logementId: json['logement_id'].toString(),
      userId: json['user_id'].toString(),
      actif: json['actif'] as String? ?? 'OUI',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: json['user'] != null
          ? '${json['user']['prenom']} ${json['user']['nom']}'
          : null,
      userPhoto: json['user']?['photo'] as String?,
      logementTitre: json['logement']?['titre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notes': notes,
      'commentaire': commentaire,
      'logement_id': logementId,
      'user_id': userId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Avis copyWith({
    String? id,
    int? notes,
    String? commentaire,
    String? logementId,
    String? userId,
    String? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userPhoto,
    String? logementTitre,
  }) {
    return Avis(
      id: id ?? this.id,
      notes: notes ?? this.notes,
      commentaire: commentaire ?? this.commentaire,
      logementId: logementId ?? this.logementId,
      userId: userId ?? this.userId,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      logementTitre: logementTitre ?? this.logementTitre,
    );
  }
}
