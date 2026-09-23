/// Configuration d'environnement de l'application.
///
/// Les valeurs sont injectées au build via `--dart-define-from-file` :
///
/// ```bash
/// flutter run   --dart-define-from-file=env/dev.json
/// flutter build appbundle --release \
///   --dart-define-from-file=env/prod.json \
///   --obfuscate --split-debug-info=build/symbols
/// ```
///
/// ## Ce qui peut figurer ici
///
/// Uniquement des valeurs **publiques par conception** : l'URL du projet
/// Supabase, la clé `anon` (dont la sécurité repose entièrement sur le RLS)
/// et la clé *publique* KKiaPay. Tout ce qui est compilé dans l'APK est
/// lisible : `unzip` + `strings` suffisent.
///
/// ## Ce qui ne doit JAMAIS y figurer
///
/// Mot de passe PostgreSQL, clé `service_role` Supabase, clé privée KKiaPay,
/// secret OAuth. Ces valeurs vivent côté serveur (variables d'environnement
/// des Edge Functions).
///
/// Voir `AUDIT_SECURITE.md` — VUL-01.
abstract final class Env {
  const Env._();

  /// URL du projet Supabase.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vbfgfbqgtattrajdmeit.supabase.co',
  );

  /// Clé anonyme Supabase — publique par conception, protégée par le RLS.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZiZmdmYnFndGF0dHJhamRtZWl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4Mzc4ODMsImV4cCI6MjA3ODQxMzg4M30.jbuLAOM0F4k_PPrqrOEUN_QeAHvz_OaMa6MvyNPQwEo',
  );

  /// Clé publique KKiaPay (widget de paiement).
  static const String kkiapayPublicKey = String.fromEnvironment(
    'KKIAPAY_PUBLIC_KEY',
    defaultValue: '2fd08370652e11efbf02478c5adba4b8',
  );

  /// Client ID Google (web) utilisé pour l'authentification Supabase.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1039090276025-nunhis6i7o5n0sqooao4idt7kpdmmrm9.apps.googleusercontent.com',
  );

  /// Client ID Google (Android) utilisé pour la validation SHA-1.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '1039090276025-bl2b33f8f9f6k6e6j9ckrp69fttpd5ct.apps.googleusercontent.com',
  );

  /// Environnement courant : `dev`, `staging` ou `prod`.
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';

  /// Mode KKiaPay : sandbox partout sauf en production.
  static bool get kkiapayIsLive => isProd;

  /// Échoue au démarrage plutôt qu'au premier appel réseau.
  ///
  /// À appeler depuis `main()` avant toute initialisation de service.
  static void assertValid() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Configuration Supabase manquante. Lancez l\'application avec :\n'
        '  flutter run --dart-define-from-file=env/dev.json',
      );
    }
    if (kkiapayPublicKey.isEmpty) {
      throw StateError('KKIAPAY_PUBLIC_KEY manquante dans la configuration.');
    }
  }
}
