import 'chat_message.dart';

/// Modèle pour la table 'conversations'
class ConversationModel {
  final int id;
  final int? logementId;
  final int visiteurId;
  final int hoteId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (chargées selon le besoin)
  final Map<String, dynamic>? logement;
  final Map<String, dynamic>? visiteur;
  final Map<String, dynamic>? hote;
  final ChatMessage? dernierMessage;
  final int messagesNonLus;

  ConversationModel({
    required this.id,
    this.logementId,
    required this.visiteurId,
    required this.hoteId,
    required this.createdAt,
    required this.updatedAt,
    this.logement,
    this.visiteur,
    this.hote,
    this.dernierMessage,
    this.messagesNonLus = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      logementId: json['logement_id'] as int?,
      visiteurId: json['visiteur_id'] as int,
      hoteId: json['hote_id'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      logement: json['logement'] as Map<String, dynamic>?,
      visiteur: json['visiteur'] as Map<String, dynamic>?,
      hote: json['hote'] as Map<String, dynamic>?,
      dernierMessage: json['dernier_message'] != null
          ? ChatMessage.fromJson(
              json['dernier_message'] as Map<String, dynamic>,
            )
          : null,
      messagesNonLus: json['messages_non_lus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logement_id': logementId,
      'visiteur_id': visiteurId,
      'hote_id': hoteId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Nom de l'autre participant
  String getNomParticipant(int currentUserId) {
    if (currentUserId == visiteurId) {
      // Je suis le visiteur, afficher le nom de l'hôte
      if (hote == null) return 'Hôte';
      final nom = hote!['nom'] ?? '';
      final prenom = hote!['prenom'] ?? '';
      return '$prenom $nom'.trim();
    } else {
      // Je suis l'hôte, afficher le nom du visiteur
      if (visiteur == null) return 'Visiteur';
      final nom = visiteur!['nom'] ?? '';
      final prenom = visiteur!['prenom'] ?? '';
      return '$prenom $nom'.trim();
    }
  }

  /// Avatar de l'autre participant
  String? getAvatarParticipant(int currentUserId) {
    if (currentUserId == visiteurId) {
      return hote?['photo'];
    } else {
      return visiteur?['photo'];
    }
  }

  /// Titre du logement (si disponible)
  String? getTitreLogement() {
    return logement?['titre'];
  }

  /// Dernier message texte
  String? getDernierMessageTexte() {
    return dernierMessage?.message;
  }

  /// Date du dernier message
  DateTime? getDateDernierMessage() {
    return dernierMessage?.createdAt;
  }

  /// A des messages non lus
  bool hasMessagesNonLus() {
    return messagesNonLus > 0;
  }

  /// Formatage de la date du dernier message
  String getFormattedLastMessageDate() {
    if (dernierMessage == null) {
      return getFormattedDate(updatedAt);
    }
    return getFormattedDate(dernierMessage!.createdAt);
  }

  String getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  ConversationModel copyWith({
    int? id,
    int? logementId,
    int? visiteurId,
    int? hoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? logement,
    Map<String, dynamic>? visiteur,
    Map<String, dynamic>? hote,
    ChatMessage? dernierMessage,
    int? messagesNonLus,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      logementId: logementId ?? this.logementId,
      visiteurId: visiteurId ?? this.visiteurId,
      hoteId: hoteId ?? this.hoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logement: logement ?? this.logement,
      visiteur: visiteur ?? this.visiteur,
      hote: hote ?? this.hote,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      messagesNonLus: messagesNonLus ?? this.messagesNonLus,
    );
  }
}
