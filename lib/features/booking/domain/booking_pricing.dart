/// Répartition d'un montant de réservation entre plateforme, projet et hôte.
///
/// Toutes les valeurs sont exprimées en XOF.
class BookingBreakdown {
  const BookingBreakdown({
    required this.montantTotal,
    required this.commission,
    required this.partProjet,
    required this.montantHote,
  });

  /// Montant payé par le voyageur.
  final double montantTotal;

  /// Part revenant à la plateforme.
  final double commission;

  /// Part reversée au projet communautaire (0 si aucun projet).
  final double partProjet;

  /// Part créditée sur le compte de l'hôte.
  final double montantHote;

  @override
  String toString() =>
      'BookingBreakdown(total: $montantTotal, commission: $commission, '
      'projet: $partProjet, hôte: $montantHote)';
}

/// Calculs de tarification d'une réservation.
///
/// Ces fonctions sont **pures** : aucun accès réseau, aucune dépendance à
/// Flutter. Elles sont extraites de `ReservationRepository`, où elles étaient
/// mêlées aux appels Supabase et donc intestables.
///
/// ⚠️ **Ces calculs ne font pas autorité.** Depuis la correction VUL-02, la
/// répartition qui fait foi est celle de la fonction PostgreSQL
/// `confirm_reservation()`. Les fonctions ci-dessous servent uniquement à
/// afficher une estimation à l'utilisateur avant paiement. Toute divergence
/// avec le serveur doit être traitée comme un bug côté client.
abstract final class BookingPricing {
  const BookingPricing._();

  /// Montant total d'un séjour.
  ///
  /// Lève [ArgumentError] si [nbNuits] ou [prixParNuit] est négatif.
  static double montantTotal({
    required double prixParNuit,
    required int nbNuits,
  }) {
    if (prixParNuit < 0) {
      throw ArgumentError.value(
        prixParNuit,
        'prixParNuit',
        'Doit être positif',
      );
    }
    if (nbNuits < 0) {
      throw ArgumentError.value(nbNuits, 'nbNuits', 'Doit être positif');
    }
    return prixParNuit * nbNuits;
  }

  /// Nombre de nuits entre deux dates, bornes `[début, fin)`.
  ///
  /// Un départ le jour de l'arrivée vaut 0 nuit. Les heures sont ignorées :
  /// seules les dates calendaires comptent.
  static int nbNuits(DateTime debut, DateTime fin) {
    final d = DateTime(debut.year, debut.month, debut.day);
    final f = DateTime(fin.year, fin.month, fin.day);
    return f.difference(d).inDays;
  }

  /// Répartit [montantTotal] selon les pourcentages fournis.
  ///
  /// [pourcentageCommission] et [pourcentageProjet] sont exprimés en points
  /// de pourcentage (ex. `15` pour 15 %). Les montants sont arrondis au
  /// centime, comme côté serveur.
  static BookingBreakdown repartir({
    required double montantTotal,
    required double pourcentageCommission,
    double pourcentageProjet = 0,
  }) {
    if (montantTotal < 0) {
      throw ArgumentError.value(
        montantTotal,
        'montantTotal',
        'Doit être positif',
      );
    }
    if (pourcentageCommission < 0 || pourcentageCommission > 100) {
      throw ArgumentError.value(
        pourcentageCommission,
        'pourcentageCommission',
        'Doit être compris entre 0 et 100',
      );
    }
    if (pourcentageProjet < 0 || pourcentageProjet > 100) {
      throw ArgumentError.value(
        pourcentageProjet,
        'pourcentageProjet',
        'Doit être compris entre 0 et 100',
      );
    }
    if (pourcentageCommission + pourcentageProjet > 100) {
      throw ArgumentError(
        'La somme des pourcentages dépasse 100 % : '
        'l\'hôte serait débité au lieu d\'être crédité',
      );
    }

    final commission = _arrondir(montantTotal * pourcentageCommission / 100);
    final partProjet = _arrondir(montantTotal * pourcentageProjet / 100);

    return BookingBreakdown(
      montantTotal: montantTotal,
      commission: commission,
      partProjet: partProjet,
      montantHote: _arrondir(montantTotal - commission - partProjet),
    );
  }

  static double _arrondir(double v) => (v * 100).roundToDouble() / 100;
}
