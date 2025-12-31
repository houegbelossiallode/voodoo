// Constante pour différencier null d'une valeur non fournie
const _undefined = Object();

/// Modèle pour les filtres de recherche de logements
class SearchFilters {
  final String? destination; // Quartier ou ville
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final int? nbVoyageurs;
  final double? prixMin;
  final double? prixMax;
  final List<int> divinites; // IDs des divinités
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
    Object? destination = _undefined,
    Object? dateDebut = _undefined,
    Object? dateFin = _undefined,
    Object? nbVoyageurs = _undefined,
    Object? prixMin = _undefined,
    Object? prixMax = _undefined,
    List<int>? divinites,
    List<int>? equipements,
    List<String>? languesHote,
    Object? nbChambresMin = _undefined,
    Object? quartierId = _undefined,
    Object? assisterRituel = _undefined,
  }) {
    return SearchFilters(
      destination: destination == _undefined
          ? this.destination
          : destination as String?,
      dateDebut: dateDebut == _undefined
          ? this.dateDebut
          : dateDebut as DateTime?,
      dateFin: dateFin == _undefined ? this.dateFin : dateFin as DateTime?,
      nbVoyageurs: nbVoyageurs == _undefined
          ? this.nbVoyageurs
          : nbVoyageurs as int?,
      prixMin: prixMin == _undefined ? this.prixMin : prixMin as double?,
      prixMax: prixMax == _undefined ? this.prixMax : prixMax as double?,
      divinites: divinites ?? this.divinites,
      equipements: equipements ?? this.equipements,
      languesHote: languesHote ?? this.languesHote,
      nbChambresMin: nbChambresMin == _undefined
          ? this.nbChambresMin
          : nbChambresMin as int?,
      quartierId: quartierId == _undefined
          ? this.quartierId
          : quartierId as int?,
      assisterRituel: assisterRituel == _undefined
          ? this.assisterRituel
          : assisterRituel as bool?,
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
