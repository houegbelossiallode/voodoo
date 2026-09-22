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
  final String? role; // Libellé du rôle (récupéré via jointure)
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
    this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Récupérer et parser role_id de façon sécurisée (int ou String)
    int parsedRoleId = 1;
    if (json['role_id'] != null) {
      if (json['role_id'] is int) {
        parsedRoleId = json['role_id'] as int;
      } else if (json['role_id'] is String) {
        parsedRoleId = int.tryParse(json['role_id'] as String) ?? 1;
      }
    } else if (json['role'] != null) {
      if (json['role'] is Map && json['role']['id'] != null) {
        final rId = json['role']['id'];
        parsedRoleId = rId is int ? rId : (int.tryParse(rId.toString()) ?? 1);
      } else if (json['role'] is int) {
        parsedRoleId = json['role'] as int;
      } else if (json['role'] is String) {
        parsedRoleId = int.tryParse(json['role'] as String) ?? 1;
      }
    }

    // Récupérer le libellé du rôle depuis la jointure PostgreSQL/Supabase (relation users.role_id -> roles.id)
    String? roleLibelle;
    
    if (json['role'] != null) {
      if (json['role'] is Map) {
        roleLibelle = (json['role'] as Map<String, dynamic>)['libelle'] as String?;
      } else if (json['role'] is String) {
        final roleStr = json['role'] as String;
        if (int.tryParse(roleStr) == null) {
          roleLibelle = roleStr;
        }
      }
    }
    
    if (roleLibelle == null && json['roles'] != null) {
      if (json['roles'] is Map) {
        roleLibelle = (json['roles'] as Map<String, dynamic>)['libelle'] as String?;
      } else if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
        final firstRole = (json['roles'] as List).first;
        if (firstRole is Map) {
          roleLibelle = firstRole['libelle'] as String?;
        }
      } else if (json['roles'] is String) {
        final roleStr = json['roles'] as String;
        if (int.tryParse(roleStr) == null) {
          roleLibelle = roleStr;
        }
      }
    }

    return User(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id'].toString()) ?? 0),
      supabaseId: json['supabase_id'] as String?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      password: json['password'] as String?,
      langue:
          (json['langue'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      telephone: json['telephone'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      passions:
          (json['passions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photo: json['photo'] as String?,
      bio: json['bio'] as String?,
      email: json['email'] as String? ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      actif: json['actif'] as String? ?? 'OUI',
      roleId: parsedRoleId,
      role: roleLibelle,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
    String? role,
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
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserPreferences {
  final int? id;
  final int userId;
  final List<int> divinitesPreferees; // IDs des divinités
  final bool assisterRituel;
  final String preferredCurrency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserPreferences({
    this.id,
    required this.userId,
    this.divinitesPreferees = const [],
    this.assisterRituel = false,
    this.preferredCurrency = 'XOF',
    this.createdAt,
    this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] != null
          ? (int.tryParse(json['user_id'].toString()) ?? 0)
          : 0,
      divinitesPreferees: json['divinites_preferees'] != null
          ? (json['divinites_preferees'] as List<dynamic>)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList()
          : [],
      assisterRituel: json['assister_rituel'] as bool? ?? false,
      preferredCurrency: json['preferred_currency'] as String? ?? 'XOF',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'divinites_preferees': divinitesPreferees,
      'assister_rituel': assisterRituel,
      'preferred_currency': preferredCurrency,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    int? id,
    int? userId,
    List<int>? divinitesPreferees,
    bool? assisterRituel,
    String? preferredCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      divinitesPreferees: divinitesPreferees ?? this.divinitesPreferees,
      assisterRituel: assisterRituel ?? this.assisterRituel,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasPreferences => divinitesPreferees.isNotEmpty;
}
