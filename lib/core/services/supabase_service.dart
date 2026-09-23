import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/secure_local_storage.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Service singleton pour gérer la connexion Supabase
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static SecureLocalStorage? _localStorage;

  /// Clé de persistance de session.
  ///
  /// Reproduit la convention de `supabase_flutter`
  /// (`sb-<sous-domaine>-auth-token`) afin que les sessions déjà écrites en
  /// clair par l'ancienne implémentation soient reconnues et migrées.
  static String get _persistSessionKey =>
      'sb-${Uri.parse(SupabaseConfig.supabaseUrl).host.split('.').first}-auth-token';

  /// Initialise Supabase.
  ///
  /// La session est persistée dans le **stockage chiffré** du système
  /// (Keystore / Keychain) et non plus dans `SharedPreferences` — VUL-10.
  static Future<void> initialize() async {
    _localStorage = SecureLocalStorage(persistSessionKey: _persistSessionKey);

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      // PKCE plutôt qu'implicit : le jeton d'accès ne transite plus dans
      // l'URL de redirection, qui peut être interceptée par une application
      // tierce déclarant le même schéma. Cf. AUDIT_SECURITE.md — VUL-06.
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        localStorage: _localStorage,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(retryAttempts: 3),
    );
    _client = Supabase.instance.client;

    // Vérifier si une session existe. L'e-mail n'est pas journalisé (VUL-08).
    AppLogger.d('Initialisation Supabase terminée', {
      'sessionActive': _client?.auth.currentSession != null,
    });
  }

  /// Récupère le client Supabase
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase n\'a pas été initialisé. Appelez SupabaseService.initialize() d\'abord.',
      );
    }
    return _client!;
  }

  /// Récupère l'utilisateur actuellement connecté
  User? get currentUser => _client?.auth.currentUser;

  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Récupère le token d'authentification
  Future<String?> get authToken async {
    final session = _client?.auth.currentSession;
    return session?.accessToken;
  }

  /// Stream des changements d'état d'authentification
  Stream<AuthState> get authStateChanges {
    return _client!.auth.onAuthStateChange;
  }

  /// Déconnexion.
  ///
  /// Purge également le stockage chiffré : après un `signOut`, aucun jeton ne
  /// doit subsister sur l'appareil (VUL-10, §6.2 du guide).
  Future<void> signOut() async {
    await _client?.auth.signOut();
    await _localStorage?.purgeAll();
  }
}
