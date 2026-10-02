import 'package:flutter/services.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Service pour gérer les deep links, notamment pour la récupération de mot de passe
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.example.vodou/deeplink');
  
  static bool _isInitialized = false;
  
  /// Initialise le service pour écouter les deep links
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    
    AppLogger.d('🔗 DeepLinkService initialisé');
  }
  
  /// Traite les appels de méthode depuis le natif
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    AppLogger.d('🔗 Méthode reçue: ${call.method}');
    
    if (call.method == 'onNewIntent') {
      final String? deepLink = call.arguments as String?;
      if (deepLink != null) {
        AppLogger.d('🔗 Deep link reçu: $deepLink');
        return _processDeepLink(deepLink);
      }
    }
    
    return null;
  }
  
  /// Traite un deep link pour détecter si c'est un lien de récupération de mot de passe
  static Future<String?> _processDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      
      // Avec PKCE, les liens de récupération contiennent des paramètres comme :
      // - code (le code d'autorisation)
      // - code_verifier (le verify code)
 AppLogger.d('🔗 Paramètres du deep link: ${uri.queryParameters.keys}');
      
      // Vérifier si c'est un lien de récupération de mot de passe
      // Supabase utilise différents paramètres selon le flow
      if (uri.queryParameters.containsKey('code') || 
          uri.queryParameters.containsKey('access_token') ||
          uri.queryParameters.containsKey('token') ||
          uri.queryParameters.containsKey('type')) {
        
        final type = uri.queryParameters['type'];
        AppLogger.d('🔗 Type de lien détecté: $type');
        
        // Si c'est un lien de récupération de mot de passe
        if (type == 'recovery' || 
            uri.queryParameters.containsKey('code') ||
            uri.path.contains('recovery')) {
          AppLogger.d('🔑 Lien de récupération de mot de passe détecté');
          return 'password_recovery';
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.e('❌ Erreur lors du traitement du deep link: $e');
      return null;
    }
  }
  
  /// Vérifie si l'URL actuelle contient des paramètres de récupération
  static bool isPasswordRecoveryLink(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Vérifier les paramètres typiques de récupération avec PKCE
      return uri.queryParameters.containsKey('code') ||
             uri.queryParameters.containsKey('type') == 'recovery' ||
             uri.path.contains('recovery');
    } catch (e) {
      return false;
    }
  }
}
