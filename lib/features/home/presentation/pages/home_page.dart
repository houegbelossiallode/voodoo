import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/widgets/network_error_widget.dart';
import 'package:vodou/core/widgets/app_logo_widget.dart';
import 'package:vodou/features/home/presentation/providers/home_provider.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:vodou/features/favorites/presentation/widgets/favorite_list_dialog.dart';
import 'package:vodou/features/home/presentation/widgets/integrated_search_bar.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divinitesAsync = ref.watch(preferredDivinitesProvider);
    final filters = ref.watch(searchFiltersProvider);

    // Si des filtres sont actifs, utiliser les résultats de recherche
    // Sinon, utiliser les recommandations
    final logementsAsync = filters.hasFilters
        ? ref.watch(searchResultsProvider)
        : ref.watch(recommendedLogementsProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Rafraîchir les divinités et les logements
          ref.invalidate(preferredDivinitesProvider);
          if (filters.hasFilters) {
            ref.invalidate(searchResultsProvider);
          } else {
            ref.invalidate(recommendedLogementsProvider);
          }
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: InkWell(
                onTap: () {
                  context.go(AppRouter.festivalSelection);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vodun Days',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          Text(
                            'Ouidah, Bénin',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.festival_outlined),
                  tooltip: 'Changer de festival',
                  onPressed: () {
                    context.go(AppRouter.festivalSelection);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: AppLogoWidget(),
                ),
              ],
            ),

            // Banner de festival sélectionné avec bouton "Changer de festival"
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.festival,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Festival Vodun Days',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Ouidah, Bénin',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.go(AppRouter.festivalSelection);
                      },
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text(
                        'Changer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar intégrée avec filtres
            const SliverToBoxAdapter(child: IntegratedSearchBar()),

            // Categories
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Expériences culturelles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: divinitesAsync.when(
                      data: (divinites) {
                        if (divinites.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Aucune divinité disponible'),
                            ),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: divinites.length,
                          itemBuilder: (context, index) {
                            final divinite = divinites[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < divinites.length - 1 ? 12 : 0,
                              ),
                              child: _buildCategoryCard(
                                context,
                                ref,
                                divinite,
                                _getIconForDivinite(divinite.nom),
                                _getColorForDivinite(index),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => NetworkErrorWidget.fromError(
                        context: context,
                        error: error,
                        onRetry: () {
                          ref.invalidate(divinitesProvider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Featured Accommodations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        filters.hasFilters
                            ? 'Résultats de recherche (${filters.activeFiltersCount} filtre${filters.activeFiltersCount > 1 ? 's' : ''})'
                            : 'Logements recommandés',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Accommodation List
            logementsAsync.when(
              data: (logements) {
                if (logements.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Aucun logement disponible')),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildAccommodationCard(
                        context,
                        logements[index],
                        ref,
                      );
                    }, childCount: logements.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => NetworkErrorWidget.fromError(
                context: context,
                error: error,
                onRetry: () {
                  if (filters.hasFilters) {
                    ref.invalidate(searchResultsProvider);
                  } else {
                    ref.invalidate(recommendedLogementsProvider);
                  }
                },
                isSliver: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDivinite(String libelle) {
    final lowerLibelle = libelle.toLowerCase();
    if (lowerLibelle.contains('sakpata')) return Icons.healing;
    if (lowerLibelle.contains('mamiwata') || lowerLibelle.contains('mami')) {
      return Icons.water;
    }
    if (lowerLibelle.contains('legba')) return Icons.auto_awesome;
    if (lowerLibelle.contains('hevioso') || lowerLibelle.contains('xevioso')) {
      return Icons.flash_on;
    }
    if (lowerLibelle.contains('dan')) return Icons.waves;
    if (lowerLibelle.contains('gu')) return Icons.hardware;
    return Icons.stars;
  }

  Color _getColorForDivinite(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.warning,
      AppColors.success,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    Divinite divinite,
    IconData icon,
    Color color,
  ) {
    final filters = ref.watch(searchFiltersProvider);
    final isSelected = filters.divinites.contains(divinite.id);

    return InkWell(
      onTap: () {
        final filtersNotifier = ref.read(searchFiltersProvider.notifier);
        if (isSelected) {
          // Retirer le filtre
          filtersNotifier.removeDivinite(divinite.id);
        } else {
          // Ajouter le filtre
          filtersNotifier.addDivinite(divinite.id);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 8),
            Text(
              divinite.nom,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccommodationCard(
    BuildContext context,
    Logement logement,
    WidgetRef ref,
  ) {
    final favoriteNotifier = ref.watch(favoriteNotifierProvider.notifier);
    final isFavorite = ref
        .watch(favoriteNotifierProvider)
        .contains(logement.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/accommodation/${logement.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
              child: Stack(
                children: [
                  if (logement.firstPhotoUrl == null)
                    const Center(
                      child: Icon(Icons.image, size: 64, color: AppColors.grey),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        // Afficher le dialog de sélection de liste
                        showDialog(
                          context: context,
                          builder: (context) => FavoriteListDialog(
                            logementId: logement.id,
                            logementTitre: logement.titre,
                          ),
                        ).then((_) {
                          // Rafraîchir l'état des favoris après fermeture du dialog
                          favoriteNotifier.refresh();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppColors.favorite.withValues(alpha: 0.9)
                              : AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_outline,
                          color: isFavorite
                              ? AppColors.white
                              : AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          logement.titre,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // if (logement.note != null) ...[
                      //   const Icon(Icons.star, color: AppColors.rating, size: 16),
                      //   const SizedBox(width: 4),
                      //   Text(logement.note!.toStringAsFixed(1)),
                      // ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (logement.adresse != null)
                    Text(
                      logement.adresse!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              ),
                            ),
                            const TextSpan(
                              text: ' / nuit',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (logement.photos.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.photo_library, size: 16),
                          label: Text('${logement.photos.length}'),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
