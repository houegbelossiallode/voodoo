/// Informations sur l'hôte
class HostInfo {
  final int id;
  final String nom;
  final String prenom;
  final String? photo;
  final String? bio;
  final List<String> langues;
  final List<String> passions;
  final DateTime? dateInscription;
  final int? nombreLogements;
  final double? noteGlobale;
  final int? nombreAvis;
  final bool superHost;

  HostInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    this.photo,
    this.bio,
    this.langues = const [],
    this.passions = const [],
    this.dateInscription,
    this.nombreLogements,
    this.noteGlobale,
    this.nombreAvis,
    this.superHost = false,
  });

  String get fullName => '$prenom $nom';

  factory HostInfo.fromJson(Map<String, dynamic> json) {
    return HostInfo(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      photo: json['photo'] as String?,
      bio: json['bio'] as String?,
      langues: json['langue'] != null
          ? List<String>.from(json['langue'] as List)
          : [],
      passions: json['passions'] != null
          ? List<String>.from(json['passions'] as List)
          : [],
      dateInscription: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      nombreLogements: json['nombre_logements'] as int?,
      noteGlobale: json['note_globale'] != null
          ? (json['note_globale'] as num).toDouble()
          : null,
      nombreAvis: json['nombre_avis'] as int?,
      superHost: json['super_host'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'photo': photo,
      'bio': bio,
      'langue': langues,
      'passions': passions,
      'created_at': dateInscription?.toIso8601String(),
      'nombre_logements': nombreLogements,
      'note_globale': noteGlobale,
      'nombre_avis': nombreAvis,
      'super_host': superHost,
    };
  }
}
