import 'package:flutter_test/flutter_test.dart';
import 'package:vodou/features/booking/domain/date_range_rules.dart';

/// Tests du chevauchement de dates.
///
/// Une erreur ici produit soit une double réservation du même logement, soit
/// un refus de réservations parfaitement valides. Les cas aux bornes sont
/// donc traités explicitement.
void main() {
  DateTime d(int jour) => DateTime(2026, 6, jour);

  group('DateRangeRules.seChevauchent', () {
    test('périodes totalement disjointes', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(5),
          debutB: d(10),
          finB: d(15),
        ),
        isFalse,
      );
    });

    test('périodes identiques', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(5),
          debutB: d(1),
          finB: d(5),
        ),
        isTrue,
      );
    });

    test('A englobe B', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(20),
          debutB: d(5),
          finB: d(10),
        ),
        isTrue,
      );
    });

    test('B englobe A', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(5),
          finA: d(10),
          debutB: d(1),
          finB: d(20),
        ),
        isTrue,
      );
    });

    test('chevauchement partiel par la gauche', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(10),
          debutB: d(5),
          finB: d(15),
        ),
        isTrue,
      );
    });

    test('chevauchement partiel par la droite', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(5),
          finA: d(15),
          debutB: d(1),
          finB: d(10),
        ),
        isTrue,
      );
    });

    // --- Cas aux bornes : c'est ici que les bugs se cachent -----------------

    test('séjours adjacents : départ le jour de l\'arrivée suivante', () {
      // A : 1 → 5 (départ le 5). B : 5 → 10 (arrivée le 5).
      // Convention [début, fin) : PAS de conflit, le logement est libéré
      // le matin et réoccupé le soir.
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(5),
          debutB: d(5),
          finB: d(10),
        ),
        isFalse,
      );
    });

    test('séjours adjacents dans l\'autre sens', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(5),
          finA: d(10),
          debutB: d(1),
          finB: d(5),
        ),
        isFalse,
      );
    });

    test('une seule nuit de recouvrement est un conflit', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: d(1),
          finA: d(6),
          debutB: d(5),
          finB: d(10),
        ),
        isTrue,
      );
    });

    test('les heures sont ignorées', () {
      expect(
        DateRangeRules.seChevauchent(
          debutA: DateTime(2026, 6, 1, 23, 59),
          finA: DateTime(2026, 6, 5, 0, 1),
          debutB: DateTime(2026, 6, 5, 14, 0),
          finB: DateTime(2026, 6, 10),
        ),
        isFalse,
      );
    });

    test('la relation est symétrique', () {
      for (var a = 1; a <= 6; a++) {
        for (var b = 1; b <= 6; b++) {
          final ab = DateRangeRules.seChevauchent(
            debutA: d(a),
            finA: d(a + 3),
            debutB: d(b),
            finB: d(b + 3),
          );
          final ba = DateRangeRules.seChevauchent(
            debutA: d(b),
            finA: d(b + 3),
            debutB: d(a),
            finB: d(a + 3),
          );
          expect(ab, ba, reason: 'a=$a, b=$b');
        }
      }
    });
  });

  group('DateRangeRules.estBloquant', () {
    test('reconnaît les statuts payés, accentués ou non', () {
      expect(DateRangeRules.estBloquant('PAYE'), isTrue);
      expect(DateRangeRules.estBloquant('PAYÉ'), isTrue);
      expect(DateRangeRules.estBloquant('CONFIRMEE'), isTrue);
      expect(DateRangeRules.estBloquant('CONFIRMÉE'), isTrue);
    });

    test('ignore la casse et les espaces', () {
      expect(DateRangeRules.estBloquant('  paye  '), isTrue);
      expect(DateRangeRules.estBloquant('Confirmee'), isTrue);
    });

    test('ne bloque pas sur une réservation annulée ou en attente', () {
      expect(DateRangeRules.estBloquant('ANNULEE'), isFalse);
      expect(DateRangeRules.estBloquant('cancelled'), isFalse);
      expect(DateRangeRules.estBloquant('EN_ATTENTE'), isFalse);
      expect(DateRangeRules.estBloquant(''), isFalse);
      expect(DateRangeRules.estBloquant(null), isFalse);
    });
  });

  group('DateRangeRules.estDansPeriode', () {
    test('séjour strictement inclus', () {
      expect(
        DateRangeRules.estDansPeriode(
          debut: d(5),
          fin: d(10),
          dispoDebut: d(1),
          dispoFin: d(20),
        ),
        isTrue,
      );
    });

    test('séjour exactement aux bornes', () {
      expect(
        DateRangeRules.estDansPeriode(
          debut: d(1),
          fin: d(20),
          dispoDebut: d(1),
          dispoFin: d(20),
        ),
        isTrue,
      );
    });

    test('séjour débordant avant', () {
      expect(
        DateRangeRules.estDansPeriode(
          debut: d(1),
          fin: d(10),
          dispoDebut: d(5),
          dispoFin: d(20),
        ),
        isFalse,
      );
    });

    test('séjour débordant après', () {
      expect(
        DateRangeRules.estDansPeriode(
          debut: d(5),
          fin: d(25),
          dispoDebut: d(1),
          dispoFin: d(20),
        ),
        isFalse,
      );
    });
  });

  group('DateRangeRules.valider', () {
    final maintenant = DateTime(2026, 6, 15);

    test('accepte une période valide', () {
      expect(
        DateRangeRules.valider(
          debut: d(20),
          fin: d(25),
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('exige les deux dates', () {
      expect(
        DateRangeRules.valider(debut: null, fin: d(25), maintenant: maintenant),
        isNotNull,
      );
      expect(
        DateRangeRules.valider(debut: d(20), fin: null, maintenant: maintenant),
        isNotNull,
      );
    });

    test('refuse une arrivée dans le passé', () {
      expect(
        DateRangeRules.valider(
          debut: d(10),
          fin: d(20),
          maintenant: maintenant,
        ),
        isNotNull,
      );
    });

    test('accepte une arrivée le jour même', () {
      expect(
        DateRangeRules.valider(
          debut: d(15),
          fin: d(20),
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('refuse un départ antérieur ou égal à l\'arrivée', () {
      expect(
        DateRangeRules.valider(
          debut: d(20),
          fin: d(20),
          maintenant: maintenant,
        ),
        isNotNull,
      );
      expect(
        DateRangeRules.valider(
          debut: d(20),
          fin: d(18),
          maintenant: maintenant,
        ),
        isNotNull,
      );
    });

    test('refuse un séjour au-delà de la durée maximale', () {
      expect(
        DateRangeRules.valider(
          debut: DateTime(2026, 6, 20),
          fin: DateTime(2026, 12, 20),
          maintenant: maintenant,
        ),
        isNotNull,
      );
    });
  });
}
