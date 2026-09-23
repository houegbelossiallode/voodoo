import 'package:flutter_test/flutter_test.dart';
import 'package:vodou/features/booking/domain/booking_pricing.dart';

/// Tests de la répartition financière d'une réservation.
///
/// Ces calculs déterminent ce que touchent la plateforme, le projet
/// communautaire et l'hôte. Une régression ici fausse des montants réels :
/// c'est la partie du code qui mérite la couverture la plus stricte.
void main() {
  group('BookingPricing.nbNuits', () {
    test('compte les nuits entre deux dates', () {
      expect(
        BookingPricing.nbNuits(DateTime(2026, 3, 1), DateTime(2026, 3, 5)),
        4,
      );
    });

    test('vaut 0 pour un départ le jour de l\'arrivée', () {
      expect(
        BookingPricing.nbNuits(DateTime(2026, 3, 1), DateTime(2026, 3, 1)),
        0,
      );
    });

    test('ignore les heures', () {
      expect(
        BookingPricing.nbNuits(
          DateTime(2026, 3, 1, 23, 59),
          DateTime(2026, 3, 2, 0, 1),
        ),
        1,
      );
    });

    test('traverse correctement un changement de mois', () {
      expect(
        BookingPricing.nbNuits(DateTime(2026, 1, 30), DateTime(2026, 2, 2)),
        3,
      );
    });

    test('traverse correctement une année bissextile', () {
      expect(
        BookingPricing.nbNuits(DateTime(2028, 2, 27), DateTime(2028, 3, 1)),
        3, // 2028 est bissextile : 27→28, 28→29, 29→1
      );
    });
  });

  group('BookingPricing.montantTotal', () {
    test('multiplie le prix par le nombre de nuits', () {
      expect(
        BookingPricing.montantTotal(prixParNuit: 15000, nbNuits: 4),
        60000,
      );
    });

    test('vaut 0 pour zéro nuit', () {
      expect(BookingPricing.montantTotal(prixParNuit: 15000, nbNuits: 0), 0);
    });

    test('refuse un prix négatif', () {
      expect(
        () => BookingPricing.montantTotal(prixParNuit: -1, nbNuits: 2),
        throwsArgumentError,
      );
    });

    test('refuse un nombre de nuits négatif', () {
      expect(
        () => BookingPricing.montantTotal(prixParNuit: 100, nbNuits: -1),
        throwsArgumentError,
      );
    });
  });

  group('BookingPricing.repartir', () {
    test('applique la commission plateforme seule', () {
      final r = BookingPricing.repartir(
        montantTotal: 100000,
        pourcentageCommission: 15,
      );

      expect(r.commission, 15000);
      expect(r.partProjet, 0);
      expect(r.montantHote, 85000);
    });

    test('cumule commission et contribution projet', () {
      final r = BookingPricing.repartir(
        montantTotal: 100000,
        pourcentageCommission: 15,
        pourcentageProjet: 5,
      );

      expect(r.commission, 15000);
      expect(r.partProjet, 5000);
      expect(r.montantHote, 80000);
    });

    test('la somme des parts égale toujours le montant total', () {
      for (final montant in [1000.0, 33333.0, 99999.0, 7.0]) {
        for (final pct in [0.0, 7.5, 15.0, 33.33]) {
          final r = BookingPricing.repartir(
            montantTotal: montant,
            pourcentageCommission: pct,
            pourcentageProjet: 2.5,
          );

          expect(
            r.commission + r.partProjet + r.montantHote,
            closeTo(montant, 0.01),
            reason: 'montant=$montant, commission=$pct%',
          );
        }
      }
    });

    test('une commission de 0 % reverse tout à l\'hôte', () {
      final r = BookingPricing.repartir(
        montantTotal: 50000,
        pourcentageCommission: 0,
      );

      expect(r.commission, 0);
      expect(r.montantHote, 50000);
    });

    test('une commission de 100 % ne laisse rien à l\'hôte', () {
      final r = BookingPricing.repartir(
        montantTotal: 50000,
        pourcentageCommission: 100,
      );

      expect(r.commission, 50000);
      expect(r.montantHote, 0);
    });

    test('arrondit au centime', () {
      final r = BookingPricing.repartir(
        montantTotal: 10000,
        pourcentageCommission: 3.333,
      );

      // 10000 * 3.333 / 100 = 333.3
      expect(r.commission, 333.3);
    });

    test('refuse un montant négatif', () {
      expect(
        () => BookingPricing.repartir(
          montantTotal: -1,
          pourcentageCommission: 10,
        ),
        throwsArgumentError,
      );
    });

    test('refuse une commission hors de [0, 100]', () {
      expect(
        () => BookingPricing.repartir(
          montantTotal: 1000,
          pourcentageCommission: 101,
        ),
        throwsArgumentError,
      );
      expect(
        () => BookingPricing.repartir(
          montantTotal: 1000,
          pourcentageCommission: -1,
        ),
        throwsArgumentError,
      );
    });

    test('refuse un cumul de pourcentages supérieur à 100 %', () {
      // Sans ce garde-fou, montantHote deviendrait négatif et le compte de
      // l'hôte serait DÉBITÉ à chaque réservation.
      expect(
        () => BookingPricing.repartir(
          montantTotal: 100000,
          pourcentageCommission: 80,
          pourcentageProjet: 30,
        ),
        throwsArgumentError,
      );
    });

    test('l\'hôte n\'est jamais débité', () {
      for (final pctCommission in [0.0, 25.0, 50.0, 99.9]) {
        final r = BookingPricing.repartir(
          montantTotal: 10000,
          pourcentageCommission: pctCommission,
        );
        expect(r.montantHote, greaterThanOrEqualTo(0));
      }
    });
  });
}
