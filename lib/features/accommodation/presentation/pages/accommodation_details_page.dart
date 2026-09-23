import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:vodou/features/favorites/presentation/widgets/favorite_list_dialog.dart';
import 'package:vodou/features/accommodation/presentation/providers/accommodation_details_provider.dart';
import 'package:vodou/features/accommodation/presentation/widgets/photo_carousel.dart';
import 'package:vodou/features/accommodation/presentation/widgets/equipements_section.dart';
import 'package:vodou/features/accommodation/presentation/widgets/divinites_section.dart';
import 'package:vodou/features/accommodation/presentation/widgets/avis_section.dart';
import 'package:vodou/features/accommodation/presentation/widgets/host_section.dart';
import 'package:vodou/features/rituals/presentation/widgets/rituals_section.dart';
import 'package:vodou/features/rituals/presentation/providers/ritual_provider.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/accommodation/domain/models/equipement.dart';
import 'package:vodou/features/accommodation/domain/models/avis.dart';
import 'package:vodou/features/accommodation/domain/models/host_info.dart';
import 'package:vodou/features/booking/presentation/widgets/availability_calendar_widget.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

class AccommodationDetailsPage extends ConsumerWidget {
  final int accommodationId;

  const AccommodationDetailsPage({super.key, required this.accommodationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logementAsync = ref.watch(logementDetailsProvider(accommodationId));
    final divinitesAsync = ref.watch(
      logementDivinitesProvider(accommodationId),
    );
    final equipementsAsync = ref.watch(
      logementEquipementsProvider(accommodationId),
    );
    final avisAsync = ref.watch(logementAvisProvider(accommodationId));
    final statsAsync = ref.watch(avisStatsProvider(accommodationId));
    final ritualsAsync = ref.watch(logementRitualsProvider(accommodationId));

    return logementAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: const CustomAppBar(title: 'Erreur'),
        body: Center(child: Text(ErrorMapper.toMessage(error))),
      ),
      data: (logement) {
        final hostAsync = ref.watch(hostInfoProvider(logement.userId));

        return _buildContent(
          context,
          ref,
          logement,
          divinitesAsync,
          equipementsAsync,
          avisAsync,
          statsAsync,
          hostAsync,
          ritualsAsync,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Logement logement,
    AsyncValue<List<Divinite>> divinitesAsync,
    AsyncValue<List<Equipement>> equipementsAsync,
    AsyncValue<List<Avis>> avisAsync,
    AsyncValue<AvisStats> statsAsync,
    AsyncValue<HostInfo> hostAsync,
    AsyncValue ritualsAsync,
  ) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Rafraîchir toutes les données du logement
          ref.invalidate(logementDetailsProvider(accommodationId));
          ref.invalidate(logementDivinitesProvider(accommodationId));
          ref.invalidate(logementEquipementsProvider(accommodationId));
          ref.invalidate(logementAvisProvider(accommodationId));
          ref.invalidate(avisStatsProvider(accommodationId));
          ref.invalidate(logementRitualsProvider(accommodationId));
          ref.invalidate(hostInfoProvider(logement.userId));
        },
        child: CustomScrollView(
          slivers: [
            // Carrousel de photos
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(AppRouter.home);
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: PhotoCarousel(photos: logement.photos),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  color: Colors.white,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: 'Découvrez ${logement.titre} sur VodooHost !',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien du logement copié !'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final favoriteNotifier = ref.watch(
                      favoriteNotifierProvider.notifier,
                    );
                    final isFavorite = ref
                        .watch(favoriteNotifierProvider)
                        .contains(logement.id);

                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_outline,
                        color: isFavorite ? AppColors.favorite : Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => FavoriteListDialog(
                            logementId: logement.id,
                            logementTitre: logement.titre,
                          ),
                        ).then((_) {
                          favoriteNotifier.refresh();
                        });
                      },
                    );
                  },
                ),
              ],
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et note
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            logement.titre,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        statsAsync.when(
                          data: (stats) {
                            if (stats.totalAvis > 0) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.rating,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats.moyenneNote.toStringAsFixed(1)} (${stats.totalAvis})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Localisation
                    if (logement.adresse != null ||
                        (logement.latitude != null &&
                            logement.longitude != null))
                      InkWell(
                        onTap: () => _showMapsConfirmationDialog(
                          context,
                          logement.latitude,
                          logement.longitude,
                          logement.adresse,
                          logement.titre,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  logement.adresse ?? 'Voir la carte',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Google Maps',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Caractéristiques rapides
                    Row(
                      children: [
                        if (logement.nbVoyageurMax != null) ...[
                          const Icon(
                            Icons.people_outline,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text('${logement.nbVoyageurMax} voyageurs'),
                          const SizedBox(width: 16),
                        ],
                        if (logement.nbChambre != null) ...[
                          const Icon(
                            Icons.bed_outlined,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text('${logement.nbChambre} chambres'),
                        ],
                      ],
                    ),

                    const Divider(height: 32),

                    // Description
                    if (logement.description != null) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        logement.description!,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Divider(height: 32),
                    ],

                    // Équipements
                    equipementsAsync.when(
                      data: (equipements) => equipements.isNotEmpty
                          ? Column(
                              children: [
                                EquipementsSection(equipements: equipements),
                                const Divider(height: 32),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Divinités
                    divinitesAsync.when(
                      data: (divinites) => divinites.isNotEmpty
                          ? Column(
                              children: [
                                DivinitesSection(divinites: divinites),
                                const Divider(height: 32),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Rituels vaudou
                    ritualsAsync.when(
                      data: (rituals) => rituals.isNotEmpty
                          ? Column(
                              children: [
                                RitualsSection(rituals: rituals),
                                const Divider(height: 32),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Calendrier de disponibilité
                    AvailabilityCalendarWidget(
                      logementId: logement.id,
                      onDateSelected: (_) {
                        context.push(AppRouter.booking, extra: logement);
                      },
                    ),
                    const Divider(height: 32),

                    // Informations sur l'hôte
                    hostAsync.when(
                      data: (host) => Column(
                        children: [
                          HostSection(host: host, logementId: logement.id),
                          const Divider(height: 32),
                        ],
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Avis et évaluations
                    avisAsync.when(
                      data: (avisList) => statsAsync.when(
                        data: (stats) => Column(
                          children: [
                            AvisSection(
                              avisList: avisList,
                              stats: stats,
                              logementId: logement.id,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${logement.prixParNuit.toStringAsFixed(0)} XOF / nuit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigation vers la page de réservation avec BookingPageV2
                  context.push(AppRouter.booking, extra: logement);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Réserver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMapsConfirmationDialog(
    BuildContext context,
    double? latitude,
    double? longitude,
    String? adresse,
    String titre,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ouvrir Google Maps'),
        content: Text(
          'Vous allez être redirigé vers Google Maps pour voir la localisation de "$titre".\n\nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openGoogleMaps(
                context,
                latitude,
                longitude,
                adresse,
                titre,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ouvrir Maps'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    double? latitude,
    double? longitude,
    String? adresse,
    String titre,
  ) async {
    Uri url;
    if (latitude != null &&
        longitude != null &&
        (latitude != 0 || longitude != 0)) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else if (adresse != null && adresse.isNotEmpty) {
      final query = Uri.encodeComponent('$titre, $adresse');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    } else {
      final query = Uri.encodeComponent(titre);
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      AppLogger.w('⚠️ Erreur d\'ouverture Maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir la carte: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
