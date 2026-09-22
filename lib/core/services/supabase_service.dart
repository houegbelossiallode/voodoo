import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/config/supabase_config.dart';

/// Service singleton pour gérer la connexion Supabase
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialise Supabase
  /// La persistance de session est activée par défaut via le stockage local
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(retryAttempts: 3),
    );
    _client = Supabase.instance.client;

    // Vérifier si une session existe
    final session = _client?.auth.currentSession;
    if (session != null) {
      print('✅ Session restaurée pour: ${session.user.email}');
    } else {
      print('ℹ️ Aucune session active');
    }
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

  /// Déconnexion
  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
