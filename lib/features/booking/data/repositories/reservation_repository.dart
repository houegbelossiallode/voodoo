import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';
import 'package:vodou/features/booking/domain/models/logement_disponibilite.dart';

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
      print('📝 Création de la réservation...');

      // 1. Récupérer le pourcentage de commission de la plateforme
      final constanceResponse = await _supabaseService.client
          .from(SupabaseConfig.constancesTable)
          .select()
          .eq('param', 'pourcentage')
          .single();

      final double pourcentageCommission = (constanceResponse['val'] as num)
          .toDouble();
      final double commission = montant * (pourcentageCommission / 100);

      print(
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

        print(
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
      print('✅ Réservation créée avec ID: $reservationId');

      // 4. Enregistrer le revenu de la plateforme
      await _supabaseService.client.from('revenu_plateformes').insert({
        'reservation_id': reservationId,
        'commission': commission,
        'part_projet': partProjet,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Revenu plateforme enregistré');

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

        print('✅ Contribution au projet enregistrée');
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
      print('💵 Montant pour l\'hôte: $montantHote XOF');

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
        print('✅ Nouveau compte créé pour l\'hôte');
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

        print('✅ Solde du compte mis à jour: $soldeActuel → $nouveauSolde XOF');
      }

      // 9. Créer la transaction
      await _supabaseService.client.from('transactions').insert({
        'montant': montantHote,
        'type': 'credit',
        'compte_id': compteId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Transaction enregistrée');

      // 10. Retourner la réservation créée
      return Reservation.fromJson(reservationResponse);
    } catch (e) {
      print('❌ Erreur lors de la création de la réservation: $e');
      throw Exception('Erreur lors de la création de la réservation: $e');
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
      throw Exception('Erreur lors de la récupération des réservations: $e');
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
      throw Exception('Erreur lors de la récupération de la réservation: $e');
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
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }

  /// Vérifie la disponibilité d'un logement pour une période
  Future<bool> checkAvailability({
    required int logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      print('🔍 Vérification de disponibilité...');
      print('   Logement ID: $logementId');
      print('   Date début: ${dateDebut.toIso8601String().split('T')[0]}');
      print('   Date fin: ${dateFin.toIso8601String().split('T')[0]}');

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

      print('📋 ${disponibilites.length} périodes de disponibilité trouvées');

      // Vérifier si les dates demandées sont couvertes par une période disponible
      bool isInAvailablePeriod = false;
      for (var dispo in disponibilites) {
        print(
          '   Vérification période: ${dispo.dateDebut.toIso8601String().split('T')[0]} - ${dispo.dateFin.toIso8601String().split('T')[0]}',
        );

        // Normaliser les dates pour comparer uniquement les jours (sans heures)
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

        print('   Dispo normalisée: $dispoDebut - $dispoFin');
        print('   Réservation normalisée: $reservDebut - $reservFin');

        // Les dates de réservation doivent être complètement dans la période disponible
        // dateDebut >= dispoDebut ET dateFin <= dispoFin
        final debutOk =
            reservDebut.isAtSameMomentAs(dispoDebut) ||
            reservDebut.isAfter(dispoDebut);
        final finOk =
            reservFin.isAtSameMomentAs(dispoFin) ||
            reservFin.isBefore(dispoFin);

        print('   Début OK: $debutOk (${reservDebut} >= ${dispoDebut})');
        print('   Fin OK: $finOk (${reservFin} <= ${dispoFin})');

        if (debutOk && finOk) {
          isInAvailablePeriod = true;
          print(
            '✅ Période disponible trouvée: ${dispo.dateDebut.toIso8601String().split('T')[0]} - ${dispo.dateFin.toIso8601String().split('T')[0]}',
          );
          break;
        }
      }

      if (!isInAvailablePeriod) {
        print('❌ Aucune période de disponibilité ne couvre ces dates');
        return false;
      }

      // 2. Vérifier s'il y a des réservations qui se chevauchent
      print('🔍 Vérification des réservations existantes...');

      final dateDebutStr = dateDebut.toIso8601String().split('T')[0];
      final dateFinStr = dateFin.toIso8601String().split('T')[0];

      final reservationsResponse = await _supabaseService.client
          .from(SupabaseConfig.reservationsTable)
          .select('id, date_debut, date_fin, statut')
          .eq('logement_id', logementId)
          .not('statut', 'in', '(cancelled,ANNULEE)')
          .lte('date_debut', dateFinStr)
          .gte('date_fin', dateDebutStr);

      final reservations = reservationsResponse as List;

      print('   ${reservations.length} réservation(s) trouvée(s)');

      if (reservations.isNotEmpty) {
        print(
          '❌ Conflit avec ${reservations.length} réservation(s) existante(s):',
        );
        for (var reservation in reservations) {
          print(
            '   - Réservation #${reservation['id']}: ${reservation['date_debut']} → ${reservation['date_fin']} (${reservation['statut']})',
          );
        }
        return false;
      }

      print('✅ Aucune réservation conflictuelle');
      print('✅ Logement disponible pour cette période');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification de disponibilité: $e');
      throw Exception('Erreur lors de la vérification de disponibilité: $e');
    }
  }
}
