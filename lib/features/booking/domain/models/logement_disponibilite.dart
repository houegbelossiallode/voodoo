/// Modèle pour les disponibilités des logements
class LogementDisponibilite {
  final int id;
  final int logementId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut; // 'disponible', 'indisponible', 'reserve'

  LogementDisponibilite({
    required this.id,
    required this.logementId,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
  });

  factory LogementDisponibilite.fromJson(Map<String, dynamic> json) {
    return LogementDisponibilite(
      id: json['id'] as int,
      logementId: json['logement_id'] as int,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      statut: json['statut'] as String? ?? 'disponible',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logement_id': logementId,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin.toIso8601String().split('T')[0],
      'statut': statut,
    };
  }

  /// Vérifie si cette disponibilité chevauche une période donnée
  bool overlaps(DateTime start, DateTime end) {
    return dateDebut.isBefore(end) && dateFin.isAfter(start);
  }

  /// Vérifie si le logement est disponible pour cette période
  bool isAvailable() {
    return statut == 'disponible';
  }
}
