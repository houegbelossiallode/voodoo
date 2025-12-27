/// Configuration KKiaPay pour les paiements
class KKiaPayConfig {
  // -----------------------------
  // 🔑 Clés KKiaPay (UNIQUEMENT PUBLIC KEY)
  // -----------------------------

  /// ⚠️ Clé à utiliser dans l'app Flutter
  static const String publicKeySandbox = 'c7d7ae40d04f11f0ab1c99b320df21bd';
  static const String publicKeyLive =
      'ab96d73fbe041ae08a74e2887480f42bef757dc3';

  /// true = production / false = sandbox
  static const bool isLive = true;

  /// Retourne automatiquement la bonne clé selon le mode
  static String get publicKey => isLive ? publicKeyLive : publicKeySandbox;

  // -----------------------------
  // 🔧 Configuration générale
  // -----------------------------

  /// Devise (KKIAPAY accepte seulement XOF / GNF / NGN)
  static const String currency = 'XOF';

  /// Montant minimum
  static const double minAmount = 100;

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
