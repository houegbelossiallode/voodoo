import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/error/app_failure.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Tests du mapping d'erreurs.
///
/// Objectif de sécurité (VUL-17) : **aucun détail technique** — nom de table,
/// code PostgREST, hôte, trace — ne doit se retrouver dans un message affiché
/// à l'utilisateur. Le dernier test de ce fichier est le garde-fou.
void main() {
  group('ErrorMapper.toMessage — classification', () {
    test('absence de réseau', () {
      final msg = ErrorMapper.toMessage(
        const SocketException(
          'Failed host lookup: vbfgfbqgtattrajdmeit.supabase.co',
        ),
      );
      expect(msg, const NetworkFailure().message);
      expect(msg, isNot(contains('supabase')));
    });

    test('délai dépassé', () {
      expect(
        ErrorMapper.toMessage(TimeoutException('timeout')),
        const NetworkFailure().message,
      );
    });

    test('violation de contrainte d\'unicité', () {
      final msg = ErrorMapper.toMessage(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );
      expect(msg, contains('existe déjà'));
    });

    test('violation de contrainte d\'exclusion — dates déjà réservées', () {
      // C'est la contrainte no_overlapping_reservations (VUL-13).
      final msg = ErrorMapper.toMessage(
        const PostgrestException(
          message:
              'conflicting key value violates exclusion constraint '
              '"no_overlapping_reservations"',
          code: '23P01',
        ),
      );
      expect(msg, contains('réservées'));
      expect(msg, isNot(contains('no_overlapping_reservations')));
    });

    test('refus RLS traité comme une session invalide', () {
      final msg = ErrorMapper.toMessage(
        const PostgrestException(
          message:
              'new row violates row-level security policy for table "comptes"',
          code: '42501',
        ),
      );
      expect(msg, const UnauthorizedFailure().message);
      expect(msg, isNot(contains('comptes')));
      expect(msg, isNot(contains('row-level')));
    });

    test('aucune ligne renvoyée par single()', () {
      expect(
        ErrorMapper.toMessage(
          const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        const NotFoundFailure().message,
      );
    });

    test('une AppFailure est renvoyée telle quelle', () {
      const f = ValidationFailure('Dates invalides.');
      expect(ErrorMapper.toMessage(f), 'Dates invalides.');
    });

    test('null donne un message générique', () {
      expect(ErrorMapper.toMessage(null), const ServerFailure().message);
    });

    test('erreur inconnue donne un message générique', () {
      expect(ErrorMapper.toMessage(Object()), const ServerFailure().message);
    });
  });

  group('ErrorMapper — non-divulgation (VUL-17)', () {
    /// Fragments qui ne doivent jamais atteindre l'écran.
    const interdits = [
      'supabase',
      'postgrest',
      'pgrst',
      'row-level',
      'rls',
      'relation',
      'column',
      'constraint',
      'stacktrace',
      'exception:',
      'select',
      'insert into',
      'public.',
      'comptes',
      'reservations',
      'revenu_plateformes',
      'auth.uid',
      'localhost',
      '.supabase.co',
    ];

    /// Erreurs réalistes telles que Supabase peut les renvoyer.
    final erreurs = <Object>[
      const PostgrestException(
        message: 'permission denied for table revenu_plateformes',
        code: '42501',
      ),
      const PostgrestException(
        message: 'relation "public.comptes" does not exist',
        code: '42P01',
      ),
      const PostgrestException(
        message: 'null value in column "montant" of relation "reservations"',
        code: '23502',
      ),
      const PostgrestException(
        message:
            'insert or update on table "contributions" violates foreign key',
        code: '23503',
      ),
      const SocketException(
        'Failed host lookup: vbfgfbqgtattrajdmeit.supabase.co',
      ),
      Exception(
        'Erreur lors de la récupération: PostgrestException(message: '
        'permission denied for table users, code: 42501)',
      ),
      StateError('Bad state: no element in public.logements'),
    ];

    test('aucun message ne divulgue de détail technique', () {
      for (final e in erreurs) {
        final msg = ErrorMapper.toMessage(e).toLowerCase();

        for (final mot in interdits) {
          expect(
            msg.contains(mot),
            isFalse,
            reason:
                'Le message « $msg » divulgue « $mot » '
                '(source : ${e.runtimeType})',
          );
        }
      }
    });

    test('tout message est non vide et rédigé en français', () {
      for (final e in erreurs) {
        final msg = ErrorMapper.toMessage(e);
        expect(msg.trim(), isNotEmpty);
        expect(msg.length, greaterThan(10));
        // Un message utile se termine par une ponctuation.
        expect(msg.trim(), endsWith('.'));
      }
    });
  });
}
