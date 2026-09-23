/// Règles de chevauchement et de validité des périodes de réservation.
///
/// Fonctions **pures**, extraites de `ReservationRepository.checkAvailability`
/// où elles étaient imbriquées dans des requêtes Supabase.
///
/// ## Convention de bornes
///
/// Toutes les périodes suivent la convention `[début, fin)` : la date de début
/// est incluse, la date de fin est exclue. Un départ le 10 et une arrivée le 10
/// ne sont donc **pas** en conflit — c'est le comportement attendu en
/// hôtellerie, et celui de la contrainte PostgreSQL `daterange(..., '[)')`
/// posée à l'étape 6 du runbook.
abstract final class DateRangeRules {
  const DateRangeRules._();

  /// Statuts de réservation qui bloquent réellement un logement.
  ///
  /// La base contient des variantes accentuées et non accentuées ; la
  /// comparaison se fait donc sur une forme normalisée.
  static const Set<String> statutsBloquants = {
    'PAYE',
    'PAYÉ',
    'CONFIRMEE',
    'CONFIRMÉE',
  };

  /// Ramène une date à minuit, pour comparer des jours et non des instants.
  static DateTime jour(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Indique si deux périodes `[début, fin)` se chevauchent.
  static bool seChevauchent({
    required DateTime debutA,
    required DateTime finA,
    required DateTime debutB,
    required DateTime finB,
  }) {
    final da = jour(debutA);
    final fa = jour(finA);
    final db = jour(debutB);
    final fb = jour(finB);
    return da.isBefore(fb) && fa.isAfter(db);
  }

  /// Indique si un statut de réservation bloque les dates.
  static bool estBloquant(String? statut) {
    if (statut == null) return false;
    return statutsBloquants.contains(statut.trim().toUpperCase());
  }

  /// Indique si `[debut, fin)` est entièrement couvert par `[dispoDebut, dispoFin]`.
  ///
  /// Les périodes de disponibilité déclarées par l'hôte sont inclusives des
  /// deux côtés, contrairement aux réservations.
  static bool estDansPeriode({
    required DateTime debut,
    required DateTime fin,
    required DateTime dispoDebut,
    required DateTime dispoFin,
  }) {
    final d = jour(debut);
    final f = jour(fin);
    final dd = jour(dispoDebut);
    final df = jour(dispoFin);
    return !d.isBefore(dd) && !f.isAfter(df);
  }

  /// Valide une demande de réservation côté client.
  ///
  /// Retourne `null` si la période est valide, sinon un message destiné à
  /// l'utilisateur. Cette validation est un confort : la validation qui fait
  /// foi est celle du serveur (VUL-02).
  static String? valider({
    required DateTime? debut,
    required DateTime? fin,
    DateTime? maintenant,
    int dureeMaxNuits = 90,
  }) {
    if (debut == null || fin == null) {
      return 'Sélectionnez vos dates d\'arrivée et de départ.';
    }

    final aujourdhui = jour(maintenant ?? DateTime.now());
    final d = jour(debut);
    final f = jour(fin);

    if (d.isBefore(aujourdhui)) {
      return 'La date d\'arrivée ne peut pas être dans le passé.';
    }
    if (!f.isAfter(d)) {
      return 'La date de départ doit suivre la date d\'arrivée.';
    }
    if (f.difference(d).inDays > dureeMaxNuits) {
      return 'La durée maximale d\'un séjour est de $dureeMaxNuits nuits.';
    }
    return null;
  }
}
