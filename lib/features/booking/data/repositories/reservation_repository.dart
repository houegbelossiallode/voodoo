import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';
import 'package:vodou/features/booking/domain/models/logement_disponibilite.dart';
import 'package:vodou/features/booking/domain/date_range_rules.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Statuts de disponibilité pour l'affichage du calendrier
enum DateAvailabilityStatus {
  disponible, // Vert
  indisponible, // Gris
  reserver, // Rouge
}

/// Repository pour gérer les réservations
class ReservationRepository {
  final SupabaseService _supabaseService;

  ReservationRepository(this._supabaseService);

  /// Crée une réservation complète avec toutes les transactions associées
  Future<Reservation> createReservation({
    required int logementId,
    required int userId,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double montant,
    required int nbNuits,
    required int nbVoyageurs,
    required String modePaiement,
    required String reference,
    int? projetId,
  }) async {
    try {
      AppLogger.d('📝 Création de la réservation...');

      // 1. Récupérer le pourcentage de commission de la plateforme
      final constanceResponse = await _supabaseService.client
          .from(SupabaseConfig.constancesTable)
          .select()
          .eq('param', 'pourcentage')
          .single();

      final double pourcentageCommission = (constanceResponse['val'] as num)
          .toDouble();
      final double commission = montant * (pourcentageCommission / 100);

      AppLogger.d(
        '💰 Commission calculée: $commission XOF ($pourcentageCommission%)',
      );

      // 2. Calculer la contribution au projet si applicable
      double partProjet = 0.0;
      if (projetId != null) {
        final projetResponse = await _supabaseService.client
            .from(SupabaseConfig.projetsTable)
            .select()
            .eq('id', projetId)
            .single();

        final double pourcentageContribution =
            (projetResponse['pourcentage_contribution'] as num).toDouble();
        partProjet = montant * (pourcentageContribution / 100);

        AppLogger.d(
          '🎯 Contribution projet calculée: $partProjet XOF ($pourcentageContribution%)',
        );
      }

      // 3. Créer la réservation
      final reservationData = {
        'logement_id': logementId,
        'user_id': userId,
        'date_debut': dateDebut.toIso8601String().split('T')[0],
        'date_fin': dateFin.toIso8601String().split('T')[0],
        'montant': montant,
        'nb_nuits': nbNuits,
        'nb_voyageurs': nbVoyageurs,
        'mode_paiement': modePaiement,
        'reference': reference,
        'projet_id': projetId,
        'statut': 'PAYE',
        'created_at': DateTime.now().toIso8601String(),
      };

      final reservationResponse = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .insert(reservationData)
          .select()
          .single();

      final int reservationId = reservationResponse['id'] as int;
      AppLogger.d('✅ Réservation créée avec ID: $reservationId');

      // 4. Enregistrer le revenu de la plateforme
      await _supabaseService.client.from('revenu_plateformes').insert({
        'reservation_id': reservationId,
        'commission': commission,
        'part_projet': partProjet,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.d('✅ Revenu plateforme enregistré');

      // 5. Si projet communautaire, créer la contribution
      if (projetId != null && partProjet > 0) {
        await _supabaseService.client
            .from(SupabaseConfig.contributionsTable)
            .insert({
              'projet_id': projetId,
              'reservation_id': reservationId,
              'montant_contribue': partProjet,
              'date_contribue': DateTime.now().toIso8601String().split('T')[0],
              'created_at': DateTime.now().toIso8601String(),
            });

        AppLogger.d('✅ Contribution au projet enregistrée');
      }

      // 6. Récupérer l'hôte du logement
      final logementResponse = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('user_id')
          .eq('id', logementId)
          .single();

      final int hoteUserId = logementResponse['user_id'] as int;

      // 7. Calculer le montant à verser à l'hôte
      final double montantHote = montant - commission - partProjet;
      AppLogger.d('💵 Montant pour l\'hôte: $montantHote XOF');

      // 8. Récupérer ou créer le compte de l'hôte
      final compteResponse = await _supabaseService.client
          .from(
            SupabaseConfig.constancesTable.replaceAll('constances', 'comptes'),
          )
          .select()
          .eq('user_id', hoteUserId)
          .maybeSingle();

      int compteId;
      double soldeActuel = 0.0;

      if (compteResponse == null) {
        // Créer un nouveau compte
        final newCompteResponse = await _supabaseService.client
            .from('comptes')
            .insert({
              'user_id': hoteUserId,
              'solde': montantHote,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        compteId = newCompteResponse['id'] as int;
        AppLogger.d('✅ Nouveau compte créé pour l\'hôte');
      } else {
        // Mettre à jour le solde existant
        compteId = compteResponse['id'] as int;
        soldeActuel = (compteResponse['solde'] as num).toDouble();
        final nouveauSolde = soldeActuel + montantHote;

        await _supabaseService.client
            .from('comptes')
            .update({
              'solde': nouveauSolde,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', compteId);

        AppLogger.d(
          '✅ Solde du compte mis à jour: $soldeActuel → $nouveauSolde XOF',
        );
      }

      // 9. Créer la transaction
      await _supabaseService.client.from('transactions').insert({
        'montant': montantHote,
        'type': 'credit',
        'compte_id': compteId,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.d('✅ Transaction enregistrée');

      // 10. Découper et synchroniser les disponibilités du logement
      await updateDisponibilitesAfterReservation(
        logementId: logementId,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      // 11. Retourner la réservation créée
      return Reservation.fromJson(reservationResponse);
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la création de la réservation: $e');
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la création de la réservation',
      );
    }
  }

  /// Récupère les réservations d'un utilisateur
  Future<List<Reservation>> getUserReservations(int userId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .select('''
            *,
            logement:${SupabaseConfig.logementsTable}(titre),
            projet:${SupabaseConfig.projetsTable}(titre)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des réservations',
      );
    }
  }

  /// Récupère une réservation par son ID
  Future<Reservation?> getReservationById(int id) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .select('''
            *,
            logement:${SupabaseConfig.logementsTable}(titre),
            projet:${SupabaseConfig.projetsTable}(titre)
          ''')
          .eq('id', id)
          .single();

      return Reservation.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération de la réservation',
      );
    }
  }

  /// Annule une réservation
  Future<void> cancelReservation(int reservationId) async {
    try {
      await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .update({
            'statut': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reservationId);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'l\'annulation de la réservation',
      );
    }
  }

  /// Vérifie la disponibilité d'un logement pour une période
  Future<bool> checkAvailability({
    required int logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      AppLogger.d('🔍 Vérification de disponibilité...');
      AppLogger.d('   Logement ID: $logementId');
      AppLogger.d(
        '   Date début: ${dateDebut.toIso8601String().split('T')[0]}',
      );
      AppLogger.d('   Date fin: ${dateFin.toIso8601String().split('T')[0]}');

      // 1. Vérifier dans la table logement_disponibilites
      final disponibilitesResponse = await _supabaseService.client
          .from('logement_disponibilites')
          .select()
          .eq('logement_id', logementId)
          .eq('statut', 'disponible');

      final disponibilites = (disponibilitesResponse as List)
          .map(
            (json) =>
                LogementDisponibilite.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      AppLogger.d(
        '📋 ${disponibilites.length} périodes de disponibilité trouvées',
      );

      // Vérifier si les dates demandées sont couvertes par une période disponible
      bool isInAvailablePeriod = false;
      for (var dispo in disponibilites) {
        final dispoDebut = DateTime(
          dispo.dateDebut.year,
          dispo.dateDebut.month,
          dispo.dateDebut.day,
        );
        final dispoFin = DateTime(
          dispo.dateFin.year,
          dispo.dateFin.month,
          dispo.dateFin.day,
        );
        final reservDebut = DateTime(
          dateDebut.year,
          dateDebut.month,
          dateDebut.day,
        );
        final reservFin = DateTime(dateFin.year, dateFin.month, dateFin.day);

        final debutOk =
            reservDebut.isAtSameMomentAs(dispoDebut) ||
            reservDebut.isAfter(dispoDebut);
        final finOk =
            reservFin.isAtSameMomentAs(dispoFin) ||
            reservFin.isBefore(dispoFin);

        if (debutOk && finOk) {
          isInAvailablePeriod = true;
          break;
        }
      }

      if (!isInAvailablePeriod) {
        AppLogger.e('❌ Aucune période de disponibilité ne couvre ces dates');
        return false;
      }

      // 2. Vérifier s'il y a des réservations qui se chevauchent
      final reservationsResponse = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .select('id, date_debut, date_fin, statut')
          .eq('logement_id', logementId);

      final reservations = reservationsResponse as List;

      // Logique de chevauchement déléguée à DateRangeRules : fonction pure,
      // couverte par des tests unitaires (VUL-11).
      final paidReservations = reservations.where((r) {
        if (!DateRangeRules.estBloquant(r['statut'] as String?)) return false;

        return DateRangeRules.seChevauchent(
          debutA: dateDebut,
          finA: dateFin,
          debutB: DateTime.parse(r['date_debut'] as String),
          finB: DateTime.parse(r['date_fin'] as String),
        );
      }).toList();

      if (paidReservations.isNotEmpty) {
        AppLogger.e(
          '❌ Conflit avec ${paidReservations.length} réservation(s) payée(s) existante(s)',
        );
        return false;
      }

      AppLogger.d('✅ Logement disponible pour cette période');
      return true;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la vérification de disponibilité: $e');
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la vérification de disponibilité',
      );
    }
  }

  /// Récupère la cartographie des statuts par date pour un logement (Mode Strict : Fermé par défaut)
  Future<Map<DateTime, DateAvailabilityStatus>> getDateStatuses(
    int logementId,
  ) async {
    final Map<DateTime, DateAvailabilityStatus> statusMap = {};
    try {
      // 1. Initialisation : En mode strict, toutes les dates des 730 prochains jours (2 ans) sont indisponibles par défaut
      final today = DateTime.now();
      final nowStart = DateTime(today.year, today.month, today.day);
      for (int i = 0; i < 730; i++) {
        final day = nowStart.add(Duration(days: i));
        statusMap[DateTime(day.year, day.month, day.day)] =
            DateAvailabilityStatus.indisponible;
      }

      // 2. Récupérer toutes les plages depuis la table logement_disponibilites
      final dispoResponse = await _supabaseService.client
          .from(SupabaseConfig.logementDisponibilitesTable)
          .select('date_debut, date_fin, statut')
          .eq('logement_id', logementId);

      final List dispoList = dispoResponse as List;

      // Trier dispoList pour appliquer la priorité : indisponible (0) -> disponible (1) -> reserver (2)
      dispoList.sort((a, b) {
        final stA = (a['statut'] as String? ?? '').toLowerCase();
        final stB = (b['statut'] as String? ?? '').toLowerCase();
        int rank(String s) {
          if (s == 'indisponible') return 0;
          if (s == 'disponible') return 1;
          return 2;
        }

        return rank(stA).compareTo(rank(stB));
      });

      for (var item in dispoList) {
        final statutStr = (item['statut'] as String? ?? 'disponible')
            .toLowerCase();
        final start = DateTime.parse(item['date_debut'] as String);
        final end = DateTime.parse(item['date_fin'] as String);

        DateAvailabilityStatus st;
        if (statutStr == 'reserve' ||
            statutStr == 'réservé' ||
            statutStr == 'reserver') {
          st = DateAvailabilityStatus.reserver;
        } else if (statutStr == 'indisponible') {
          st = DateAvailabilityStatus.indisponible;
        } else {
          st = DateAvailabilityStatus.disponible;
        }

        DateTime current = DateTime(start.year, start.month, start.day);
        final last = DateTime(end.year, end.month, end.day);

        while (!current.isAfter(last)) {
          statusMap[current] = st;
          current = current.add(const Duration(days: 1));
        }
      }

      // 3. Superposer les réservations payées (statut PAYE / PAYÉ / CONFIRMEE) par-dessus
      final reservationsResponse = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .select('date_debut, date_fin, statut')
          .eq('logement_id', logementId);

      for (var item in reservationsResponse as List) {
        final st = (item['statut'] as String? ?? '').toUpperCase();
        if (st != 'PAYE' &&
            st != 'PAYÉ' &&
            st != 'CONFIRMEE' &&
            st != 'CONFIRMÉE') {
          continue;
        }

        final start = DateTime.parse(item['date_debut'] as String);
        final end = DateTime.parse(item['date_fin'] as String);

        DateTime current = DateTime(start.year, start.month, start.day);
        final last = DateTime(end.year, end.month, end.day);

        while (!current.isAfter(last)) {
          statusMap[current] = DateAvailabilityStatus.reserver;
          current = current.add(const Duration(days: 1));
        }
      }
    } catch (e) {
      AppLogger.e('❌ Erreur getDateStatuses: $e');
    }
    return statusMap;
  }

  /// Récupère la liste des dates explicitement disponibles pour la réservation
  Future<Set<DateTime>> getAvailableDates(int logementId) async {
    try {
      final statusMap = await getDateStatuses(logementId);
      final Set<DateTime> availableDates = {};

      for (var entry in statusMap.entries) {
        if (entry.value == DateAvailabilityStatus.disponible) {
          availableDates.add(entry.key);
        }
      }

      AppLogger.d(
        '📅 [getAvailableDates] Total dates disponibles: ${availableDates.length}',
      );
      return availableDates;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des dates disponibles: $e');
      return {};
    }
  }

  /// Récupère la liste des dates indisponibles (réservées ou marquées comme indisponibles)
  Future<List<DateTime>> getDisabledDates(int logementId) async {
    try {
      final statusMap = await getDateStatuses(logementId);
      final List<DateTime> disabledDates = [];

      for (var entry in statusMap.entries) {
        if (entry.value != DateAvailabilityStatus.disponible) {
          disabledDates.add(entry.key);
        }
      }

      AppLogger.d(
        '📅 [getDisabledDates] Total dates désactivées (non disponibles): ${disabledDates.length}',
      );
      return disabledDates;
    } catch (e) {
      AppLogger.e(
        '❌ Erreur lors de la récupération des dates indisponibles: $e',
      );
      return [];
    }
  }

  /// Met à jour et découpe automatiquement les plages dans `logement_disponibilites` lors d'une réservation
  Future<void> updateDisponibilitesAfterReservation({
    required int logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      AppLogger.d(
        '🔄 Découpage et mise à jour des disponibilités pour le logement #$logementId...',
      );
      final reqDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
      final reqFin = DateTime(dateFin.year, dateFin.month, dateFin.day);

      final reqDebutStr = reqDebut.toIso8601String().split('T')[0];
      final reqFinStr = reqFin.toIso8601String().split('T')[0];

      // 1. Récupérer toutes les plages chevauchant [reqDebut, reqFin]
      final overlappingResponse = await _supabaseService.client
          .from(SupabaseConfig.logementDisponibilitesTable)
          .select()
          .eq('logement_id', logementId)
          .lte('date_debut', reqFinStr)
          .gte('date_fin', reqDebutStr);

      final List overlappingList = overlappingResponse as List;
      AppLogger.d(
        '📋 ${overlappingList.length} plage(s) chevauchante(s) trouvée(s)',
      );

      if (overlappingList.isEmpty) {
        // Aucune plage existante chevauchante -> Insérer directement la plage réservée
        await _supabaseService.client
            .from(SupabaseConfig.logementDisponibilitesTable)
            .insert({
              'logement_id': logementId,
              'date_debut': reqDebutStr,
              'date_fin': reqFinStr,
              'statut': 'reserver',
              'created_at': DateTime.now().toIso8601String(),
            });
        AppLogger.d(
          '✅ Ligne de réservation insérée directement dans logement_disponibilites',
        );
        return;
      }

      for (var item in overlappingList) {
        final int itemPlanId = item['id'] as int;
        final dispoDebut = DateTime.parse(item['date_debut'] as String);
        final dispoFin = DateTime.parse(item['date_fin'] as String);
        final String origStatut = item['statut'] as String? ?? 'disponible';

        final hasBeforeSegment = dispoDebut.isBefore(reqDebut);
        final hasAfterSegment = dispoFin.isAfter(reqFin);

        if (hasBeforeSegment && hasAfterSegment) {
          // CAS A : La réservation est au milieu de la plage initiale
          final beforeEnd = reqDebut.subtract(const Duration(days: 1));
          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .update({
                'date_fin': beforeEnd.toIso8601String().split('T')[0],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', itemPlanId);

          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .insert({
                'logement_id': logementId,
                'date_debut': reqDebutStr,
                'date_fin': reqFinStr,
                'statut': 'reserver',
                'created_at': DateTime.now().toIso8601String(),
              });

          final afterStart = reqFin.add(const Duration(days: 1));
          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .insert({
                'logement_id': logementId,
                'date_debut': afterStart.toIso8601String().split('T')[0],
                'date_fin': dispoFin.toIso8601String().split('T')[0],
                'statut': origStatut,
                'created_at': DateTime.now().toIso8601String(),
              });
        } else if (hasBeforeSegment && !hasAfterSegment) {
          // CAS B : La réservation touche la fin de la plage initiale
          final beforeEnd = reqDebut.subtract(const Duration(days: 1));
          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .update({
                'date_fin': beforeEnd.toIso8601String().split('T')[0],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', itemPlanId);

          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .insert({
                'logement_id': logementId,
                'date_debut': reqDebutStr,
                'date_fin': reqFinStr,
                'statut': 'reserver',
                'created_at': DateTime.now().toIso8601String(),
              });
        } else if (!hasBeforeSegment && hasAfterSegment) {
          // CAS C : La réservation touche le début de la plage initiale
          final afterStart = reqFin.add(const Duration(days: 1));
          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .update({
                'date_debut': afterStart.toIso8601String().split('T')[0],
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', itemPlanId);

          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .insert({
                'logement_id': logementId,
                'date_debut': reqDebutStr,
                'date_fin': reqFinStr,
                'statut': 'reserver',
                'created_at': DateTime.now().toIso8601String(),
              });
        } else {
          // CAS D : La réservation englobe totalement la plage initiale
          await _supabaseService.client
              .from(SupabaseConfig.logementDisponibilitesTable)
              .update({
                'statut': 'reserver',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', itemPlanId);
        }
      }
      AppLogger.d(
        '✅ Plages de disponibilité découpées et synchronisées avec succès !',
      );
    } catch (e) {
      AppLogger.e('❌ Erreur lors du découpage des disponibilités: $e');
    }
  }
}
