import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/features/auth/domain/models/role.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';

/// Provider pour récupérer les rôles actifs
final rolesProvider = FutureProvider<List<Role>>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getActiveRoles();
});

/// Provider pour le rôle sélectionné lors de l'inscription
final selectedRoleProvider = StateProvider<Role?>((ref) => null);
