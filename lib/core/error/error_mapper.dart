import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/error/app_failure.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/utils/auth_error_formatter.dart';

/// Traduit n'importe quelle erreur technique en [AppFailure] affichable.
///
/// Point d'entrée unique pour tout ce qui remonte à l'écran. L'objectif est
/// qu'aucun nom de table, code PostgREST, hôte ou trace d'exécution ne
/// parvienne jamais à l'utilisateur (cf. `AUDIT_SECURITE.md` — VUL-17) :
/// ces informations décrivent la structure interne du système et facilitent
/// la tâche d'un attaquant.
///
/// ```dart
/// try {
///   await repository.charger();
/// } catch (e, s) {
///   throw ErrorMapper.map(e, s, context: 'chargement des logements');
/// }
/// ```
abstract final class ErrorMapper {
  const ErrorMapper._();

  /// Convertit [error] en [AppFailure] et journalise le détail brut.
  ///
  /// [context] décrit l'opération en cours ; il n'apparaît que dans les logs.
  static AppFailure map(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final failure = _classify(error);

    // Le détail complet reste dans les logs, jamais à l'écran.
    AppLogger.e(
      context == null ? 'Échec' : 'Échec — $context',
      error,
      stackTrace,
    );

    return failure;
  }

  /// Message utilisateur pour une erreur déjà interceptée ailleurs.
  ///
  /// À utiliser dans les widgets, notamment sur la branche `error` d'un
  /// `AsyncValue`, où l'erreur n'est pas levée mais reçue.
  static String toMessage(Object? error) {
    if (error == null) return const ServerFailure().message;
    if (error is AppFailure) return error.message;
    return _classify(error).message;
  }

  // ---------------------------------------------------------------------------

  static AppFailure _classify(Object error) {
    // Déjà traduit en amont
    if (error is AppFailure) return error;

    // --- Réseau -------------------------------------------------------------
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return const NetworkFailure();
    }

    // --- Authentification ---------------------------------------------------
    if (error is AuthException) {
      // AuthErrorFormatter produit déjà des messages en français, sans détail
      // technique, pour les cas d'authentification courants.
      return ValidationFailure(AuthErrorFormatter.format(error));
    }

    // --- PostgREST ----------------------------------------------------------
    if (error is PostgrestException) {
      return _fromPostgrest(error);
    }

    // --- Storage ------------------------------------------------------------
    if (error is StorageException) {
      final status = int.tryParse(error.statusCode ?? '');
      if (status == 404) return const NotFoundFailure('Fichier introuvable.');
      if (status == 401 || status == 403) return const UnauthorizedFailure();
      if (status == 413) {
        return const ValidationFailure('Fichier trop volumineux.');
      }
      return const ServerFailure('Le transfert du fichier a échoué.');
    }

    // --- Fonctions Edge -----------------------------------------------------
    if (error is FunctionException) {
      final data = error.details;
      // L'Edge Function renvoie un message déjà rédigé pour l'utilisateur.
      if (data is Map && data['error'] is String) {
        final msg = data['error'] as String;
        if (error.status == 402) return PaymentFailure(msg);
        if (error.status == 409) return ConflictFailure(msg);
        if (error.status == 401 || error.status == 403) {
          return const UnauthorizedFailure();
        }
        return ValidationFailure(msg);
      }
      return const ServerFailure();
    }

    // --- Repli : ne jamais renvoyer error.toString() ------------------------
    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') ||
        raw.contains('network') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection')) {
      return const NetworkFailure();
    }
    if (raw.contains('jwt') ||
        raw.contains('expired') ||
        raw.contains('unauthorized')) {
      return const UnauthorizedFailure();
    }

    return const ServerFailure();
  }

  static AppFailure _fromPostgrest(PostgrestException e) {
    // Codes SQLSTATE : https://www.postgresql.org/docs/current/errcodes-appendix.html
    switch (e.code) {
      case '23505': // unique_violation
        return const ConflictFailure('Cet élément existe déjà.');
      case '23514': // check_violation
      case '23P01': // exclusion_violation — contrainte anti-double-réservation
        return const ConflictFailure(
          'Ces dates viennent d\'être réservées. Choisissez une autre période.',
        );
      case '23503': // foreign_key_violation
        return const ValidationFailure(
          'Opération impossible : un élément lié est manquant.',
        );
      case '42501': // insufficient_privilege — RLS
      case 'PGRST301':
        return const UnauthorizedFailure();
      case 'PGRST116': // aucune ligne renvoyée par .single()
        return const NotFoundFailure();
    }

    final status = int.tryParse(e.code ?? '');
    if (status == 401 || status == 403) return const UnauthorizedFailure();
    if (status == 404) return const NotFoundFailure();

    return const ServerFailure();
  }
}
