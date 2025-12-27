/// Modèle pour la table 'messages' (messagerie entre visiteurs et hôtes)
class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String? message;
  final String? attachment;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final Map<String, dynamic>? sender;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.message,
    this.attachment,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      message: json['message'] as String?,
      attachment: json['attachment'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      sender: json['sender'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': message,
      'attachment': attachment,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Nom de l'expéditeur
  String getSenderName() {
    if (sender == null) return 'Utilisateur';
    final nom = sender!['nom'] ?? '';
    final prenom = sender!['prenom'] ?? '';
    return '$prenom $nom'.trim();
  }

  /// Avatar de l'expéditeur
  String? getSenderAvatar() {
    return sender?['photo'];
  }

  /// Est-ce un message envoyé par l'utilisateur actuel
  bool isSentByMe(int currentUserId) {
    return senderId == currentUserId;
  }

  /// A un fichier attaché
  bool hasAttachment() {
    return attachment != null && attachment!.isNotEmpty;
  }

  /// Type de fichier (image, document, etc.)
  String? getAttachmentType() {
    if (!hasAttachment()) return null;

    final ext = attachment!.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image';
    } else if (['pdf', 'doc', 'docx'].contains(ext)) {
      return 'document';
    }
    return 'file';
  }

  /// Formatage de la date
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[createdAt.weekday - 1];
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? message,
    String? attachment,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? sender,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      attachment: attachment ?? this.attachment,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
    );
  }
}
