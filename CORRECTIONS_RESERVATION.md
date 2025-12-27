# 🔧 Corrections à Apporter - Système de Réservation

## ✅ Problèmes Identifiés

### 1. **Statut de Réservation** ✅ CORRIGÉ
- ❌ Ancien : `'statut': 'confirmed'`
- ✅ Nouveau : `'statut': 'payee'`
- **Fichier** : `reservation_repository.dart` ligne 73

### 2. **Logique du Bouton de Réservation** ⚠️ À CORRIGER

**Problème actuel** :
- Le bouton ne s'active pas si on ne touche pas à "Je souhaite contribuer à un projet"
- Quand on coche puis décoche, le bouton reste activé (comportement correct)
- Quand on ne touche pas du tout, le bouton reste désactivé (PROBLÈME)

**Solution** :
Supprimer la variable `_hasInteractedWithProjectCheckbox` et la logique associée.

**Modifications dans `booking_page_v2.dart`** :

```dart
// SUPPRIMER cette variable
bool _hasInteractedWithProjectCheckbox = false;

// MODIFIER la méthode _canBook()
bool _canBook() {
  // Vérifier les champs obligatoires
  if (_checkIn == null || _checkOut == null) return false;
  if (_guests <= 0) return false;
  if (widget.logement.nbVoyageurMax != null &&
      _guests > widget.logement.nbVoyageurMax!)
    return false;

  // Si l'utilisateur veut contribuer, un projet doit être sélectionné
  if (_contributeToProject && _selectedProject == null) return false;

  // Vérifier la disponibilité
  if (!_isAvailable) return false;

  return true;
}

// SUPPRIMER cette ligne dans onChanged du SwitchListTile
_hasInteractedWithProjectCheckbox = true; // ❌ À SUPPRIMER
```

### 3. **Vérification de Disponibilité** ✅ AJOUTÉ

**Nouvelle logique dans `reservation_repository.dart`** :

```dart
Future<bool> checkAvailability({
  required int logementId,
  required DateTime dateDebut,
  required DateTime dateFin,
}) async {
  // 1. Vérifier dans logement_disponibilites
  final disponibilites = await _supabaseService.client
      .from('logement_disponibilites')
      .select()
      .eq('logement_id', logementId)
      .eq('statut', 'disponible');

  // Vérifier si les dates sont dans une période disponible
  bool isInAvailablePeriod = false;
  for (var dispo in disponibilites) {
    if (dispo.dateDebut <= dateDebut && dispo.dateFin >= dateFin) {
      isInAvailablePeriod = true;
      break;
    }
  }

  if (!isInAvailablePeriod) return false;

  // 2. Vérifier les réservations existantes
  final reservations = await _supabaseService.client
      .from('reservations')
      .select()
      .eq('logement_id', logementId)
      .neq('statut', 'cancelled')
      .or('date_debut.lte.$dateFin,date_fin.gte.$dateDebut');

  return reservations.isEmpty;
}
```

**Ajouts dans `booking_page_v2.dart`** :

```dart
// Nouvelles variables d'état
bool _isCheckingAvailability = false;
bool _isAvailable = true;
String? _availabilityMessage;

// Nouvelle méthode
Future<void> _checkAvailability() async {
  if (_checkIn == null || _checkOut == null) return;

  setState(() {
    _isCheckingAvailability = true;
    _availabilityMessage = null;
  });

  try {
    final isAvailable = await ref
        .read(reservationRepositoryProvider)
        .checkAvailability(
          logementId: widget.logement.id,
          dateDebut: _checkIn!,
          dateFin: _checkOut!,
        );

    setState(() {
      _isAvailable = isAvailable;
      _isCheckingAvailability = false;
      if (!isAvailable) {
        _availabilityMessage =
            '⚠️ Ce logement n\'est pas disponible pour ces dates. Veuillez choisir d\'autres dates.';
      }
    });
  } catch (e) {
    setState(() {
      _isAvailable = false;
      _isCheckingAvailability = false;
      _availabilityMessage =
          '❌ Erreur lors de la vérification de disponibilité.';
    });
  }
}

// Appeler _checkAvailability() après la sélection des dates
void _selectDate(bool isCheckIn) async {
  // ... code existant ...
  
  // À la fin, après avoir défini _checkIn et _checkOut
  if (_checkIn != null && _checkOut != null) {
    await _checkAvailability();
  }
}

// Afficher le message de disponibilité dans le build()
if (_availabilityMessage != null) ...[
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _isAvailable ? Colors.green : Colors.red,
      ),
    ),
    child: Row(
      children: [
        Icon(
          _isAvailable ? Icons.check_circle : Icons.error,
          color: _isAvailable ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _availabilityMessage!,
            style: TextStyle(
              color: _isAvailable ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16),
],
```

## 📋 Checklist de Corrections

- [x] Changer le statut à 'payee' dans `reservation_repository.dart`
- [ ] Supprimer `_hasInteractedWithProjectCheckbox` dans `booking_page_v2.dart`
- [ ] Modifier `_canBook()` pour supprimer la vérification d'interaction
- [ ] Ajouter les variables `_isCheckingAvailability`, `_isAvailable`, `_availabilityMessage`
- [ ] Ajouter la méthode `_checkAvailability()`
- [ ] Appeler `_checkAvailability()` après sélection des dates
- [ ] Afficher le message de disponibilité dans l'UI
- [x] Créer le modèle `LogementDisponibilite`
- [x] Mettre à jour `checkAvailability()` dans le repository

## 🧪 Test

1. **Test du bouton sans interaction projet** :
   - Sélectionner des dates
   - Choisir nombre de voyageurs
   - NE PAS toucher à "Je souhaite contribuer"
   - ✅ Le bouton doit être activé

2. **Test de disponibilité** :
   - Sélectionner des dates non disponibles
   - ❌ Message d'erreur affiché
   - ❌ Bouton désactivé
   - Sélectionner des dates disponibles
   - ✅ Message de succès affiché
   - ✅ Bouton activé

3. **Test du statut** :
   - Effectuer une réservation
   - Vérifier dans Supabase :
   ```sql
   SELECT statut FROM reservations ORDER BY created_at DESC LIMIT 1;
   ```
   - ✅ Doit afficher 'payee'

## 📝 Notes Importantes

- La table `logement_disponibilites` doit contenir des périodes avec `statut = 'disponible'`
- Si aucune période n'est définie, tous les logements seront indisponibles
- Le statut 'payee' est plus précis que 'confirmed' car il indique que le paiement a été effectué
