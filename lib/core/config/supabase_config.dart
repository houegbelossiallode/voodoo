/// Configuration Supabase pour l'application Vodoo Host
class SupabaseConfig {
  // URL et clé Supabase
  // IMPORTANT: Ces valeurs doivent être récupérées depuis la console Supabase
  // https://app.supabase.com/project/YOUR_PROJECT/settings/api

  static const String supabaseUrl = 'https://vbfgfbqgtattrajdmeit.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZiZmdmYnFndGF0dHJhamRtZWl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4Mzc4ODMsImV4cCI6MjA3ODQxMzg4M30.jbuLAOM0F4k_PPrqrOEUN_QeAHvz_OaMa6MvyNPQwEo';

  // Configuration de la base de données PostgreSQL
  // Ces informations sont utilisées pour la connexion directe si nécessaire
  static const String dbHost = 'aws-0-eu-west-2.pooler.supabase.com';
  static const int dbPort = 6543;
  static const String dbName = 'postgres';
  static const String dbUsername = 'postgres.vbfgfbqgtattrajdmeit';
  static const String dbPassword = '0HJte9fxqSeYzHOG';

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
  static const String logementImagesBucket = 'logement-images';
  static const String userPhotosBucket = 'user-photos';
  static const String rituelImagesBucket = 'rituel-images';
  static const String diviniteImagesBucket = 'divinite-images';
  static const String projetImagesBucket = 'projet-images';

  // Configuration de l'authentification
  static const bool enableEmailAuth = true;
  static const bool enablePhoneAuth = true;
  static const bool enableGoogleAuth = true;
  static const bool enableFacebookAuth =
      false; // Désactivé - Configuration incomplète
  static const bool enableAppleAuth = false; // Désactivé - iOS uniquement

  // OAuth Configuration
  // IMPORTANT: À configurer dans Supabase Dashboard → Authentication → Providers
  // Google: Récupérer depuis Google Cloud Console
  // Web Client ID pour l'authentification Supabase
  static const String googleClientId =
      '563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf.apps.googleusercontent.com';

  // Android Client ID pour la validation SHA-1 sur Android
  static const String googleAndroidClientId =
      '563099795585-t6toaj2erv817l9hho0lrhivivq6g18p.apps.googleusercontent.com';

  // Facebook: Récupérer depuis Facebook Developers
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String facebookClientToken = 'YOUR_FACEBOOK_CLIENT_TOKEN';

  // Délais et limites
  static const Duration sessionTimeout = Duration(days: 7);
  static const int maxUploadSizeMB = 10;
  static const int paginationLimit = 20;
}
