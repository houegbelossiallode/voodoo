import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/favorites/domain/models/favorite.dart';
import 'package:vodou/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/home/presentation/pages/main_page.dart';

/// Page de détail d'une liste de favoris
class FavoriteListDetailPage extends ConsumerWidget {
  final Favorite favoriteList;

  const FavoriteListDetailPage({super.key, required this.favoriteList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logementsAsync = ref.watch(
      favoriteListLogementsProvider(favoriteList.id),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: favoriteList.libelle,
        actions: [
          // Bouton partager
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareList(context, ref),
          ),
          // Menu options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameList(context, ref);
                  break;
                case 'delete':
                  _deleteList(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Renommer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Supprimer', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: logementsAsync.when(
        data: (logements) {
          if (logements.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(favoriteListLogementsProvider(favoriteList.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(context, ref),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteListLogementsProvider(favoriteList.id));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logements.length,
              itemBuilder: (context, index) {
                return _buildLogementCard(context, logements[index], ref);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(
                    favoriteListLogementsProvider(favoriteList.id),
                  );
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Liste vide',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des logements à cette liste',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              context.go(AppRouter.home);
            },
            icon: const Icon(Icons.search),
            label: const Text('Explorer les logements'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogementCard(
    BuildContext context,
    Logement logement,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: logement.firstPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(logement.firstPhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logement.firstPhotoUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: AppColors.grey,
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: () => _removeLogement(context, ref, logement),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logement.titre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (logement.adresse != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          logement.adresse!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (logement.nbVoyageurMax != null) ...[
                      const Icon(Icons.people_outline, size: 16),
                      const SizedBox(width: 4),
                      Text('${logement.nbVoyageurMax} voyageurs'),
                      const SizedBox(width: 16),
                    ],
                    if (logement.nbChambre != null) ...[
                      const Icon(Icons.bed_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text('${logement.nbChambre} chambres'),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text:
                                '${logement.prixParNuit.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(
                            text: ' / nuit',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Naviguer vers la page de détails du logement
                        // Utilise GoRouter pour conserver le routage centralisé
                        context.go(
                          AppRouter.accommodationDetails.replaceFirst(
                            ':id',
                            logement.id.toString(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Voir détails →'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeLogement(
    BuildContext context,
    WidgetRef ref,
    Logement logement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer des favoris'),
        content: Text(
          'Voulez-vous retirer "${logement.titre}" de cette liste ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(favoriteRepositoryProvider)
            .removeLogementFromFavorite(favoriteList.id, logement.id);

        // Vérifier si le logement est dans d'autres listes
        final repository = ref.read(favoriteRepositoryProvider);
        final user = ref.read(currentUserProvider).value;
        if (user != null) {
          final listsContaining = await repository
              .getFavoriteListsContainingLogement(user.id, logement.id);

          // Si le logement n'est plus dans aucune liste, le retirer de l'état
          if (listsContaining.isEmpty) {
            ref
                .read(favoriteNotifierProvider.notifier)
                .removeFromState(logement.id);
          }
        }

        ref.invalidate(favoriteListLogementsProvider(favoriteList.id));
        ref.invalidate(favoriteLogementsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logement retiré de la liste'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _shareList(BuildContext context, WidgetRef ref) async {
    try {
      final link = await ref
          .read(favoriteRepositoryProvider)
          .generateShareLink(favoriteList.id);

      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien copié dans le presse-papiers'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _renameList(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: favoriteList.libelle);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la liste'),
        content: TextField(
          controller: controller,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Nom de la liste',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    if (newName != null && newName != favoriteList.libelle && context.mounted) {
      try {
        await ref
            .read(favoriteRepositoryProvider)
            .renameFavoriteList(favoriteList.id, newName);

        ref.invalidate(favoriteListsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liste renommée'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(); // Retour à la liste des favoris
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteList(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la liste'),
        content: Text(
          'Voulez-vous vraiment supprimer la liste "${favoriteList.libelle}" ? '
          'Tous les logements de cette liste seront retirés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(favoriteRepositoryProvider)
            .deleteFavoriteList(favoriteList.id);

        ref.invalidate(favoriteListsProvider);
        ref.read(favoriteNotifierProvider.notifier).refresh();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liste supprimée'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(); // Retour à la liste des favoris
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
