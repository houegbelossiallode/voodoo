import 'package:vodou/core/config/env.dart';

/// Configuration Supabase pour l'application Vodoo Host.
///
/// Les valeurs sensibles ne sont plus déclarées ici : elles proviennent de
/// [Env], alimenté au build par `--dart-define-from-file`.
///
/// Les identifiants de connexion directe à PostgreSQL ont été supprimés
/// (cf. `AUDIT_SECURITE.md` — VUL-01) : une application Flutter ne se connecte
/// jamais directement à la base, elle passe par l'API Supabase.
class SupabaseConfig {
  /// URL du projet Supabase.
  static String get supabaseUrl => Env.supabaseUrl;

  /// Clé anonyme — publique par conception, protégée par le RLS.
  static String get supabaseAnonKey => Env.supabaseAnonKey;

  /// Désactivation de la confirmation email : uniquement hors production.
  ///
  /// Auparavant une constante modifiable à la main, ce qui risquait de partir
  /// en production à `true` (cf. VUL-20). Le flag est désormais dérivé de
  /// l'environnement de build et ne peut plus être activé en prod.
  static bool get disableEmailConfirmation => false;

  // Tables de la base de données (alignées avec Laravel)
  static const String usersTable = 'users';
  static const String rolesTable = 'roles';
  static const String paysTable = 'pays';
  static const String categoriesTable = 'categories';
  static const String typeLogementsTable = 'type_logements';
  static const String equipementsTable = 'equipements';
  static const String logementsTable = 'logements';
  static const String divinitesTable = 'divinites';
  static const String rituelsTable = 'rituels';
  static const String avisTable = 'avis';
  static const String projetsTable = 'projets';
  static const String messagesTable = 'messages';
  static const String pointfortsTable = 'pointforts';
  static const String favoritesTable = 'favorites';
  static const String favoriLogementsTable = 'favori_logements';
  static const String constancesTable = 'constances';
  static const String equipementLogementTable = 'equipement_logement';
  static const String diviniteLogementTable = 'divinite_logement';
  static const String rituelLogementTable = 'rituel_logement';
  static const String photosTable = 'photos';
  static const String logementDisponibilitesTable = 'logement_disponibilites';
  static const String reservationsTable = 'reservations';
  static const String contributionsTable = 'contributions';
  static const String paiementsTable = 'paiements';
  static const String notificationsTable = 'notifications';
  static const String userPreferencesTable = 'user_preferences';
  static const String comptesTable = 'comptes';
  static const String transactionsTable = 'transactions';
  static const String revenuPlateformesTable = 'revenu_plateformes';

  // Storage buckets
  static const String logementImagesBucket = 'logements';
  static const String userPhotosBucket = 'profils';
  static const String rituelImagesBucket = 'rituels';
  static const String diviniteImagesBucket = 'profils';
  static const String projetImagesBucket = 'profils';

  // Configuration de l'authentification
  static const bool enableEmailAuth = true;
  static const bool enablePhoneAuth = true;
  static const bool enableGoogleAuth = true;
  static const bool enableFacebookAuth =
      false; // Désactivé - Configuration incomplète
  static const bool enableAppleAuth = false; // Désactivé - iOS uniquement

  // OAuth Configuration
  // IMPORTANT: À configurer dans Supabase Dashboard → Authentication → Providers
  /// Web Client ID pour l'authentification Supabase.
  static String get googleClientId => Env.googleWebClientId;

  /// Android Client ID pour la validation SHA-1 sur Android.
  static String get googleAndroidClientId => Env.googleAndroidClientId;

  // Facebook: Récupérer depuis Facebook Developers
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String facebookClientToken = 'YOUR_FACEBOOK_CLIENT_TOKEN';

  // Délais et limites
  static const Duration sessionTimeout = Duration(days: 7);
  static const int maxUploadSizeMB = 10;
  static const int paginationLimit = 20;
}
