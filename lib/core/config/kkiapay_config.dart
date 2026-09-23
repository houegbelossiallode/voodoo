import 'package:vodou/core/config/env.dart';

/// Configuration KKiaPay pour les paiements.
///
/// ⚠️ Seule la clé **publique** figure côté application. La clé privée, qui
/// permet de vérifier le statut réel d'une transaction, doit rester côté
/// serveur (Edge Function Supabase) — cf. `AUDIT_SECURITE.md`, VUL-02.
class KKiaPayConfig {
  // -----------------------------
  // 🔑 Clé KKiaPay (UNIQUEMENT PUBLIC KEY)
  // -----------------------------

  /// Clé publique, injectée au build via `--dart-define-from-file`.
  static String get publicKey => Env.kkiapayPublicKey;

  /// `true` en production, `false` (sandbox) partout ailleurs.
  ///
  /// Dérivé de l'environnement de build : plus de constante à basculer
  /// manuellement avant une release.
  static bool get isLive => Env.kkiapayIsLive;

  // -----------------------------
  // 🔧 Configuration générale
  // -----------------------------

  /// Devise (KKIAPAY accepte seulement XOF / GNF / NGN)
  static const String currency = 'XOF';

  /// Montant minimum
  static const double minAmount = 100;

  /// Montant maximum autorisé par KKiaPay (10 Millions XOF)
  static const double maxAmount = 10000000;

  // -----------------------------
  // 💳 Méthodes de paiement (facultatif)
  // -----------------------------
  // static const List<String> paymentMethods = ['mtn', 'moov', 'card'];

  // static const Map<String, String> paymentMethodNames = {
  //   'mtn': 'MTN Mobile Money',
  //   'moov': 'Moov Money',
  //   'card': 'Carte bancaire',
  // };

  static const List<String> paymentMethods = [
    'mtn',
    'moov',
    'card',
    'celtis', // Celtis Money (exemple)
    'wave', // Wave (SI supporté)
    'airtel', // Airtel Money (SI supporté)
    'om', // Orange Money (SI supporté)
  ];

  static const Map<String, String> paymentMethodNames = {
    'mtn': 'MTN Mobile Money',
    'moov': 'Moov Money',
    'card': 'Carte bancaire',
    'celtis': 'Celtis Money',
    'wave': 'Wave',
    'airtel': 'Airtel Money',
    'om': 'Orange Money',
  };
}
