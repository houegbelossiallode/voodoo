import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilitaire pour la personnalisation et la traduction des messages d'erreur d'authentification
class AuthErrorFormatter {
  /// Traduit et formate une exception d'authentification en un message clair et convivial en français
  static String format(dynamic error) {
    if (error == null) return 'Une erreur inconnue s\'est produite.';

    final rawMessage = error.toString();
    final lowerMessage = rawMessage.toLowerCase();

    // Identifiants incorrects
    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid_credentials') ||
        lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('wrong password') ||
        lowerMessage.contains('invalid_grant')) {
      return 'Email ou mot de passe incorrect. Veuillez vérifier vos identifiants.';
    }

    // Email déjà enregistré
    if (lowerMessage.contains('user already registered') ||
        lowerMessage.contains('already exists') ||
        lowerMessage.contains('user_already_exists') ||
        lowerMessage.contains('email_already_in_use') ||
        lowerMessage.contains('already registered')) {
      return 'Un compte existe déjà avec cette adresse email. Veuillez vous connecter.';
    }

    // Mot de passe faible
    if (lowerMessage.contains('password should be at least') ||
        lowerMessage.contains('weak_password') ||
        lowerMessage.contains('password_too_short')) {
      return 'Le mot de passe est trop court. Il doit contenir au moins 6 caractères.';
    }

    // Format d'email invalide
    if (lowerMessage.contains('invalid email') ||
        lowerMessage.contains('invalid_email') ||
        lowerMessage.contains('unable to validate email')) {
      return 'Format d\'adresse email invalide.';
    }

    // Boîte mail non confirmée
    if (lowerMessage.contains('email not confirmed')) {
      return 'Veuillez vérifier votre boîte de réception pour confirmer votre compte.';
    }

    // Trop de tentatives
    if (lowerMessage.contains('too many requests') ||
        lowerMessage.contains('rate limit')) {
      return 'Nombreux essais détectés. Veuillez patienter un instant avant de réessayer.';
    }

    // Erreur réseau
    if (lowerMessage.contains('socketexception') ||
        lowerMessage.contains('clientexception') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('failed host lookup')) {
      return 'Connexion internet indisponible. Veuillez vérifier votre réseau.';
    }

    // Extraction propre du message Supabase si présent
    if (error is AuthException) {
      return error.message;
    }

    // Extraction du message des Exception personnalisées
    if (error is Exception) {
      final message = error.toString();
      // Si le message commence par "Exception: ", on l'extrait
      if (message.startsWith('Exception: ')) {
        return message.substring(11); // Enlève "Exception: "
      }
      return message;
    }

    return 'Une erreur s\'est produite lors de la connexion. Veuillez réessayer.';
  }
}
