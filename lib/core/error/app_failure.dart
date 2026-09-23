/// Catégories d'échec exposables à l'utilisateur.
///
/// Chaque variante porte un message **déjà rédigé pour l'utilisateur final** :
/// aucun détail technique (nom de table, code PostgREST, trace) ne doit y
/// figurer. Les détails bruts partent dans [AppLogger], jamais à l'écran.
///
/// Cf. `AUDIT_SECURITE.md` — VUL-17.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  /// Message affichable tel quel dans l'interface.
  final String message;

  @override
  String toString() => message;
}

/// Pas de réseau, DNS injoignable, délai dépassé.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'Connexion indisponible. Vérifiez votre réseau et réessayez.',
  ]);
}

/// Session expirée ou droits insuffisants.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Votre session a expiré. Veuillez vous reconnecter.',
  ]);
}

/// La ressource demandée n'existe pas (ou n'est pas visible par cet utilisateur).
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([
    super.message = 'Cet élément n\'est plus disponible.',
  ]);
}

/// Donnée saisie invalide, règle métier non respectée.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// Échec lié au paiement.
final class PaymentFailure extends AppFailure {
  const PaymentFailure([
    super.message =
        'Le paiement n\'a pas abouti. Aucun montant n\'a été débité.',
  ]);
}

/// Conflit : dates déjà réservées, doublon, écriture concurrente.
final class ConflictFailure extends AppFailure {
  const ConflictFailure([
    super.message =
        'Cette opération est en conflit avec une autre. Actualisez et réessayez.',
  ]);
}

/// Erreur serveur ou cas non identifié.
final class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message =
        'Une erreur est survenue. Veuillez réessayer dans un instant.',
  ]);
}
