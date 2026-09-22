import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';

/// Page qui gère le callback de confirmation email depuis Supabase
/// Cette page est appelée via deep link: vodoohost://auth/callback
class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processAuthCallback();
  }

  Future<void> _processAuthCallback() async {
    try {
      // Supabase Flutter SDK gère automatiquement les tokens dans l'URL
      // Nous devons juste vérifier si la session est active
      final supabase = SupabaseService.instance;
      
      // Attendre que Supabase traite le deep link et crée la session
      // On essaie plusieurs fois car le traitement peut prendre du temps
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final session = supabase.client.auth.currentSession;
        
        if (session != null) {
          print('✅ Session détectée après ${i + 1} essai(s)');
          print('   Email: ${session.user.email}');
          print('   Email confirmé: ${session.user.emailConfirmedAt != null}');
          
          if (session.user.emailConfirmedAt != null) {
            // Rafraîchir l'utilisateur pour créer le profil si nécessaire
            await ref.read(currentUserProvider.notifier).refresh();
            
            if (mounted) {
              // Rediriger vers la page d'accueil
              context.go(AppRouter.home);
            }
            return;
          }
        }
      }
      
      // Si après 5 secondes toujours pas de session
      print('⚠️ Aucune session détectée après 5 secondes');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Email non confirmé ou session expirée. Veuillez réessayer.';
        });
      }
    } catch (e) {
      print('❌ Erreur lors du traitement du callback: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Erreur: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isProcessing
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Text(
                        'Confirmation de votre email...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez patienter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _errorMessage != null
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 64,
                        color: _errorMessage != null
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage ?? 'Email confirmé avec succès !',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          context.go(AppRouter.login);
                        },
                        child: const Text('Aller à la connexion'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
