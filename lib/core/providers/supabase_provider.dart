import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/services/supabase_service.dart';

/// Provider pour le client Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.instance.client;
});

/// Provider pour l'utilisateur actuel
final currentUserProvider = StateProvider<User?>((ref) {
  return SupabaseService.instance.currentUser;
});

/// Provider pour l'état d'authentification
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.instance.authStateChanges;
});

/// Provider pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
