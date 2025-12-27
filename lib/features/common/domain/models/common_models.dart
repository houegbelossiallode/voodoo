/// Modèles communs utilisés dans toute l'application

/// Modèle pour la table 'roles'
class Role {
  final String id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Role({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
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

/// Modèle pour la table 'pays'
class Pays {
  final String id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Pays({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory Pays.fromJson(Map<String, dynamic> json) {
    return Pays(
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

/// Modèle pour la table 'type_logements'
class TypeLogement {
  final String id;
  final String libelle;
  final String actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TypeLogement({
    required this.id,
    required this.libelle,
    this.actif = 'OUI',
    required this.createdAt,
    this.updatedAt,
  });

  factory TypeLogement.fromJson(Map<String, dynamic> json) {
    return TypeLogement(
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

/// Modèle pour la table 'constances' (paramètres de l'application)
class Constance {
  final String id;
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
      id: json['id'].toString(),
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

/// Modèle pour la table 'notifications'
class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
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
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isRead => readAt != null;

  Notification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modèle pour la table 'user_preferences'
class UserPreference {
  final String id;
  final String userId;
  final List<String> divinitesPreferees;
  final bool assisterRituel;
  final String? niveauImmersion; // débutant, intermédiaire, avancé
  final Map<String, dynamic>? preferencesSupplementaires;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserPreference({
    required this.id,
    required this.userId,
    this.divinitesPreferees = const [],
    this.assisterRituel = false,
    this.niveauImmersion,
    this.preferencesSupplementaires,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      divinitesPreferees:
          (json['divinites_preferees'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      assisterRituel: json['assister_rituel'] as bool? ?? false,
      niveauImmersion: json['niveau_immersion'] as String?,
      preferencesSupplementaires:
          json['preferences_supplementaires'] as Map<String, dynamic>?,
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
      'divinites_preferees': divinitesPreferees,
      'assister_rituel': assisterRituel,
      'niveau_immersion': niveauImmersion,
      'preferences_supplementaires': preferencesSupplementaires,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserPreference copyWith({
    String? id,
    String? userId,
    List<String>? divinitesPreferees,
    bool? assisterRituel,
    String? niveauImmersion,
    Map<String, dynamic>? preferencesSupplementaires,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      divinitesPreferees: divinitesPreferees ?? this.divinitesPreferees,
      assisterRituel: assisterRituel ?? this.assisterRituel,
      niveauImmersion: niveauImmersion ?? this.niveauImmersion,
      preferencesSupplementaires:
          preferencesSupplementaires ?? this.preferencesSupplementaires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
