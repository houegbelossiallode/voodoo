/// Modèle pour les préférences culturelles de l'utilisateur
/// Correspond à la table user_preferences dans Supabase
class UserPreferences {
  final int id;
  final int userId;
  final List<String> divinitesPreferees; // IDs ou noms des divinités préférées
  final bool assisterRituel; // Souhaite assister à un rituel en direct
  final String preferredCurrency; // Devise préférée (XOF par défaut)
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserPreferences({
    required this.id,
    required this.userId,
    this.divinitesPreferees = const [],
    this.assisterRituel = false,
    this.preferredCurrency = 'XOF',
    required this.createdAt,
    this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      divinitesPreferees:
          (json['divinites_preferees'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      assisterRituel: json['assister_rituel'] as bool? ?? false,
      preferredCurrency: json['preferred_currency'] as String? ?? 'XOF',
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
      'preferred_currency': preferredCurrency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    int? id,
    int? userId,
    List<String>? divinitesPreferees,
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

  /// Vérifie si l'utilisateur a complété le questionnaire
  /// Le questionnaire est considéré comme complété si au moins une divinité est sélectionnée
  bool get isCompleted {
    return divinitesPreferees.isNotEmpty;
  }

  /// Vérifie si l'utilisateur est intéressé par une divinité spécifique
  bool isInterestedIn(String diviniteId) {
    return divinitesPreferees.contains(diviniteId);
  }
}

/// Divinités disponibles dans le questionnaire
enum DiviniteType {
  sakpata('sakpata', 'Sakpata', 'Divinité de la terre et de la guérison'),
  mamiwata('mamiwata', 'Mamiwata', 'Déesse des eaux et de la richesse'),
  legba('legba', 'Legba', 'Gardien des portes et des chemins'),
  hevioso('hevioso', 'Hevioso', 'Dieu du tonnerre et de la foudre'),
  gu('gu', 'Gu', 'Dieu du fer et de la guerre'),
  dan('dan', 'Dan', 'Serpent arc-en-ciel, symbole de richesse');

  final String id;
  final String nom;
  final String description;

  const DiviniteType(this.id, this.nom, this.description);

  static DiviniteType? fromId(String? id) {
    if (id == null) return null;
    try {
      return DiviniteType.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Niveaux d'immersion disponibles
enum NiveauImmersion {
  debutant('débutant', 'Découverte', 'Je découvre la culture Vodoun'),
  intermediaire('intermédiaire', 'Exploration', 'Je connais quelques aspects'),
  avance('avancé', 'Immersion', 'Je souhaite une expérience approfondie');

  final String value;
  final String label;
  final String description;

  const NiveauImmersion(this.value, this.label, this.description);

  static NiveauImmersion? fromValue(String? value) {
    if (value == null) return null;
    return NiveauImmersion.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NiveauImmersion.debutant,
    );
  }
}
