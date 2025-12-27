# ✅ Résolution de l'Erreur d'Import Ambiguë

## 🐛 Problème

```
The name 'LogementDisponibilite' is defined in the libraries 
'package:vodou/features/booking/domain/models/logement_disponibilite.dart' 
and 'package:vodou/features/booking/domain/models/reservation.dart'.
```

## 🔍 Cause

La classe `LogementDisponibilite` était définie dans **deux fichiers différents** :
1. ✅ `logement_disponibilite.dart` (nouveau fichier créé)
2. ❌ `reservation.dart` (ancienne définition)

Cela créait un conflit d'import dans `reservation_repository.dart`.

## ✅ Solution Appliquée

**Suppression de la classe dupliquée dans `reservation.dart`**

La classe `LogementDisponibilite` a été supprimée du fichier `reservation.dart` (lignes 186-231).

Maintenant, la classe n'existe que dans son fichier dédié :
- ✅ `lib/features/booking/domain/models/logement_disponibilite.dart`

## 📁 Structure Finale des Modèles

```
lib/features/booking/domain/models/
├── reservation.dart
│   ├── class Reservation
│   └── class Paiement
│
└── logement_disponibilite.dart
    └── class LogementDisponibilite
```

## 🔧 Imports dans `reservation_repository.dart`

```dart
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';
import 'package:vodou/features/booking/domain/models/logement_disponibilite.dart';
```

## ✅ Vérification

L'erreur devrait maintenant être résolue. Vous pouvez vérifier en :

1. **Sauvegardant tous les fichiers** (Ctrl+S)
2. **Relançant l'analyse Dart** :
   ```bash
   flutter pub get
   dart analyze
   ```

## 📝 Classe LogementDisponibilite

La classe est maintenant uniquement définie dans `logement_disponibilite.dart` :

```dart
class LogementDisponibilite {
  final int id;
  final int logementId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut; // 'disponible', 'indisponible', 'reserve'

  LogementDisponibilite({
    required this.id,
    required this.logementId,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
  });

  factory LogementDisponibilite.fromJson(Map<String, dynamic> json) {
    return LogementDisponibilite(
      id: json['id'] as int,
      logementId: json['logement_id'] as int,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      statut: json['statut'] as String? ?? 'disponible',
    );
  }

  bool overlaps(DateTime start, DateTime end) {
    return dateDebut.isBefore(end) && dateFin.isAfter(start);
  }

  bool isAvailable() {
    return statut == 'disponible';
  }
}
```

## 🎯 Différences entre les Deux Versions

| Aspect | Ancienne (reservation.dart) | Nouvelle (logement_disponibilite.dart) |
|--------|----------------------------|----------------------------------------|
| Type `id` | `String` | `int` ✅ |
| Type `logementId` | `String` | `int` ✅ |
| Champs `createdAt/updatedAt` | ✅ Présents | ❌ Supprimés (simplification) |
| Méthodes utilitaires | ❌ Aucune | ✅ `overlaps()`, `isAvailable()` |

La nouvelle version est plus simple et mieux adaptée à notre usage.

---

**✅ L'erreur d'import ambiguë est maintenant résolue !**
