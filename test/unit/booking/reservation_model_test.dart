import 'package:flutter_test/flutter_test.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';

/// Tests du mapper `Reservation.fromJson`.
///
/// Les mappers sont le point de contact entre la base et l'application : un
/// changement de schéma côté Supabase s'y manifeste d'abord. Ces tests
/// documentent ce que le modèle tolère et ce qu'il refuse.
void main() {
  /// Réponse Supabase minimale, telle que renvoyée par la table `reservations`.
  Map<String, dynamic> payload({Map<String, dynamic> overrides = const {}}) => {
    'id': 42,
    'logement_id': 7,
    'user_id': 3,
    'date_debut': '2026-06-01',
    'date_fin': '2026-06-05',
    'montant': 60000,
    'nb_nuits': 4,
    'nb_voyageurs': 2,
    'mode_paiement': 'kkiapay',
    'reference': 'TX-12345',
    'projet_id': null,
    'statut': 'PAYE',
    'created_at': '2026-05-20T10:30:00.000Z',
    'updated_at': null,
    ...overrides,
  };

  group('Reservation.fromJson', () {
    test('convertit une réponse complète', () {
      final r = Reservation.fromJson(payload());

      expect(r.id, '42');
      expect(r.logementId, '7');
      expect(r.userId, '3');
      expect(r.dateDebut, DateTime(2026, 6, 1));
      expect(r.dateFin, DateTime(2026, 6, 5));
      expect(r.montant, 60000.0);
      expect(r.nbNuits, 4);
      expect(r.nbVoyageurs, 2);
      expect(r.modePaiement, 'kkiapay');
      expect(r.reference, 'TX-12345');
      expect(r.statut, 'PAYE');
      expect(r.updatedAt, isNull);
    });

    test('normalise les identifiants numériques en chaînes', () {
      // Les identifiants sont des int en base mais des String dans le modèle.
      final r = Reservation.fromJson(payload());
      expect(r.id, isA<String>());
      expect(r.logementId, isA<String>());
    });

    test('accepte un montant entier comme décimal', () {
      expect(Reservation.fromJson(payload()).montant, 60000.0);
      expect(
        Reservation.fromJson(payload(overrides: {'montant': 60000.5})).montant,
        60000.5,
      );
    });

    test('accepte les champs optionnels absents', () {
      final r = Reservation.fromJson(
        payload(
          overrides: {
            'mode_paiement': null,
            'reference': null,
            'projet_id': null,
          },
        ),
      );

      expect(r.modePaiement, isNull);
      expect(r.reference, isNull);
      expect(r.projetId, isNull);
    });

    test('convertit projet_id quand il est présent', () {
      final r = Reservation.fromJson(payload(overrides: {'projet_id': 9}));
      expect(r.projetId, '9');
    });

    test('lit updated_at quand il est renseigné', () {
      final r = Reservation.fromJson(
        payload(overrides: {'updated_at': '2026-05-21T08:00:00.000Z'}),
      );
      expect(r.updatedAt, isNotNull);
    });

    test('échoue explicitement si une date obligatoire est absente', () {
      // Mieux vaut une exception au mapping qu'une valeur par défaut
      // silencieuse qui fausserait un calcul de séjour.
      final incomplet = payload()..remove('date_debut');
      expect(() => Reservation.fromJson(incomplet), throwsA(anything));
    });

    test('échoue explicitement si le montant est absent', () {
      final incomplet = payload()..remove('montant');
      expect(() => Reservation.fromJson(incomplet), throwsA(anything));
    });

    test('le nombre de nuits est cohérent avec les dates', () {
      final r = Reservation.fromJson(payload());
      expect(r.dateFin.difference(r.dateDebut).inDays, r.nbNuits);
    });
  });
}
