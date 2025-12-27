/// Modèle pour la table 'messages'
class Message {
  final String id;
  final String destinataireId;
  final String?
  expediteurId; // Nullable pour les messages de visiteurs non inscrits
  final String nom;
  final String prenom;
  final String email;
  final String logementId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? destinataireNom;
  final String? destinatairePrenom;
  final String? expediteurNom;
  final String? expediteurPrenom;
  final String? logementTitre;

  Message({
    required this.id,
    required this.destinataireId,
    this.expediteurId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.logementId,
    required this.createdAt,
    this.updatedAt,
    this.destinataireNom,
    this.destinatairePrenom,
    this.expediteurNom,
    this.expediteurPrenom,
    this.logementTitre,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      destinataireId: json['destinataire_id'].toString(),
      expediteurId: json['expediteur_id']?.toString(),
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      logementId: json['logement_id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      destinataireNom: json['destinataire']?['nom'] as String?,
      destinatairePrenom: json['destinataire']?['prenom'] as String?,
      expediteurNom: json['expediteur']?['nom'] as String?,
      expediteurPrenom: json['expediteur']?['prenom'] as String?,
      logementTitre: json['logement']?['titre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinataire_id': destinataireId,
      'expediteur_id': expediteurId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'logement_id': logementId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get senderFullName => '$prenom $nom';

  String get destinataireFullName =>
      destinatairePrenom != null && destinataireNom != null
      ? '$destinatairePrenom $destinataireNom'
      : 'Destinataire';

  String get expediteurFullName =>
      expediteurPrenom != null && expediteurNom != null
      ? '$expediteurPrenom $expediteurNom'
      : senderFullName;

  Message copyWith({
    String? id,
    String? destinataireId,
    String? expediteurId,
    String? nom,
    String? prenom,
    String? email,
    String? logementId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? destinataireNom,
    String? destinatairePrenom,
    String? expediteurNom,
    String? expediteurPrenom,
    String? logementTitre,
  }) {
    return Message(
      id: id ?? this.id,
      destinataireId: destinataireId ?? this.destinataireId,
      expediteurId: expediteurId ?? this.expediteurId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      logementId: logementId ?? this.logementId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      destinataireNom: destinataireNom ?? this.destinataireNom,
      destinatairePrenom: destinatairePrenom ?? this.destinatairePrenom,
      expediteurNom: expediteurNom ?? this.expediteurNom,
      expediteurPrenom: expediteurPrenom ?? this.expediteurPrenom,
      logementTitre: logementTitre ?? this.logementTitre,
    );
  }
}
