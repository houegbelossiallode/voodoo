# Plan de mise en conformité — VodooHost

> **Objectif** : amener le projet `vodou` au niveau du référentiel *Flutter — Bonnes pratiques professionnelles (2026)*, sans réécriture complète et sans gel des développements.
> **Document lié** : [AUDIT_SECURITE.md](AUDIT_SECURITE.md) — inventaire des 32 vulnérabilités et défauts (identifiants `VUL-xx` / `Q-xx` repris ici).
> **Durée estimée** : 8 à 10 semaines à 1 développeur temps plein, ou 5 à 6 semaines à 2 développeurs.

---

> ### 📌 État d'avancement au 22 septembre 2026
>
> Une **passe de correction automatisée** a été appliquée. Tout ce qui était réalisable sans accès au dashboard Supabase ni à la base de données est fait — voir le §9 « Journal des corrections appliquées » d'[AUDIT_SECURITE.md](AUDIT_SECURITE.md).
>
> | Phase | Avancement |
> |---|---|
> | **0** — Urgence sécurité | 🟨 0.4 à 0.6 faits ; **0.1 (rotation), 0.2 (trigger) et 0.3 (RLS) restent bloquants** |
> | **1** — Fondations | 🟨 1.1, 1.4, 1.5, 1.6 faits ; restent 1.2 (flavors) et 1.3 (`very_good_analysis`) |
> | **2** — Backend | ⬜ Non commencée — **c'est désormais la priorité absolue** |
> | **3 à 6** | ⬜ Non commencées (quelques correctifs ponctuels anticipés) |
>
> **Indicateur clé** : `flutter analyze` passe de **518 problèmes à 0**, et `flutter build bundle` réussit.
>
> ⚠️ **L'application reste exploitable financièrement** tant que la phase 2.1 n'est pas livrée : les corrections appliquées portent sur le durcissement du client, pas sur la validation côté serveur.

---

## 0. Réponse à la question : est-ce faisable ?

**Oui, intégralement — et sans réécrire l'application.**

Le projet part d'une base bien plus favorable qu'il n'y paraît :

| Atout déjà en place | Conséquence |
|---|---|
| Organisation **feature-first** cohérente sur 15 features | La structure cible du §1.3 est à ~70 % atteinte ; il s'agit surtout de renommer et de compléter |
| **Riverpod seul**, sans mélange Provider/GetX/Bloc | La règle « un seul pattern par projet » (§2) est déjà respectée |
| **go_router** avec `GoRouterRefreshStream` fonctionnel | Le §3.5 est presque conforme |
| Constantes centralisées (`AppColors`, `AppStrings`, `AppAssets`) et `ThemeData` déclaré | Les tokens de design existent, il reste à les faire passer par `Theme.of` |
| Découpage `data` / `domain` / `presentation` déjà matérialisé | La couche `domain` est à compléter, pas à créer |

**Ce qui coûtera réellement :**

1. Le déplacement de la logique métier vers le serveur (**VUL-02**) — c'est un travail backend, pas Flutter, et c'est le poste le plus lourd.
2. L'écriture des tests à partir de zéro (**VUL-11**) — inévitable, à étaler.
3. La migration `freezed` de ~25 modèles (**Q-08**) — mécanique mais volumineuse.

**Ce qui est rapide :** les 5 vulnérabilités critiques sont, hors VUL-02, réparables en **2 à 3 jours cumulés**. C'est l'objet de la phase 0.

### Arbitrages proposés

| Sujet | Recommandation | Justification |
|---|---|---|
| **Riverpod ou Bloc ?** | **Rester sur Riverpod** | Le §2 autorise les deux. Une migration vers Bloc coûterait 3 semaines sans bénéfice de sécurité. Le caractère financier de l'app plaide pour des transitions auditables, mais la traçabilité s'obtient ici par les logs serveur, pas par le pattern client. |
| **`very_good_analysis` ou `flutter_lints` ?** | **`very_good_analysis`, activé progressivement** | Passer d'un coup ferait exploser le compteur de 518 à plusieurs milliers. Voir phase 1.3 pour la montée par paliers. |
| **`dartz`/`fpdart` ou `Result` maison ?** | **`Result<T>` scellé maison** (Dart 3 `sealed class`) | Évite une dépendance de plus (§8 : « le moins de packages possible ») et le style `Either` que l'équipe ne pratique pas. |
| **Use cases systématiques ?** | **Non** | Le §1.2 l'interdit explicitement pour les relais sans logique. Seuls 4 use cases sont justifiés (voir phase 3.3). |
| **`drift`/`isar` pour l'offline ?** | **Reporté hors périmètre** | À décider après mesure du besoin réel. `hive` sera retiré (jamais utilisé). |

---

## 1. Stratégie d'exécution

### Principe : *strangler pattern*, pas de big-bang

On ne gèle pas les développements et on ne refactorise pas 123 fichiers d'un coup. Chaque phase produit un état **compilable, testable et livrable**.

```
Phase 0  URGENCE SÉCURITÉ          ← 3 j   — bloquant, à faire en premier
Phase 1  FONDATIONS                ← 1 sem — outillage, config, logger, lint
Phase 2  BACKEND & DONNÉES         ← 2 sem — Edge Functions, RLS, atomicité
Phase 3  ARCHITECTURE              ← 2 sem — domain, Result, ViewModels
Phase 4  TESTS & CI                ← 1,5 sem
Phase 5  PERFORMANCE               ← 1 sem
Phase 6  QUALITÉ & FINITION        ← 1,5 sem
```

**Ordre imposé** : les phases 0, 1 et 2 sont séquentielles. Les phases 3 à 6 peuvent se chevaucher partiellement à deux développeurs.

### Règles de travail pour toute la durée du chantier

- Une branche par phase, une PR par tâche : `fix/vul-01-rotate-db-credentials`
- Conventional Commits : `fix(security):`, `refactor(auth):`, `test(booking):`
- **Règle du boy-scout** : tout fichier touché sort conforme (`const`, `_buildXxx` extrait, `print` supprimé)
- Aucune PR fusionnée si `flutter analyze` régresse

---

## 2. Phase 0 — Urgence sécurité (3 jours, bloquant)

> **Objectif** : rendre le dépôt et l'application non triviallement exploitables. Rien d'autre ne démarre avant.

### 0.1 — Rotation et purge des secrets · `VUL-01` · 3 h

| Étape | Action |
|---|---|
| 1 | Supabase Dashboard → Settings → Database → **Reset database password** |
| 2 | Supprimer `dbHost`, `dbPort`, `dbName`, `dbUsername`, `dbPassword` de `lib/core/config/supabase_config.dart` |
| 3 | Vider `.env.example` de toute valeur réelle (placeholders uniquement) |
| 4 | Ajouter à `.gitignore` : `.env`, `.env.*`, `!.env.example`, `android/key.properties`, `*.jks`, `env/*.json` |
| 5 | `git filter-repo --replace-text secrets.txt` puis `git push --force` (coordonner avec l'équipe) |
| 6 | Révoquer et régénérer la clé publique KKiaPay par précaution |

**Critère d'acceptation** : `git log -S '<ANCIEN_MOT_DE_PASSE>' --all` ne retourne aucun commit.

### 0.2 — Neutraliser l'élévation de privilèges · `VUL-03` · 4 h

1. Exécuter `supabase_triggers_fix.sql` (trigger `SECURITY DEFINER` forçant le rôle `Visiteur`).
2. Retirer `'role_id': roleId` de `signUp(data: {...})` — `auth_repository.dart:61`.
3. Supprimer la lecture de `metadata['role_id']` — `auth_repository.dart:198-222`.
4. Appliquer la policy `Users can update own profile` de `supabase_rls_policies.sql:31-37`.

**Critère d'acceptation** : un compte créé après `auth.updateUser(data: {'role_id': 1})` ressort bien avec le rôle `Visiteur`.

### 0.3 — Verrouiller les écritures financières · `VUL-04` · 1 j

Mesure conservatoire, en attendant les Edge Functions de la phase 2 :

```sql
ALTER TABLE public.comptes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenu_plateformes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions      ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.comptes, public.transactions,
       public.revenu_plateformes, public.contributions FROM authenticated, anon;
```

> ⚠️ **Cette étape casse volontairement le parcours de réservation.** C'est assumé : mieux vaut un parcours indisponible qu'un parcours exploitable. La phase 2.1 le rétablit sous 2 semaines. Si un environnement de production est déjà exposé, appliquer cette étape **en premier**, avant même 0.1.

Puis auditer l'existant :

```sql
SELECT relname, relrowsecurity FROM pg_class
WHERE relnamespace='public'::regnamespace AND relkind='r' ORDER BY relrowsecurity, relname;
```

Retirer tous les `EXCEPTION WHEN OTHERS THEN NULL` des deux scripts SQL.

### 0.4 — Signature de release · `VUL-05` · 3 h

Créer le keystore, `android/key.properties` (gitignoré), câbler `build.gradle.kts`, basculer `applicationId` sur `com.vodoohost.app`, régénérer `google-services.json` et déclarer le nouveau SHA-1 (Google Cloud Console + Supabase).

### 0.5 — Correctifs rapides · `VUL-06`, `VUL-07`, `VUL-20` · 2 h

- `AuthFlowType.implicit` → `AuthFlowType.pkce` (`supabase_service.dart:22`)
- Retirer `android:autoVerify="true"` du filtre à schéma personnalisé
- Créer la fonction RPC `search_rituels` et l'appeler depuis `ritual_repository.dart:106`
- Supprimer `disableEmailConfirmation` de la config

### 0.6 — Purge des traces sensibles · sous-ensemble de `VUL-08` · 2 h

Suppression ciblée, avant le remplacement global de la phase 1.4 :

| Fichier | Lignes |
|---|---|
| `core/services/kkiapay_service.dart` | 90-93 (clé API, payload, URL base64) |
| `main.dart` | 25-29 (email, expiration de session) |
| `auth_repository.dart` | 193 (`user_metadata` complet) |
| `booking/.../reservation_provider.dart` | 78-81, 93-97 (montant, email, téléphone) |

### ✅ Sortie de phase 0

- [ ] Aucun secret dans le code ni dans l'historique
- [ ] Rôle non manipulable par le client
- [ ] Tables financières en lecture seule pour le client
- [ ] APK de release signé avec un keystore dédié
- [ ] Flux PKCE actif
- [ ] Aucune donnée personnelle ni clé dans les logs

---

## 3. Phase 1 — Fondations (1 semaine)

### 1.1 — Configuration par `--dart-define-from-file` · §6.1 · 4 h

```json
// env/dev.json — gitignoré
{
  "SUPABASE_URL": "https://xxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ...",
  "KKIAPAY_PUBLIC_KEY": "...",
  "ENV": "dev"
}
```

```dart
// lib/core/config/env.dart
abstract final class Env {
  static const supabaseUrl      = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey  = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const kkiapayPublicKey = String.fromEnvironment('KKIAPAY_PUBLIC_KEY');
  static const _env             = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isProd => _env == 'prod';
  static bool get isDev  => _env == 'dev';

  /// Échoue au démarrage plutôt qu'au premier appel réseau.
  static void assertValid() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError('Configuration manquante : lancez avec --dart-define-from-file=env/dev.json');
    }
  }
}
```

```bash
flutter run   --dart-define-from-file=env/dev.json
flutter build appbundle --release --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols
```

Committer `env/dev.json.example` et `env/prod.json.example`.

### 1.2 — Flavors dev / staging / prod · §6.1 · 1 j

Trois `productFlavors` Android (suffixes `.dev`, `.stg`), trois schémas Xcode, trois projets Supabase distincts. Objectif : **plus jamais de test sur la base de production**.

### 1.3 — Lint par paliers · §3.1 · 4 h

Bascule immédiate vers `very_good_analysis` en neutralisant temporairement ce qui n'est pas encore traité :

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    avoid_print: error                      # ← durci dès la phase 1.4
    use_build_context_synchronously: error
    unrelated_type_equality_checks: error
    deprecated_member_use: warning          # 138 occurrences, traitées en phase 6
    public_member_api_docs: ignore          # réactivé en phase 6
    lines_longer_than_80_chars: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - build/**
```

**Paliers** : phase 1 → `avoid_print` en `error` · phase 3 → retrait de `strict-raw-types: ignore` · phase 6 → `deprecated_member_use` en `error`, `public_member_api_docs` réactivé.

Hooks pré-commit (`lefthook.yml`) : `dart format --set-exit-if-changed` + `flutter analyze`.

### 1.4 — Logger · `VUL-08` · §3.8 · 1 j

```dart
// lib/core/utils/app_logger.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

final appLogger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 8),
);
```

Substitution des 359 `print()` — et **suppression sans remplacement** de tout ce qui contient clé, email, téléphone, montant ou `user_metadata`.

**Critère d'acceptation** : `flutter analyze` ne remonte plus aucun `avoid_print`.

### 1.5 — Nettoyage des dépendances · `Q-11` · §6.8 · 2 h

**À retirer** (10 déclarées, 0 usage) : `dio`, `shared_preferences`, `hive`, `hive_flutter`, `cached_network_image`¹, `shimmer`¹, `flutter_svg`, `intl_phone_field`, `country_picker`, `sign_in_with_apple`.

¹ `cached_network_image` et `shimmer` seront **réintroduits et réellement utilisés** en phase 5.2 — les retirer maintenant clarifie l'inventaire.

**À ajouter** :

```yaml
dependencies:
  flutter_localizations: { sdk: flutter }
  flutter_secure_storage: ^9.2.2
  logger: ^2.4.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  sentry_flutter: ^8.9.0

dev_dependencies:
  very_good_analysis: ^6.0.0
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  mocktail: ^1.0.4
```

Nettoyer aussi les blocs commentés de `pubspec.yaml` (Stripe, Maps, notifications) et créer `assets/icons/` ou retirer sa déclaration.

### 1.6 — Suppression du code mort · `Q-10` · 1 h

- Supprimer `lib/core/services/kkiapay_payment_service.dart` (230 lignes commentées, contenant un faux paiement `Future.delayed(5s)` + succès forcé)
- Supprimer `lib/features/booking/presentation/pages/booking_page.dart` (remplacé par `booking_page_v2.dart`)
- Committer la suppression des 15 `.md` en attente dans `git status`

### ✅ Sortie de phase 1

- [ ] Aucune valeur de configuration en dur
- [ ] 3 flavors opérationnels
- [ ] `very_good_analysis` actif, 0 `avoid_print`
- [ ] 10 dépendances inutiles retirées
- [ ] Code mort supprimé

---

## 4. Phase 2 — Backend et intégrité des données (2 semaines)

> Phase la plus lourde et la plus structurante. C'est elle qui rend l'application réellement sûre.

### 2.1 — Edge Function de confirmation de paiement · `VUL-02` · 4 j

**Architecture cible**

```
App Flutter                Edge Function             KKiaPay        PostgreSQL
    │  widget de paiement                                │
    ├──────────────────────────────────────────────────►│
    │                          webhook                   │
    │                    ◄───────────────────────────────┤
    │                          ├─ vérifie le statut ────►│
    │                          ├─ recalcule le montant
    │                          └─ confirm_reservation() ──────────►│ (atomique)
    │  ◄─ realtime / polling ─────────────────────────────────────┤
```

**Étape A — fonction PL/pgSQL atomique** (`VUL-12`, `VUL-14`)

```sql
CREATE OR REPLACE FUNCTION confirm_reservation(
  p_logement_id int, p_user_id int,
  p_date_debut date, p_date_fin date,
  p_montant numeric, p_nb_voyageurs int,
  p_reference text, p_projet_id int DEFAULT NULL
) RETURNS reservations
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_res        reservations;
  v_pct        numeric;
  v_commission numeric;
  v_part_projet numeric := 0;
  v_hote_id    int;
  v_compte_id  int;
BEGIN
  SELECT val INTO v_pct FROM constances WHERE param = 'pourcentage';
  v_commission := p_montant * v_pct / 100;

  IF p_projet_id IS NOT NULL THEN
    SELECT p_montant * pourcentage_contribution / 100
      INTO v_part_projet FROM projets WHERE id = p_projet_id;
  END IF;

  INSERT INTO reservations (logement_id, user_id, date_debut, date_fin, montant,
                            nb_nuits, nb_voyageurs, mode_paiement, reference,
                            projet_id, statut)
  VALUES (p_logement_id, p_user_id, p_date_debut, p_date_fin, p_montant,
          p_date_fin - p_date_debut, p_nb_voyageurs, 'kkiapay', p_reference,
          p_projet_id, 'PAYE')
  RETURNING * INTO v_res;   -- la contrainte d'exclusion (2.2) protège du doublon

  INSERT INTO revenu_plateformes (reservation_id, commission, part_projet)
  VALUES (v_res.id, v_commission, v_part_projet);

  IF v_part_projet > 0 THEN
    INSERT INTO contributions (projet_id, reservation_id, montant_contribue, date_contribue)
    VALUES (p_projet_id, v_res.id, v_part_projet, CURRENT_DATE);
  END IF;

  SELECT user_id INTO v_hote_id FROM logements WHERE id = p_logement_id;

  INSERT INTO comptes (user_id, solde) VALUES (v_hote_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE comptes SET solde = solde + (p_montant - v_commission - v_part_projet)
  WHERE user_id = v_hote_id RETURNING id INTO v_compte_id;   -- atomique, pas de read-modify-write

  INSERT INTO transactions (montant, type, compte_id)
  VALUES (p_montant - v_commission - v_part_projet, 'credit', v_compte_id);

  RETURN v_res;
END $$;

REVOKE EXECUTE ON FUNCTION confirm_reservation FROM authenticated, anon;
```

**Étape B — Edge Function** : vérifie le statut auprès de KKiaPay avec la **clé privée** (variable d'environnement Supabase, jamais dans l'app), recalcule le montant attendu depuis `logements.prix_par_nuit`, rejette tout écart, puis appelle `confirm_reservation()` avec le `service_role`.

**Étape C — côté Flutter** : `reservation_repository.createReservation()` est vidé de toute logique financière. Il ne fait plus qu'attendre la confirmation (Supabase Realtime sur `reservations`, ou polling court sur la référence de transaction).

### 2.2 — Contrainte d'exclusion anti-double-réservation · `VUL-13` · 2 h

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE reservations ADD CONSTRAINT no_overlapping_reservations
EXCLUDE USING gist (
  logement_id WITH =,
  daterange(date_debut, date_fin, '[)') WITH &&
) WHERE (statut IN ('PAYE', 'CONFIRMEE'));
```

Le conflit devient structurellement impossible, quel que soit le comportement du client.

### 2.3 — Jeu de policies RLS complet · `VUL-04` · 3 j

Réécrire un fichier unique `supabase/migrations/0001_rls.sql`, **sans `EXCEPTION WHEN OTHERS`**, avec :

- **Référentiels** (`roles`, `pays`, `categories`, `divinites`, `rituels`…) : lecture publique, écriture interdite.
- **`logements`, `photos`, `avis`, `logement_disponibilites`** : lecture publique, écriture réservée au propriétaire.
- **`users`** : lecture complète réservée au propriétaire ; exposition des hôtes via une **vue** `public_profiles (id, nom, prenom, photo)` — résout l'incompatibilité relevée en `VUL-04`.
- **Tables financières** : `SELECT` du propriétaire uniquement, **aucune** écriture côté client.
- **`messages` / `conversations`** : accès limité aux participants.

Chaque policy est accompagnée d'un test d'intégration qui, avec la clé `anon`, tente l'écriture interdite et vérifie le refus.

### 2.4 — Recherche par RPC · `VUL-07` · 4 h

Remplacer `.or('titre.ilike.%$query%,...')` par la fonction `search_rituels(p_query text)`. Auditer les 2 autres `.or()` (`messaging_repository.dart:21,248`) : les valeurs y sont des `int`, donc sûres, mais à basculer sur RPC par cohérence.

### 2.5 — Uploads sécurisés · `VUL-09` · 4 h

Validation de taille (constante `maxUploadSizeMB` enfin utilisée), `maxWidth: 1920` + `imageQuality: 85` à la sélection, vérification des *magic bytes*, **suppression du repli silencieux vers le bucket `logements`**, et policies RLS sur les buckets Storage.

### 2.6 — Stockage sécurisé des sessions · `VUL-10` · 1 j

Implémenter un `SecureLocalStorage` adossé à `flutter_secure_storage` et l'injecter dans `Supabase.initialize`. Purger le stockage sensible au `signOut()`.

### ✅ Sortie de phase 2

- [ ] Aucun montant ni commission calculé côté client
- [ ] Paiement vérifié auprès de KKiaPay avant toute écriture
- [ ] Réservation atomique, double réservation impossible en base
- [ ] RLS complet, testé, sans masquage d'erreur
- [ ] Tokens en stockage chiffré

---

## 5. Phase 3 — Architecture (2 semaines)

### 3.1 — Arborescence cible · §1.3 · 2 j

```
lib/
  main.dart                    # bootstrap uniquement
  app.dart                     # ← À CRÉER : MaterialApp.router, thème, l10n
  core/
    config/        env.dart, flavors.dart
    di/            ← À CRÉER
    error/         ← À CRÉER : failure.dart, result.dart, error_mapper.dart
    network/       supabase_client.dart, connectivity.dart
    router/        app_router.dart, routes.dart, guards.dart
    theme/         app_theme.dart, app_colors.dart, app_spacing.dart, app_typography.dart
    utils/         app_logger.dart, formatters.dart, validators.dart, extensions/
    l10n/          ← À CRÉER : app_fr.arb, app_en.arb
  features/
    <feature>/
      data/
        models/          # DTO freezed + json_serializable
        services/        # ← À CRÉER : 1 classe par source (API, local)
        repositories/    # implémentations
      domain/
        entities/        # ← renommé depuis models/
        repositories/    # ← À CRÉER : interfaces abstraites
        usecases/        # ← uniquement si logique métier réelle
      presentation/
        screens/         # ← renommé depuis pages/
        widgets/
        viewmodels/      # ← renommé depuis providers/
  shared/
    widgets/       ← déplacé depuis core/widgets/
    extensions/
```

**Renommages** (mécaniques, un commit chacun) :

| Actuel | Cible | Volume |
|---|---|---|
| `presentation/pages/` | `presentation/screens/` | 15 features |
| `*_page.dart` | `*_screen.dart` | ~30 fichiers |
| `presentation/providers/` | `presentation/viewmodels/` | 15 fichiers |
| `domain/models/` | `domain/entities/` | 15 features |
| `core/widgets/` | `shared/widgets/` | 5 fichiers |

### 3.2 — Interfaces de repository · `Q-02` · §1.4 · 3 j

Le projet ne contient **aucune `abstract class`** : les ViewModels dépendent aujourd'hui des implémentations concrètes, ce qui rend les tests impossibles sans réseau.

```dart
// domain/repositories/reservation_repository.dart
abstract interface class ReservationRepository {
  Future<Result<Reservation>> create(CreateReservationParams params);
  Future<Result<List<Reservation>>> getUserReservations(int userId);
  Future<Result<bool>> checkAvailability({...});
}
```

```dart
// data/repositories/reservation_repository_impl.dart
final class ReservationRepositoryImpl implements ReservationRepository { ... }
```

```dart
final reservationRepositoryProvider = Provider<ReservationRepository>(
  (ref) => ReservationRepositoryImpl(ref.watch(supabaseServiceProvider)),
);
```

### 3.3 — `Result` et `Failure` · `VUL-17` · §3.4 · 3 j

Remplacer les 64 `throw Exception('Erreur ... : $e')` :

```dart
// core/error/failure.dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}
final class NetworkFailure      extends Failure { const NetworkFailure()      : super('Connexion indisponible'); }
final class ServerFailure       extends Failure { const ServerFailure(super.message); }
final class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Session expirée'); }
final class ValidationFailure   extends Failure { const ValidationFailure(super.message); }
final class PaymentFailure      extends Failure { const PaymentFailure(super.message); }

// core/error/result.dart
sealed class Result<T> { const Result(); }
final class Ok<T>  extends Result<T> { const Ok(this.value); final T value; }
final class Err<T> extends Result<T> { const Err(this.failure); final Failure failure; }
```

Mapping des exceptions techniques **dans la couche data uniquement** (`PostgrestException`, `AuthException`, `SocketException` → `Failure`), messages utilisateur localisés côté UI.

**Use cases justifiés** (§1.2 — seulement s'ils portent une vraie logique) : `CalculateBookingPriceUseCase`, `ValidateBookingDatesUseCase`, `DetermineUserRoleCapabilitiesUseCase`, `BuildSearchQueryUseCase`. Partout ailleurs, le ViewModel appelle le repository directement.

### 3.4 — Modèles `freezed` · `Q-08`, `Q-09` · §3.3 · 4 j

Migrer ~25 modèles. **Traiter d'abord les doublons** : fusionner les 3 `logement.dart` et les 2 `avis.dart` en une entité unique dans `features/accommodation/domain/entities/`.

```dart
@freezed
class Reservation with _$Reservation {
  const factory Reservation({
    required int id,
    required int logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double montant,
    required ReservationStatut statut,
  }) = _Reservation;

  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);
}
```

Remplacer les `statut` en `String` par des `enum` — cela élimine les comparaisons `'PAYE' || 'PAYÉ' || 'CONFIRMEE' || 'CONFIRMÉE'` de `reservation_repository.dart:332`.

### 3.5 — ViewModels sans `BuildContext` · §1.4 · 2 j

`reservation_provider.dart` reçoit aujourd'hui un `BuildContext` et appelle `Navigator.push` — un ViewModel ne doit connaître ni widget ni contexte (`VUL-16`, `Q-07`).

- Le lancement du widget KKiaPay remonte dans le `screen`.
- Le ViewModel expose un `AsyncValue<ReservationState>`, l'écran réagit via `ref.listen`.
- Ajouter `if (!context.mounted) return;` sur les 5 occurrences signalées.
- Réduire les 91 `setState` à l'état purement local (animations, focus, expansion de panneau).

### ✅ Sortie de phase 3

- [ ] Structure conforme au §1.3
- [ ] Une interface par repository, ViewModels mockables
- [ ] `Result`/`Failure` partout, 0 exception brute exposée
- [ ] Modèles `freezed` immuables, doublons fusionnés
- [ ] 0 `BuildContext` dans les ViewModels

---

## 6. Phase 4 — Tests et CI (1,5 semaine)

### 4.1 — Socle de test · 1 j

```
test/
  unit/     core/, features/<f>/domain/, features/<f>/data/
  widget/   features/<f>/presentation/
helpers/    pump_app.dart, mocks.dart, fixtures/
integration_test/
```

`mocktail` pour les mocks, `ProviderContainer` + `overrides` pour l'injection.

### 4.2 — Tests prioritaires · 4 j

Par ordre de valeur décroissante, **en commençant par ce qui touche l'argent** :

| Cible | Cas à couvrir |
|---|---|
| Calcul de commission | pourcentage nominal, 0 %, arrondis, contribution projet cumulée |
| Chevauchement de dates | bornes exactes, séjour englobant, séjour inclus, dates adjacentes (`[)`) |
| `checkAvailability` | hors période disponible, conflit avec réservation payée, statut annulé ignoré |
| `ValidateBookingDatesUseCase` | date passée, fin ≤ début, durée maximale |
| Mappers `fromJson` | champ null, type inattendu, enum inconnu |
| `AuthViewModel` | succès, mauvais identifiants, e-mail non confirmé, rate limit (`VUL-15`) |
| Validators | email, téléphone béninois, montant |

**Objectif** : 80 % sur `domain/` et `data/`.

### 4.3 — Widget tests · 2 j

Écrans critiques : login, signup, `booking_screen`, `search_screen` — dans chacun des trois états `loading` / `error` / `data`.

### 4.4 — Tests d'intégration · 2 j

Parcours de bout en bout : inscription → confirmation → connexion, et recherche → détail → réservation → paiement (sandbox KKiaPay).
**Plus les tests de sécurité RLS** : avec la clé `anon`, chaque écriture interdite doit être refusée (`reservations.statut`, `comptes.solde`, `users.role_id`).

### 4.5 — Pipeline CI · 1 j

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request, push]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.35.x', cache: true }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
  build:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo '${{ secrets.ENV_STAGING_JSON }}' > env/staging.json
          flutter build appbundle --flavor staging \
            --dart-define-from-file=env/staging.json \
            --obfuscate --split-debug-info=build/symbols
```

### ✅ Sortie de phase 4

- [ ] ≥ 80 % de couverture sur `domain/` et `data/`
- [ ] Parcours critiques couverts en intégration
- [ ] CI bloquante sur format, analyse et tests
- [ ] Tests RLS automatisés

---

## 7. Phase 5 — Performance (1 semaine)

### 5.1 — N+1 sur les conversations · `VUL-18` · §5.6 · 4 h

Remplacer la boucle `2N+1` de `messaging_repository.dart:28-41` par une vue SQL agrégeant dernier message et compteur de non-lus, et supprimer le `indexOf` en O(n²).

**Mesure attendue** : 41 requêtes → 1 ; ~4 s → < 400 ms pour 20 conversations.

### 5.2 — Images · §5.3 · 1 j

Réintroduire `cached_network_image` dans `AppImage` (aujourd'hui `Image.network` brut, donc re-téléchargement à chaque scroll), avec `memCacheWidth`/`memCacheHeight` calculés depuis la taille d'affichage, `shimmer` en placeholder, et redimensionnement côté serveur via les *image transformations* Supabase Storage.

### 5.3 — `autoDispose` · `VUL-19` · §5.9 · 4 h

Ajouter `autoDispose` sur les 69 providers, en conservant l'état global uniquement là où il est justifié (session, préférences). Vérifier les 26 `TextEditingController` contre les 17 `dispose()` (`Q-06`).

### 5.4 — Listes et calendrier · §5.2 · 1 j

- Basculer les 7 `ListView(` restants en `.builder`, ajouter `itemExtent` quand la hauteur est fixe, `ValueKey(item.id)` partout.
- `getDateStatuses()` (`reservation_repository.dart:360`) construit **730 entrées** (2 ans) à chaque ouverture du calendrier alors qu'un mois est affiché → restreindre à la fenêtre visible.
- Pagination API sur la recherche et la liste des logements.

### 5.5 — Rendu et démarrage · §5.4, §5.7 · 1 j

Auditer les 129 `Opacity` / `BackdropFilter` (les remplacer par `AnimatedOpacity` / `FadeTransition` dans les listes), ajouter `RepaintBoundary` sur les zones animées, alléger `main()` (initialisation paresseuse), installer `flutter_native_splash`.

### 5.6 — Mesure · §5.9 · 1 j

Profilage DevTools en mode `--profile` **sur un appareil bas de gamme réel** (pas sur émulateur) : parcours recherche, détail, réservation, messagerie. Relever le jank et les fuites mémoire.

### ✅ Sortie de phase 5

- [ ] Liste des conversations en 1 requête
- [ ] Images cachées et décodées à la taille d'affichage
- [ ] `autoDispose` généralisé, tous les controllers disposés
- [ ] Aucun jank > 16 ms sur les parcours principaux

---

## 8. Phase 6 — Qualité et finition (1,5 semaine)

### 6.1 — Localisation · `Q-04` · §3.7 · 3 j

Mettre en place `flutter_localizations` + `app_fr.arb` / `app_en.arb`, puis migrer les **190 chaînes en dur** et les 44 usages d'`AppStrings`. Priorité aux écrans d'authentification, de réservation et aux messages d'erreur (qui alimentent aussi `Failure` en phase 3.3).

### 6.2 — Thème · `Q-05` · §3.6 · 2 j

Les **667 accès directs à `AppColors`** contre 72 `Theme.of(context)` rendent le `darkTheme` déclaré dans `app_theme.dart` inopérant. Migrer vers `Theme.of(context).colorScheme` / `textTheme`, créer `AppSpacing`, puis activer `ThemeMode.system` dans `app.dart`.

### 6.3 — Extraction des widgets · `Q-03`, `Q-12` · §3.2 · 3 j

Convertir les **75 méthodes `_buildXxx()`** en `StatelessWidget` (meilleure granularité de rebuild, testabilité, `const`). Découper les fichiers les plus longs : `profile_page.dart` (1158 lignes), `booking_page_v2.dart` (766), `auth_repository.dart` (722). Passer `const` partout où c'est possible.

### 6.4 — Déprécations · `Q-01` · 1 j

Traiter les 138 `withOpacity` → `withValues(alpha:)`, puis passer `deprecated_member_use` en `error`.

### 6.5 — Documentation et ADR · §3.9 · 2 j

- `///` sur les API publiques, réactivation de `public_member_api_docs`
- `README.md` : setup, flavors, commandes, schéma d'architecture
- `docs/adr/` : 4 décisions à consigner — *Riverpod plutôt que Bloc*, *Result maison plutôt que dartz*, *logique financière côté serveur*, *pas de use case systématique*

### 6.6 — Durcissement final · §6.6, §6.7 · 2 j

- `--obfuscate --split-debug-info` intégré au pipeline, symbols archivés
- `android:usesCleartextTraffic="false"` explicite + ATS iOS
- `sentry_flutter` avec `beforeSend` **scrubbant** email, téléphone et montants
- Permissions demandées au moment de l'usage, avec explication
- `FLAG_SECURE` sur les écrans de paiement
- Revue RGPD : consentement, droit à l'effacement, minimisation
- Certificate pinning : **à évaluer**, l'app manipulant des flux financiers

### ✅ Sortie de phase 6

- [ ] 0 chaîne en dur dans l'UI
- [ ] Thème sombre fonctionnel
- [ ] 0 méthode `_buildXxx()`
- [ ] `flutter analyze --fatal-infos` : 0 problème
- [ ] Builds obfusqués, crash reporting avec scrubbing

---

## 9. Récapitulatif de charge

| Phase | Contenu | Charge | Cumul |
|---|---|---|---|
| **0** | Urgence sécurité | 3 j | 3 j |
| **1** | Fondations | 5 j | 8 j |
| **2** | Backend et intégrité | 10 j | 18 j |
| **3** | Architecture | 10 j | 28 j |
| **4** | Tests et CI | 8 j | 36 j |
| **5** | Performance | 5 j | 41 j |
| **6** | Qualité et finition | 8 j | 49 j |

**≈ 49 jours-homme** — 10 semaines à 1 développeur, 5 à 6 semaines à 2 développeurs en parallélisant les phases 3 à 6.

### Si le temps manque

**Périmètre minimal pour une mise en production défendable** : phases **0**, **2** et **4.2** (tests financiers uniquement) — soit **≈ 16 jours**. Les phases 1, 3, 5 et 6 sont de la dette technique : coûteuses à long terme, mais non bloquantes pour la sécurité des fonds et des données.

---

## 10. Suivi par jalon

| Jalon | Phases | Critère de validation |
|---|---|---|
| **J1 — Dépôt assaini** | 0 | Aucun secret exploitable, rôle non manipulable, release signé |
| **J2 — Données intègres** | 1-2 | Aucun calcul financier côté client, RLS testé |
| **J3 — Architecture conforme** | 3 | §1 et §3 du guide respectés |
| **J4 — Filet de sécurité** | 4 | CI verte, 80 % de couverture métier |
| **J5 — Production ready** | 5-6 | Checklist de sortie d'`AUDIT_SECURITE.md` intégralement cochée |

---

## 11. Risques du chantier

| Risque | Probabilité | Impact | Atténuation |
|---|---|---|---|
| La phase 0.3 interrompt le parcours de réservation | Certaine | Élevé | Assumé et annoncé ; rétabli en phase 2.1 sous 2 semaines |
| Le changement d'`applicationId` casse OAuth | Élevée | Moyen | Régénérer `google-services.json` + SHA-1 avant le déploiement ; valider en staging |
| La purge de l'historique Git perturbe l'équipe | Moyenne | Moyen | Planifier un créneau, faire re-cloner tout le monde |
| La migration `freezed` introduit des régressions | Moyenne | Moyen | Feature par feature, tests écrits avant migration |
| Charge sous-estimée sur les Edge Functions | Moyenne | Élevé | Commencer par le parcours de réservation seul, itérer |

---

## 12. Premier pas concret

```bash
git checkout -b fix/vul-01-rotate-db-credentials
# 1. Supabase Dashboard → Reset database password
# 2. Supprimer le bloc db* de lib/core/config/supabase_config.dart
# 3. Nettoyer .env.example, compléter .gitignore
git commit -m "fix(security): remove hardcoded database credentials

Supprime les identifiants superutilisateur PostgreSQL du code source
et de .env.example. Le mot de passe a été tourné côté Supabase.

Refs: VUL-01"
```
