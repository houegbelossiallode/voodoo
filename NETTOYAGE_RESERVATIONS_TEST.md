# 🧹 Nettoyage des Réservations de Test

## 🐛 Problème Actuel

Vous avez **5 réservations** qui bloquent le logement #31 pour les dates 2025-12-22 → 2025-12-25.

```
✅ Période disponible trouvée: 2025-12-22 - 2025-12-26
❌ Conflit avec 5 réservation(s) existante(s)
```

## 🔍 Diagnostic

### Étape 1 : Relancer l'Application

Avec les nouveaux logs, vous verrez maintenant les détails des réservations qui bloquent :

```bash
flutter run
```

**Logs attendus** :
```
🔍 Vérification des réservations existantes...
❌ Conflit avec 5 réservation(s) existante(s):
   - Réservation #1: 2025-12-22 → 2025-12-25 (pending)
   - Réservation #2: 2025-12-23 → 2025-12-24 (confirmed)
   - Réservation #3: 2025-12-22 → 2025-12-26 (PAYE)
   - Réservation #4: 2025-12-20 → 2025-12-23 (pending)
   - Réservation #5: 2025-12-24 → 2025-12-27 (pending)
```

### Étape 2 : Identifier les Réservations dans Supabase

```sql
-- Voir toutes les réservations du logement #31
SELECT 
  id,
  date_debut,
  date_fin,
  statut,
  mode_paiement,
  reference,
  created_at
FROM reservations
WHERE logement_id = 31
ORDER BY created_at DESC;
```

## 🛠️ Solutions

### Solution 1 : Annuler les Réservations de Test

Si ce sont des réservations de test, annulez-les :

```sql
-- Annuler toutes les réservations de test du logement #31
UPDATE reservations
SET statut = 'ANNULEE'
WHERE logement_id = 31
  AND statut IN ('pending', 'confirmed', 'PAYE');
```

**OU** annuler seulement certaines réservations :

```sql
-- Annuler des réservations spécifiques
UPDATE reservations
SET statut = 'ANNULEE'
WHERE id IN (1, 2, 3, 4, 5);  -- Remplacer par les vrais IDs
```

### Solution 2 : Supprimer les Réservations de Test

⚠️ **Attention** : Cela supprime définitivement les données !

```sql
-- Supprimer toutes les réservations de test du logement #31
DELETE FROM reservations
WHERE logement_id = 31
  AND statut IN ('pending', 'confirmed');
```

### Solution 3 : Choisir d'Autres Dates

Si les réservations sont légitimes, choisissez des dates qui ne chevauchent pas :

```sql
-- Trouver les périodes libres
SELECT 
  date_debut,
  date_fin,
  statut
FROM reservations
WHERE logement_id = 31
  AND statut NOT IN ('cancelled', 'ANNULEE')
ORDER BY date_debut;
```

## 📊 Vérification Après Nettoyage

### 1. Vérifier qu'il n'y a plus de réservations actives

```sql
SELECT COUNT(*) as nb_reservations_actives
FROM reservations
WHERE logement_id = 31
  AND statut NOT IN ('cancelled', 'ANNULEE');
```

**Résultat attendu** : `0`

### 2. Vérifier les statuts disponibles

```sql
-- Voir tous les statuts utilisés
SELECT DISTINCT statut, COUNT(*) as count
FROM reservations
WHERE logement_id = 31
GROUP BY statut;
```

**Résultat attendu** :
```
statut   | count
---------|------
ANNULEE  | 5
```

### 3. Tester à Nouveau

1. Relancer l'application : `flutter run`
2. Sélectionner le logement #31
3. Choisir les dates : 2025-12-22 → 2025-12-25
4. Observer les logs :

```
🔍 Vérification de disponibilité...
📋 1 périodes de disponibilité trouvées
✅ Période disponible trouvée: 2025-12-22 - 2025-12-26
🔍 Vérification des réservations existantes...
✅ Aucune réservation conflictuelle
✅ Logement disponible pour cette période
```

5. Vérifier l'UI :
   - ✅ Message vert : "Logement disponible"
   - ✅ Bouton "Confirmer et payer" activé

## 🔧 Script de Nettoyage Complet

Pour nettoyer TOUTES les réservations de test de TOUS les logements :

```sql
-- 1. Voir combien de réservations seront affectées
SELECT COUNT(*) as total_a_nettoyer
FROM reservations
WHERE statut IN ('pending', 'confirmed')
  AND created_at < NOW() - INTERVAL '1 day';

-- 2. Annuler les réservations de test (plus de 1 jour)
UPDATE reservations
SET statut = 'ANNULEE',
    updated_at = NOW()
WHERE statut IN ('pending', 'confirmed')
  AND created_at < NOW() - INTERVAL '1 day';

-- 3. Vérifier le résultat
SELECT statut, COUNT(*) as count
FROM reservations
GROUP BY statut;
```

## 📝 Statuts de Réservation

Voici les statuts qui **bloquent** la disponibilité :
- ✅ `'pending'` : En attente de paiement
- ✅ `'confirmed'` : Confirmée (ancien statut)
- ✅ `'PAYE'` : Payée (nouveau statut)
- ✅ `'completed'` : Terminée

Voici les statuts qui **ne bloquent PAS** :
- ❌ `'cancelled'` : Annulée (ancien statut)
- ❌ `'ANNULEE'` : Annulée (nouveau statut)

## 🎯 Recommandations

### Pour le Développement

1. **Utilisez un logement de test dédié** :
   ```sql
   -- Créer un logement spécial pour les tests
   INSERT INTO logements (titre, description, adresse, prix_par_nuit, ...)
   VALUES ('LOGEMENT TEST - NE PAS UTILISER', '...', '...', 1000, ...);
   ```

2. **Nettoyez régulièrement** :
   ```sql
   -- Script à exécuter régulièrement
   UPDATE reservations
   SET statut = 'ANNULEE'
   WHERE logement_id IN (SELECT id FROM logements WHERE titre LIKE '%TEST%')
     AND statut != 'ANNULEE';
   ```

### Pour la Production

1. **Ajoutez une colonne `is_test`** :
   ```sql
   ALTER TABLE reservations ADD COLUMN is_test BOOLEAN DEFAULT false;
   ```

2. **Marquez les réservations de test** :
   ```sql
   UPDATE reservations
   SET is_test = true
   WHERE mode_paiement = 'test' OR reference LIKE '%test%';
   ```

3. **Excluez-les de la vérification** :
   ```dart
   .not('statut', 'in', '(cancelled,ANNULEE)')
   .eq('is_test', false)  // Ajouter cette ligne
   ```

## 🚀 Action Immédiate

**Pour débloquer votre test maintenant** :

```sql
-- Annuler toutes les réservations du logement #31
UPDATE reservations
SET statut = 'ANNULEE'
WHERE logement_id = 31;
```

Puis relancez l'application et testez à nouveau !

---

**✅ Après le nettoyage, votre réservation devrait fonctionner !**
