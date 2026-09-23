import 'package:flutter/foundation.dart';

/// Journalisation applicative.
///
/// Remplace les appels directs à `print()`, qui écrivent dans logcat en
/// production — un canal lisible par d'autres applications sur appareil rooté
/// et systématiquement capté par les outils de crash reporting
/// (cf. `AUDIT_SECURITE.md` — VUL-08).
///
/// ## Règle d'usage
///
/// Ne jamais journaliser : clé d'API, jeton, mot de passe, e-mail, numéro de
/// téléphone, montant de transaction, `user_metadata`. En cas de doute, ne pas
/// journaliser — ou n'inscrire qu'un identifiant technique.
///
/// ```dart
/// AppLogger.d('Réservation créée', {'id': reservation.id});   // ✅
/// AppLogger.d('Paiement', {'email': user.email});             // ❌
/// ```
///
/// En release, seuls [w] et [e] produisent une sortie ; [d] et [i] sont
/// compilés hors du binaire par le `tree shaking` grâce à [kDebugMode].
abstract final class AppLogger {
  const AppLogger._();

  /// Débogage — visible uniquement en debug.
  static void d(String message, [Object? context]) {
    if (kDebugMode) {
      debugPrint('🔹 $message${_fmt(context)}');
    }
  }

  /// Information — visible uniquement en debug.
  static void i(String message, [Object? context]) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message${_fmt(context)}');
    }
  }

  /// Avertissement — conservé en release.
  static void w(String message, [Object? context]) {
    debugPrint('⚠️ $message${_fmt(context)}');
  }

  /// Erreur — conservée en release.
  ///
  /// [error] et [stackTrace] sont destinés à être transmis au crash reporting
  /// (Sentry / Crashlytics) une fois celui-ci en place.
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ $message${error != null ? ' — $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static String _fmt(Object? context) => context == null ? '' : ' $context';
}
