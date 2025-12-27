/// Modèle pour les photos des logements
class Photo {
  final int id;
  final int logementId;
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
      id: json['id'] as int,
      logementId: json['logement_id'] as int,
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

  Photo copyWith({
    int? id,
    int? logementId,
    String? url,
    String? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      logementId: logementId ?? this.logementId,
      url: url ?? this.url,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
