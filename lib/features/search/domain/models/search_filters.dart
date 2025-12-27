/// Modèle pour les filtres de recherche de logements
class SearchFilters {
  final String? destination; // Quartier ou ville
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final int? nbVoyageurs;
  final double? prixMin;
  final double? prixMax;
  final List<String> divinites; // IDs ou noms des divinités
  final List<int> equipements; // IDs des équipements
  final List<String> languesHote; // Langues parlées par l'hôte
  final int? nbChambresMin;
  final int? quartierId;
  final bool? assisterRituel; // Filtrer les logements avec rituels

  const SearchFilters({
    this.destination,
    this.dateDebut,
    this.dateFin,
    this.nbVoyageurs,
    this.prixMin,
    this.prixMax,
    this.divinites = const [],
    this.equipements = const [],
    this.languesHote = const [],
    this.nbChambresMin,
    this.quartierId,
    this.assisterRituel,
  });

  /// Crée une copie avec des modifications
  SearchFilters copyWith({
    String? destination,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? nbVoyageurs,
    double? prixMin,
    double? prixMax,
    List<String>? divinites,
    List<int>? equipements,
    List<String>? languesHote,
    int? nbChambresMin,
    int? quartierId,
    bool? assisterRituel,
  }) {
    return SearchFilters(
      destination: destination ?? this.destination,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      nbVoyageurs: nbVoyageurs ?? this.nbVoyageurs,
      prixMin: prixMin ?? this.prixMin,
      prixMax: prixMax ?? this.prixMax,
      divinites: divinites ?? this.divinites,
      equipements: equipements ?? this.equipements,
      languesHote: languesHote ?? this.languesHote,
      nbChambresMin: nbChambresMin ?? this.nbChambresMin,
      quartierId: quartierId ?? this.quartierId,
      assisterRituel: assisterRituel ?? this.assisterRituel,
    );
  }

  /// Réinitialise tous les filtres
  SearchFilters clear() {
    return const SearchFilters();
  }

  /// Vérifie si des filtres sont appliqués
  bool get hasFilters {
    return destination != null ||
        dateDebut != null ||
        dateFin != null ||
        nbVoyageurs != null ||
        prixMin != null ||
        prixMax != null ||
        divinites.isNotEmpty ||
        equipements.isNotEmpty ||
        languesHote.isNotEmpty ||
        nbChambresMin != null ||
        quartierId != null ||
        assisterRituel != null;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (destination != null) count++;
    if (dateDebut != null && dateFin != null) count++;
    if (nbVoyageurs != null) count++;
    if (prixMin != null || prixMax != null) count++;
    if (divinites.isNotEmpty) count++;
    if (equipements.isNotEmpty) count++;
    if (languesHote.isNotEmpty) count++;
    if (nbChambresMin != null) count++;
    if (assisterRituel != null) count++;
    return count;
  }

  /// Convertit en Map pour les requêtes
  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'nb_voyageurs': nbVoyageurs,
      'prix_min': prixMin,
      'prix_max': prixMax,
      'divinites': divinites,
      'equipements': equipements,
      'langues_hote': languesHote,
      'nb_chambres_min': nbChambresMin,
      'quartier_id': quartierId,
      'assister_rituel': assisterRituel,
    };
  }

  @override
  String toString() {
    return 'SearchFilters(destination: $destination, dates: $dateDebut - $dateFin, '
        'voyageurs: $nbVoyageurs, prix: $prixMin-$prixMax, '
        'divinites: ${divinites.length}, equipements: ${equipements.length})';
  }
}
