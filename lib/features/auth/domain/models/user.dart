class User {
  final int id; // ID auto-incrémenté PostgreSQL
  final String? supabaseId; // UUID de Supabase Auth
  final String nom;
  final String prenom;
  final String? password;
  final List<String> langue;
  final String telephone;
  final String profession;
  final List<String> passions;
  final String? photo;
  final String? bio;
  final String email;
  final DateTime? emailVerifiedAt;
  final String actif;
  final int roleId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.supabaseId,
    required this.nom,
    required this.prenom,
    this.password,
    this.langue = const [],
    required this.telephone,
    required this.profession,
    this.passions = const [],
    this.photo,
    this.bio,
    required this.email,
    this.emailVerifiedAt,
    this.actif = 'OUI',
    required this.roleId,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      supabaseId: json['supabase_id'] as String?,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      password: json['password'] as String?,
      langue:
          (json['langue'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      telephone: json['telephone'] as String,
      profession: json['profession'] as String,
      passions:
          (json['passions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photo: json['photo'] as String?,
      bio: json['bio'] as String?,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      actif: json['actif'] as String? ?? 'OUI',
      roleId: json['role_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supabase_id': supabaseId,
      'nom': nom,
      'prenom': prenom,
      'password': password,
      'langue': langue,
      'telephone': telephone,
      'profession': profession,
      'passions': passions,
      'photo': photo,
      'bio': bio,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'actif': actif,
      'role_id': roleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$prenom $nom';

  User copyWith({
    int? id,
    String? supabaseId,
    String? nom,
    String? prenom,
    String? password,
    List<String>? langue,
    String? telephone,
    String? profession,
    List<String>? passions,
    String? photo,
    String? bio,
    String? email,
    DateTime? emailVerifiedAt,
    String? actif,
    int? roleId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      password: password ?? this.password,
      langue: langue ?? this.langue,
      telephone: telephone ?? this.telephone,
      profession: profession ?? this.profession,
      passions: passions ?? this.passions,
      photo: photo ?? this.photo,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      actif: actif ?? this.actif,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserPreferences {
  final List<String> interestedDivinities;
  final bool wantsToAttendRituals;
  final List<String> culturalInterests;

  UserPreferences({
    this.interestedDivinities = const [],
    this.wantsToAttendRituals = false,
    this.culturalInterests = const [],
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      interestedDivinities:
          (json['interested_divinities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      wantsToAttendRituals: json['wants_to_attend_rituals'] as bool? ?? false,
      culturalInterests:
          (json['cultural_interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interested_divinities': interestedDivinities,
      'wants_to_attend_rituals': wantsToAttendRituals,
      'cultural_interests': culturalInterests,
    };
  }

  UserPreferences copyWith({
    List<String>? interestedDivinities,
    bool? wantsToAttendRituals,
    List<String>? culturalInterests,
  }) {
    return UserPreferences(
      interestedDivinities: interestedDivinities ?? this.interestedDivinities,
      wantsToAttendRituals: wantsToAttendRituals ?? this.wantsToAttendRituals,
      culturalInterests: culturalInterests ?? this.culturalInterests,
    );
  }
}
