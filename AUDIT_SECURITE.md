# Audit de sécurité et de conformité — VodooHost

> **Projet** : `vodou` (Flutter 3.9 / Dart 3.9, Supabase, KKiaPay)
> **Périmètre** : 123 fichiers Dart, ~26 950 lignes, configuration Android, scripts SQL Supabase
> **Date de l'audit** : 22 septembre 2026
> **Référentiel** : `Flutter — Bonnes pratiques professionnelles (2026)` + OWASP Mobile Top 10 (2024)

---

## 1. Résumé exécutif

**Statut : 🔴 NON DÉPLOYABLE EN PRODUCTION.**

L'architecture feature-first est saine et constitue une base solide. En revanche, **la totalité de la logique métier sensible (paiement, commissions, soldes, attribution des rôles) s'exécute côté client**, et des identifiants d'administration de la base de données sont présents en clair dans le dépôt Git. Ces deux points, à eux seuls, permettent respectivement le vol de fonds et la compromission complète des données utilisateurs.

### Répartition des vulnérabilités

| Sévérité | Nombre | Délai de correction attendu |
|---|---|---|
| 🔴 **Critique** | 5 | Immédiat — avant toute distribution |
| 🟠 **Élevée** | 6 | Avant mise en production |
| 🟡 **Moyenne** | 9 | Sous 2 à 4 semaines |
| 🔵 **Faible / Qualité** | 12 | Dette technique planifiée |
| | **32** | |

### Conformité au guide 2026

| § | Domaine | Conformité | Commentaire |
|---|---|---|---|
| 1 | Architecture | 🟡 45 % | Feature-first OK, mais aucune couche `domain` réelle (0 interface de repository) |
| 2 | Gestion d'état | 🟡 55 % | Riverpod seul et cohérent, mais 0 `autoDispose`, état mutable, 91 `setState` |
| 3 | Qualité de code | 🔴 25 % | 518 problèmes d'analyse, 359 `print()`, 0 `freezed`, 0 l10n |
| 4 | Tests | 🔴 0 % | Aucun test, aucun dossier `test/` |
| 5 | Performance | 🟡 40 % | N+1 réseau, images non cachées, listes non virtualisées |
| 6 | Sécurité | 🔴 15 % | Secrets versionnés, validation métier côté client, pas de stockage sécurisé |
| 7 | CI/CD | 🔴 0 % | Aucun pipeline, build release signé avec la clé de debug |

---

## 2. Conventions de lecture

**Sévérité** — 🔴 Critique · 🟠 Élevée · 🟡 Moyenne · 🔵 Faible
**Effort** — S (< 1 h) · M (1 j) · L (2-5 j) · XL (> 1 semaine)

Chaque fiche renvoie à la section du guide 2026 qu'elle viole (`§6.1`, `§5.2`…).

---

## 3. Vulnérabilités critiques

### VUL-01 · 🔴 Mot de passe superutilisateur PostgreSQL en clair dans le dépôt

| | |
|---|---|
| **Fichiers** | `lib/core/config/supabase_config.dart:12-17`, `.env.example:12` |
| **Règle violée** | §6.1 — *Aucun secret dans le code source* |
| **OWASP** | M1 — Improper Credential Usage |
| **Effort** | S (rotation) + M (purge de l'historique) |

**Constat**

```dart
// lib/core/config/supabase_config.dart
static const String dbHost     = 'aws-0-eu-west-2.pooler.supabase.com';
static const String dbPort     = 6543;
static const String dbUsername = 'postgres.vbfgfbqgtattrajdmeit';
static const String dbPassword = '<ANCIEN_MOT_DE_PASSE>';   // ⚠️ superutilisateur
```

Le même secret figure dans `.env.example`, fichier **versionné**, et se trouve dans l'historique Git depuis le commit `a0d4a45`.

**Impact**

Il s'agit du compte `postgres` (superutilisateur). Une connexion directe avec ces identifiants **ignore intégralement le Row Level Security** : lecture et écriture sur toutes les tables, y compris `users`, `messages`, `paiements`, `comptes`. Suppression de la base possible.

**Exploitation**

```bash
unzip -p app-release.apk lib/arm64-v8a/libapp.so | strings | grep -E '^[A-Za-z0-9]{16}$'
psql "postgresql://postgres.vbfgfbqgtattrajdmeit:<pwd>@aws-0-eu-west-2.pooler.supabase.com:6543/postgres"
```

**Correction**

1. **Rotation immédiate** : Supabase Dashboard → Settings → Database → *Reset database password*.
2. Supprimer intégralement le bloc `dbHost` / `dbPort` / `dbName` / `dbUsername` / `dbPassword` — une application Flutter ne se connecte **jamais** directement à PostgreSQL, elle passe par l'API REST Supabase.
3. Nettoyer `.env.example` de toute valeur réelle (ne garder que des placeholders).
4. Ajouter `.env` à `.gitignore` (absent aujourd'hui).
5. Purger l'historique :
   ```bash
   git filter-repo --replace-text <(echo '<ANCIEN_MOT_DE_PASSE>==>***REMOVED***')
   ```
   À défaut, considérer le dépôt comme compromis et en créer un nouveau.

> ℹ️ La clé `anon` en dur (`supabase_config.dart:8`) est **normale** : elle est conçue pour être publique. Sa sécurité repose entièrement sur le RLS — voir **VUL-04**.

---

### VUL-02 · 🔴 Absence de vérification serveur des paiements — réservations gratuites

| | |
|---|---|
| **Fichiers** | `lib/features/booking/presentation/providers/reservation_provider.dart:88-130`, `lib/features/booking/data/repositories/reservation_repository.dart:20-190` |
| **Règle violée** | §6.5 — *Règles métier (montants, droits, commissions) appliquées côté serveur* |
| **OWASP** | M4 — Insufficient Input/Output Validation |
| **Effort** | L |

**Constat**

L'intégralité de la chaîne financière est exécutée depuis le téléphone :

```dart
// reservation_provider.dart
onSuccess: (response, ctx) async {
  final transactionId = response['transactionId']?.toString() ?? '';
  final reservation = await _repository.createReservation(
    montant: montant,          // ← calculé par le client
    reference: transactionId,  // ← jamais confrontée à l'API KKiaPay
  );
}
```

Puis `createReservation()` enchaîne, toujours côté client :
calcul de la commission → insertion de la réservation avec `'statut': 'PAYE'` → écriture dans `revenu_plateformes` → **crédit de `comptes.solde` de l'hôte** → insertion dans `transactions`.

Le `transactionId` renvoyé par le widget n'est **jamais vérifié** auprès de KKiaPay (`GET /api/v1/transactions/status`).

**Impact**

Avec la clé `anon` extraite de l'APK, un attaquant peut appeler l'API Supabase directement pour :

- créer une réservation `statut = 'PAYE'` **sans aucun paiement** ;
- fixer `montant = 100 XOF` pour un séjour facturé 500 000 ;
- **créditer arbitrairement le solde de n'importe quel compte hôte**, puis demander un retrait ;
- fausser `revenu_plateformes` et les contributions aux projets communautaires.

**Correction**

Déplacer les étapes 1 à 9 de `createReservation` dans une **Edge Function Supabase** appelée par webhook KKiaPay :

```ts
// supabase/functions/confirm-reservation/index.ts
const tx = await fetch(`https://api.kkiapay.me/api/v1/transactions/status`, {
  method: 'POST',
  headers: { 'x-api-key': Deno.env.get('KKIAPAY_PRIVATE_KEY')! },  // jamais dans l'app
  body: JSON.stringify({ transactionId }),
}).then(r => r.json());

if (tx.status !== 'SUCCESS') throw new Error('Paiement non confirmé');

// Recalcul du montant côté serveur à partir de logements.prix_par_nuit
const attendu = nbNuits * logement.prix_par_nuit;
if (Math.abs(tx.amount - attendu) > 1) throw new Error('Montant incohérent');

// Écritures dans UNE transaction SQL (voir VUL-12)
```

Côté RLS, retirer au rôle `authenticated` tout droit `INSERT`/`UPDATE` sur `reservations`, `comptes`, `transactions`, `revenu_plateformes`, `contributions`.

---

### VUL-03 · 🔴 Élévation de privilèges — le rôle utilisateur est choisi par le client

| | |
|---|---|
| **Fichiers** | `lib/features/auth/data/repositories/auth_repository.dart:61`, `:198-222`, `:689` |
| **Règle violée** | §6.5 — *Le client n'est jamais une source de confiance* |
| **OWASP** | M3 — Insecure Authentication/Authorization |
| **Effort** | M |

**Constat**

```dart
// 1. L'inscription stocke le rôle dans user_metadata
await _supabase.auth.signUp(data: { 'role_id': roleId, /* ... */ });

// 2. La création du profil le relit et l'écrit tel quel
final roleId = metadata['role_id'] as int?;
await _supabase.from('users').insert({ 'role_id': roleId, /* ... */ });
```

`user_metadata` est **modifiable par l'utilisateur lui-même** via `auth.updateUser(data: {...})`.

**Exploitation**

```dart
await supabase.auth.updateUser(UserAttributes(data: {'role_id': 1})); // id admin
// puis déclencher la création du profil
```

**Correction**

1. Réactiver le trigger `SECURITY DEFINER` de `supabase_triggers_fix.sql:36`, qui force le rôle `Visiteur` côté serveur — et **ne pas** appliquer `supabase_triggers_remove.sql`.
2. Supprimer `role_id` de `user_metadata` et de `_createProfileFromMetadata()`.
3. Ajouter la policy RLS empêchant toute modification de `role_id` :
   ```sql
   CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE
   USING (auth.uid() = supabase_id)
   WITH CHECK (
     auth.uid() = supabase_id
     AND role_id = (SELECT role_id FROM public.users WHERE supabase_id = auth.uid())
     AND actif   = (SELECT actif   FROM public.users WHERE supabase_id = auth.uid())
   );
   ```
   (déjà rédigée dans `supabase_rls_policies.sql:31-37` — reste à l'appliquer)
4. Tout changement de rôle légitime (Visiteur → Hôte) passe par une Edge Function avec validation métier.

---

### VUL-04 · 🔴 Row Level Security vraisemblablement inactif + scripts qui masquent leurs erreurs

| | |
|---|---|
| **Fichiers** | `supabase_rls_all_tables.sql`, `supabase_rls_policies.sql` |
| **Règle violée** | §6.5 — *Valider côté client **et** côté serveur* |
| **OWASP** | M8 — Security Misconfiguration |
| **Effort** | L |

**Constat n°1 — incohérence entre les policies et le comportement réel de l'app**

| Policy écrite | Comportement observé dans le code |
|---|---|
| `users` : `SELECT USING (auth.uid() = supabase_id)` — profil personnel uniquement | `host_section.dart` affiche le profil des hôtes → impossible sous cette policy |
| `comptes`, `transactions`, `revenu_plateformes` : RLS activé, **aucune policy `INSERT`/`UPDATE`** | `reservation_repository.dart` y écrit systématiquement → échouerait à chaque réservation |

L'application fonctionnant, le RLS est **probablement désactivé en base**. Dans ce cas, la clé `anon` publique donne un accès **lecture et écriture libre à toutes les tables**.

**Constat n°2 — les scripts avalent silencieusement leurs erreurs**

```sql
DO $$
BEGIN
    EXECUTE 'CREATE POLICY ...';
    -- 14 autres policies
EXCEPTION WHEN OTHERS THEN NULL;   -- ⚠️ succès affiché même si TOUT échoue
END $$;
```

Un opérateur peut croire la base sécurisée alors qu'aucune policy n'a été créée.

**Correction**

1. Vérifier l'état réel :
   ```sql
   SELECT relname, relrowsecurity FROM pg_class
   WHERE relnamespace = 'public'::regnamespace AND relkind = 'r'
   ORDER BY relrowsecurity, relname;

   SELECT schemaname, tablename, policyname, cmd
   FROM pg_policies WHERE schemaname = 'public';
   ```
2. Retirer tous les `EXCEPTION WHEN OTHERS THEN NULL` — un échec doit faire échouer le script.
3. Reconstruire un jeu de policies **cohérent avec les écrans réels** :
   - `users` : lecture publique limitée aux colonnes non sensibles (via une vue `public_profiles` exposant `id, nom, prenom, photo`), lecture complète réservée au propriétaire ;
   - tables financières : **lecture seule** côté client, écriture réservée au `service_role`.
4. Rédiger un test d'intégration qui, avec la clé `anon`, tente chaque écriture interdite et vérifie le refus.

---

### VUL-05 · 🔴 Build de release signé avec le keystore de debug

| | |
|---|---|
| **Fichier** | `android/app/build.gradle.kts:37-41` |
| **Règle violée** | §7 — *Builds signés automatiquement, secrets en variables CI* |
| **OWASP** | M8 — Security Misconfiguration |
| **Effort** | M |

**Constat**

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

S'y ajoute `applicationId = "com.example.vodou"` — préfixe réservé aux exemples, refusé par le Play Store.

**Impact**

Le keystore de debug est **livré publiquement avec le SDK Android**. N'importe qui peut modifier l'application (retirer les contrôles, injecter du code) et la signer de manière à ce qu'Android l'accepte comme mise à jour légitime de l'application installée.

**Correction**

```bash
keytool -genkey -v -keystore ~/vodoohost-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias vodoohost
```

```properties
# android/key.properties — À AJOUTER AU .gitignore
storeFile=/chemin/vodoohost-release.jks
storePassword=...
keyAlias=vodoohost
keyPassword=...
```

```kotlin
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    namespace = "com.vodoohost.app"
    defaultConfig { applicationId = "com.vodoohost.app" }
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }
    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
}
```

⚠️ Le changement d'`applicationId` impose de **régénérer `google-services.json`** et de déclarer le nouveau SHA-1 dans Google Cloud Console (OAuth) et Supabase.

---

## 4. Vulnérabilités élevées

### VUL-06 · 🟠 Flux OAuth `implicit` + deep link non protégé → interception de session

| | |
|---|---|
| **Fichiers** | `lib/core/services/supabase_service.dart:22`, `android/app/src/main/AndroidManifest.xml:33-40` |
| **Règle violée** | §6.9 — *Valider les paramètres des deep links* · §6.4 |
| **Effort** | S |

```dart
authOptions: const FlutterAuthClientOptions(
  authFlowType: AuthFlowType.implicit,   // ⚠️ token dans l'URL
)
```

```xml
<intent-filter android:autoVerify="true">
    <data android:scheme="vodoohost" />   <!-- schéma non revendiqué, sans host ni path -->
</intent-filter>
```

En flux implicite, le **jeton d'accès transite dans le fragment de l'URL de redirection**. Le schéma `vodoohost://` n'appartient à personne : toute application malveillante installée peut le déclarer et **intercepter la session** à la confirmation d'email ou au retour OAuth. `android:autoVerify="true"` n'apporte rien ici — il ne s'applique qu'aux schémas `http`/`https` (App Links).

**Correction**

```dart
authFlowType: AuthFlowType.pkce,   // le token ne circule plus dans l'URL
```
Puis, à terme, migrer vers un App Link vérifié :
```xml
<data android:scheme="https" android:host="vodoohost.com" android:pathPrefix="/auth" />
```
avec le fichier `/.well-known/assetlinks.json` publié sur le domaine.

---

### VUL-07 · 🟠 Injection de filtre PostgREST dans la recherche de rituels

| | |
|---|---|
| **Fichier** | `lib/features/rituals/data/repositories/ritual_repository.dart:106` |
| **Règle violée** | §6.5 — *Échapper / sanitiser toute donnée externe* |
| **OWASP** | M4 |
| **Effort** | S |

```dart
.or('titre.ilike.%$query%,description.ilike.%$query%')
```

`query` est du texte libre saisi par l'utilisateur, interpolé **brut** dans une expression de filtre PostgREST. Une virgule, une parenthèse ou une clause du type `,id.gt.0` permettent de sortir de l'expression prévue et de réécrire la clause `WHERE`. Combiné à l'absence de RLS (**VUL-04**), cela permet l'exfiltration de lignes hors périmètre.

**Correction** — passer par une fonction RPC à paramètre typé :

```sql
CREATE OR REPLACE FUNCTION search_rituels(p_query text)
RETURNS SETOF rituels LANGUAGE sql STABLE AS $$
  SELECT * FROM rituels
  WHERE titre ILIKE '%' || p_query || '%'
     OR description ILIKE '%' || p_query || '%';
$$;
```

```dart
await _supabase.rpc('search_rituels', params: {'p_query': query});
```

> Les appels `.ilike('adresse', '%$x%')` (6 occurrences) sont **sûrs** : la valeur passe en paramètre échappé par le client. Seules les chaînes `.or(...)` construites à la main sont vulnérables.

---

### VUL-08 · 🟠 359 `print()` en production — fuite de secrets et de données personnelles

| | |
|---|---|
| **Fichiers** | 30 fichiers ; 348 signalés par l'analyseur |
| **Règle violée** | §3.8 — *pas de `print()`* · §6.3 — *Ne jamais logger les headers d'auth ni les données personnelles* |
| **OWASP** | M9 — Insecure Data Storage |
| **Effort** | M |

Sur Android, `print()` écrit dans **logcat**, lisible par d'autres applications sur appareil rooté et systématiquement capté par les outils de crash reporting.

Fuites confirmées :

| Fichier | Ligne | Donnée exposée |
|---|---|---|
| `core/services/kkiapay_service.dart` | 90-93 | **Clé API KKiaPay**, payload complet, URL base64 du paiement |
| `main.dart` | 26 | Email de l'utilisateur à chaque démarrage |
| `auth_repository.dart` | 193 | `user_metadata` complet : nom, téléphone, profession, rôle |
| `booking/.../reservation_provider.dart` | 78-81 | Montant, email, téléphone du payeur |

`kDebugMode` n'apparaît **nulle part** dans le projet.

**Correction**

```yaml
dependencies:
  logger: ^2.4.0
```

```dart
// lib/core/utils/app_logger.dart
final logger = Logger(
  filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0),
);
```

Puis substitution mécanique, avec **suppression pure et simple** des traces contenant clés, emails, téléphones ou montants.

---

### VUL-09 · 🟠 Uploads sans validation de taille ni de type

| | |
|---|---|
| **Fichier** | `lib/core/services/file_upload_service.dart:68-130` |
| **Règle violée** | §5.3, §6.5 |
| **Effort** | S |

- Aucun contrôle de taille — la constante `maxUploadSizeMB = 10` est **définie et jamais utilisée**.
- `readAsBytes()` charge **l'intégralité du fichier en mémoire** → risque d'OOM.
- `pickImage()` appelé sans `maxWidth` / `imageQuality` : une photo 12 Mpx (~8 Mo) part telle quelle.
- `contentType` déduit de l'extension, jamais du contenu réel (magic bytes).
- **Repli silencieux vers le bucket `logements`** (ligne 108) en cas d'échec : une photo de profil peut atterrir dans le mauvais bucket sans alerte.

**Correction**

```dart
final XFile? image = await _imagePicker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
);

const maxBytes = SupabaseConfig.maxUploadSizeMB * 1024 * 1024;
if (await file.length() > maxBytes) {
  throw const FileTooLargeFailure(maxUploadSizeMB);
}
```
Supprimer le repli vers `logements` : un échec d'upload doit remonter à l'appelant.

---

### VUL-10 · 🟠 Aucun stockage sécurisé ; `flutter_secure_storage` absent

| | |
|---|---|
| **Règle violée** | §6.2 — *`flutter_secure_storage` pour tokens et credentials* |
| **Effort** | M |

`shared_preferences` et `hive` sont déclarés dans `pubspec.yaml` mais **utilisés zéro fois**. La persistance de session repose entièrement sur le comportement par défaut de `supabase_flutter`, qui écrit dans `SharedPreferences` — donc **en clair** dans `/data/data/<pkg>/shared_prefs/`, lisible sur appareil rooté.

Aucune purge du stockage au logout n'est implémentée.

**Correction** — fournir un `LocalStorage` chiffré à Supabase :

```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
  authOptions: FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    localStorage: SecureLocalStorage(),   // adossé à flutter_secure_storage
  ),
);
```

---

### VUL-11 · 🟠 Aucun test automatisé sur du code qui manipule de l'argent

| | |
|---|---|
| **Règle violée** | §4 — *Logique métier couverte à 80 %+* |
| **Effort** | XL |

Aucun dossier `test/`, aucun fichier de test, aucune CI. Le calcul de commission, la répartition hôte/plateforme/projet et la détection de chevauchement de dates ne sont vérifiés par rien.

**Correction** — priorité aux tests unitaires listés dans le plan de correction (`PLAN_CORRECTIONS.md`, phase 4).

---

## 5. Vulnérabilités et défauts moyens

### VUL-12 · 🟡 `createReservation` : 11 écritures séquentielles sans transaction

`reservation_repository.dart:20-190` — si l'étape 8 (crédit du solde) échoue, la réservation et le revenu plateforme sont déjà enregistrés, **sans rollback possible**. Données financières durablement incohérentes.
**Correction** : tout regrouper dans une fonction PL/pgSQL unique (atomique par nature), appelée depuis l'Edge Function de **VUL-02**.

### VUL-13 · 🟡 Double réservation possible (TOCTOU)

`booking_page_v2.dart:644` — `checkAvailability()` est appelé à la sélection des dates, le paiement dure ~30 s, puis l'insertion se fait **sans nouvelle vérification**. Deux clients peuvent réserver le même logement aux mêmes dates.
**Correction** : contrainte d'exclusion PostgreSQL, qui rend le conflit structurellement impossible :

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE reservations ADD CONSTRAINT no_overlap
EXCLUDE USING gist (
  logement_id WITH =,
  daterange(date_debut, date_fin, '[)') WITH &&
) WHERE (statut IN ('PAYE', 'CONFIRMEE'));
```

### VUL-14 · 🟡 Race condition sur le solde de l'hôte

`reservation_repository.dart:157-165` — `solde` est lu puis réécrit (*read-modify-write*). Deux réservations simultanées : un des deux crédits est perdu.
**Correction** : `UPDATE comptes SET solde = solde + $1 WHERE id = $2`, ou traitement dans la fonction atomique de **VUL-12**.

### VUL-15 · 🟡 Deux branches de gestion d'erreur mortes

`auth_repository.dart:111` et `:113` — `e.statusCode` est un `String?` comparé à des `int` (`== 429`, `== 400`) : l'expression vaut **toujours `false`**. Les messages « Trop de tentatives » et le message d'erreur 400 personnalisé ne s'affichent jamais.
**Correction** : `e.statusCode == '429'`. Détecté par le lint `unrelated_type_equality_checks`.

### VUL-16 · 🟡 `BuildContext` utilisé après `await` sans garde `mounted`

5 occurrences, dont deux dans le **flux de paiement** (`reservation_provider.dart:120,124` — `Navigator.pop(ctx)` après une écriture réseau), et deux dans `profile_page.dart:587,598`. Crash si l'utilisateur quitte l'écran pendant l'opération.
**Correction** : `if (!context.mounted) return;` avant chaque usage.

### VUL-17 · 🟡 64 messages d'erreur exposent l'exception brute à l'utilisateur

Motif `throw Exception('Erreur ... : $e')` répété dans tous les repositories : divulgue les noms de tables, la structure PostgREST et les messages Postgres.
**Correction** : hiérarchie `Failure` scellée (§3.4) + messages localisés.

### VUL-18 · 🟡 N+1 réseau sur la liste des conversations

`messaging_repository.dart:28-41` — boucle appelant deux requêtes par conversation, soit **2N+1 aller-retours séquentiels** (41 requêtes pour 20 conversations, ≈ 4 s en 3G), plus un `conversations.indexOf(conversation)` **dans** la boucle (complexité O(n²)).
**Correction** : requête unique avec jointure, ou à défaut `Future.wait` + `asMap().entries`.

### VUL-19 · 🟡 Aucun `autoDispose` sur les 69 providers

Les 15 fichiers de providers ne contiennent **aucun** `autoDispose`. Résultats de recherche, détails de logement et listes de réservations restent en mémoire pour toute la durée de vie de l'application : fuite progressive et affichage de données périmées au retour sur un écran.

### VUL-20 · 🟡 Flag `disableEmailConfirmation` en dur dans la config

`supabase_config.dart:20-22` — accompagné du commentaire `/////// TODO: A supprimer en production ///////`. Actuellement `false`, mais un passage à `true` désactive la vérification d'email.
**Correction** : remplacer par un flavor (`Env.isDev`), jamais par une constante modifiable à la main.

---

## 6. Défauts de qualité (faible sévérité)

| # | Constat | Mesure | Règle |
|---|---|---|---|
| Q-01 | `flutter analyze` remonte **518 problèmes** (348 `avoid_print`, 138 `withOpacity` déprécié, 5 `use_build_context_synchronously`, 5 imports inutilisés, 2 comparaisons de types incompatibles) | 518 | §3.1 |
| Q-02 | **Aucune interface de repository** (`abstract class` : 0 occurrence) — la couche `domain` ne contient que des modèles, les ViewModels dépendent des implémentations concrètes | 0 | §1.4 |
| Q-03 | **75 méthodes `_buildXxx()`** au lieu de `StatelessWidget` extraits | 75 | §3.2 |
| Q-04 | **190 chaînes en dur** dans l'UI (`Text('...')`) contre 44 usages d'`AppStrings` ; aucun `flutter_localizations`, aucun `.arb` | 190 | §3.7 |
| Q-05 | **667 accès directs à `AppColors`** contre 72 `Theme.of(context)` — le thème sombre déclaré dans `app_theme.dart` est inopérant | 667 | §3.6 |
| Q-06 | **26 `TextEditingController`** pour seulement **17 `dispose()`** → fuites mémoire probables | 26 / 17 | §5.9 |
| Q-07 | **91 `setState`** sur 29 `StatefulWidget` en présence de Riverpod | 91 | §2 |
| Q-08 | Aucun `freezed` / `json_serializable` : `fromJson` écrits à la main, modèles mutables, pas de `copyWith` généré | 0 | §3.3 |
| Q-09 | **Modèles dupliqués** : `logement.dart` en **3 exemplaires** (`accommodation/`, `home/`, `booking/`), `avis.dart` en 2 | 5 | §1.3 |
| Q-10 | **Code mort** : `kkiapay_payment_service.dart` = 230 lignes **intégralement commentées**, contenant un « paiement simulé » (`Future.delayed(5s)` + succès forcé) à ne surtout pas réactiver ; `booking_page.dart` coexiste avec `booking_page_v2.dart` | 2 fichiers | §3.8 |
| Q-11 | **10 dépendances déclarées et jamais utilisées** : `dio`, `shared_preferences`, `hive`, `hive_flutter`, `cached_network_image`, `shimmer`, `flutter_svg`, `intl_phone_field`, `country_picker`, `sign_in_with_apple` | 10 | §6.8, §5.8 |
| Q-12 | Fichiers trop longs : `profile_page.dart` **1158 lignes**, `booking_page_v2.dart` 766, `auth_repository.dart` 722 | 3 | §3.2 |

**Autres constats mineurs**

- 20 `TODO` non traités, dont `// TODO: Implement OTP verification logic` (`otp_verification_page.dart:38`) alors que l'authentification par téléphone est annoncée active dans la config.
- `.env.example` décrit une configuration par variables d'environnement, mais aucun mécanisme de chargement n'existe (`flutter_dotenv` absent, `--dart-define` non utilisé) : tout est en dur.
- `assets/icons/` déclaré dans `pubspec.yaml` mais le dossier n'existe pas.
- Facebook activé dans `AndroidManifest.xml` avec `YOUR_FACEBOOK_APP_ID` en placeholder.
- Pas de `lib/app.dart` : `MaterialApp.router` est déclaré dans `main.dart`.
- Aucun flavor dev / staging / prod.
- `usesCleartextTraffic` non défini explicitement à `false`.
- Pas d'obfuscation (`--obfuscate --split-debug-info`) dans la procédure de build.
- 15 fichiers `.md` supprimés mais non committés (`git status`).

---

## 7. Checklist de sortie

Aucune distribution — même interne — avant que **toutes** ces cases soient cochées.

### Bloquants absolus

- [ ] **VUL-01** Mot de passe PostgreSQL tourné, bloc `db*` supprimé du code, historique Git purgé
- [ ] **VUL-02** Vérification KKiaPay côté serveur opérationnelle (Edge Function + webhook)
- [ ] **VUL-03** `role_id` retiré de `user_metadata`, trigger serveur actif
- [ ] **VUL-04** RLS activé et vérifié sur les 31 tables, écritures financières interdites au client
- [ ] **VUL-05** Keystore de release créé, `applicationId` définitif

### Avant production

- [ ] **VUL-06** `AuthFlowType.pkce`
- [ ] **VUL-07** Recherche de rituels via RPC
- [ ] **VUL-08** 0 `print()` restant (`dart analyze` sans `avoid_print`)
- [ ] **VUL-09** Validation taille + qualité des uploads
- [ ] **VUL-10** Tokens en `flutter_secure_storage`, purge au logout
- [ ] **VUL-12/13/14** Réservation atomique + contrainte d'exclusion + `solde = solde + x`
- [ ] **VUL-11** Tests unitaires sur commission, chevauchement de dates, disponibilité

### Hygiène

- [ ] `flutter analyze` : 0 erreur, 0 warning
- [ ] `--obfuscate --split-debug-info` dans la procédure de build
- [ ] Pipeline CI : `format` → `analyze` → `test` → `build`
- [ ] Crash reporting avec scrubbing des données personnelles

---

## 8. Suivi

Légende : ✅ corrigé · 🟨 partiellement corrigé · ⬜ à faire
*(Dernière mise à jour : 22 septembre 2026 — passe de correction automatisée)*

| ID | Sévérité | Titre | Effort | Statut | Reste à faire |
|---|---|---|---|---|---|
| VUL-01 | 🔴 | Mot de passe PostgreSQL versionné | S+M | 🟨 | **Rotation du mot de passe** + purge de l'historique Git (accès dashboard requis) |
| VUL-02 | 🔴 | Paiement non vérifié côté serveur | L | ⬜ | Edge Function + webhook KKiaPay |
| VUL-03 | 🔴 | Élévation de privilèges via `role_id` | M | ⬜ | Trigger SQL + policy RLS (accès base requis) |
| VUL-04 | 🔴 | RLS inactif / scripts silencieux | L | ⬜ | Exécution et vérification des policies |
| VUL-05 | 🔴 | Release signé en debug | M | 🟨 | Générer le keystore et créer `android/key.properties` |
| VUL-06 | 🟠 | OAuth implicit + deep link ouvert | S | ✅ | — (App Link `https` à prévoir à terme) |
| VUL-07 | 🟠 | Injection filtre PostgREST | S | 🟨 | Migrer vers la fonction RPC `search_rituels` |
| VUL-08 | 🟠 | 359 `print()` avec secrets | M | ✅ | — |
| VUL-09 | 🟠 | Uploads non validés | S | ✅ | Vérification des *magic bytes* (optionnelle) |
| VUL-10 | 🟠 | Pas de stockage sécurisé | M | ✅ | — (à valider à l'exécution) |
| VUL-11 | 🟠 | Aucun test | XL | 🟨 | 63 tests sur la logique financière ; reste l'UI et l'intégration |
| VUL-12 | 🟡 | Réservation non atomique | M | ⬜ | Fonction PL/pgSQL `confirm_reservation` |
| VUL-13 | 🟡 | Double réservation (TOCTOU) | S | ⬜ | Contrainte d'exclusion `btree_gist` |
| VUL-14 | 🟡 | Race sur le solde | S | ⬜ | `UPDATE comptes SET solde = solde + x` |
| VUL-15 | 🟡 | Branches d'erreur mortes | S | ✅ | — |
| VUL-16 | 🟡 | `BuildContext` après `await` | S | ✅ | — |
| VUL-17 | 🟡 | Exceptions brutes exposées | M | ✅ | — (couvert par un test de non-divulgation) |
| VUL-18 | 🟡 | N+1 conversations | S | 🟨 | Vue SQL agrégée (le parallélisme est en place) |
| VUL-19 | 🟡 | Providers sans `autoDispose` | S | ✅ | — (28 providers `family`) |
| VUL-20 | 🟡 | Flag `disableEmailConfirmation` | S | ✅ | — |
| Q-01 | 🔵 | 518 problèmes d'analyse | M | ✅ | **0 problème** (`flutter analyze`) |
| Q-02 | 🔵 | Aucune interface de repository | L | ⬜ | Phase 3.2 |
| Q-03 | 🔵 | 75 méthodes `_buildXxx()` | L | ⬜ | Phase 6.3 |
| Q-04 | 🔵 | 190 chaînes en dur, pas de l10n | L | ⬜ | Phase 6.1 |
| Q-05 | 🔵 | 667 `AppColors` directs | M | ⬜ | Phase 6.2 |
| Q-06 | 🔵 | Controllers non disposés | S | ⬜ | Audit manuel nécessaire |
| Q-07 | 🔵 | 91 `setState` | M | ⬜ | Phase 3.5 |
| Q-08 | 🔵 | Pas de `freezed` | L | ⬜ | Phase 3.4 |
| Q-09 | 🔵 | Modèles dupliqués | M | ⬜ | Phase 3.4 |
| Q-10 | 🔵 | Code mort | S | ✅ | — |
| Q-11 | 🔵 | 10 dépendances inutilisées | S | ✅ | — |
| Q-12 | 🔵 | Fichiers trop longs | M | ⬜ | Phase 6.3 |

Le plan de remédiation séquencé se trouve dans [PLAN_CORRECTIONS.md](PLAN_CORRECTIONS.md).

---

## 9. Journal des corrections appliquées

### Passe automatisée du 22 septembre 2026

Toutes les corrections réalisables **sans accès au dashboard Supabase ni à la base de données** ont été appliquées. Le projet compile (`flutter build bundle`) et `flutter analyze` ne remonte **aucun problème** (contre 518 avant la passe).

#### Secrets et configuration

| Fichier | Changement |
|---|---|
| `lib/core/config/supabase_config.dart` | Suppression de `dbHost`, `dbPort`, `dbName`, `dbUsername`, **`dbPassword`**. URL et clé déléguées à `Env`. |
| `lib/core/config/env.dart` | **Nouveau** — configuration via `String.fromEnvironment`, `assertValid()` qui échoue au démarrage si la config manque. |
| `lib/core/config/kkiapay_config.dart` | Clé publique déléguée à `Env` ; `isLive` dérivé de l'environnement de build au lieu d'une constante manuelle. |
| `.env.example` | Purgé de toute valeur réelle (placeholders uniquement). |
| `.gitignore` | Ajout de `.env`, `.env.*`, `env/*.json`, `android/key.properties`, `*.jks`, `*.keystore`, `build/symbols/`. |
| `env/dev.json.example`, `env/prod.json.example` | **Nouveaux** — gabarits `--dart-define-from-file`. |

#### Sécurité applicative

| Fichier | Changement |
|---|---|
| `lib/core/services/supabase_service.dart` | `AuthFlowType.implicit` → **`pkce`**. Journalisation de l'e-mail de session supprimée. |
| `android/app/src/main/AndroidManifest.xml` | `usesCleartextTraffic="false"`, `allowBackup="false"`, retrait de l'`autoVerify` trompeur, deep link restreint à `vodoohost://auth`. |
| `android/app/build.gradle.kts` | Configuration de signature de release via `key.properties`, avec avertissement Gradle explicite en cas de repli sur la clé de debug. |
| `android/key.properties.example` | **Nouveau** — procédure de génération du keystore. |
| `lib/features/rituals/.../ritual_repository.dart` | `_sanitizeFilterValue()` neutralise `, ( ) . % _ \ "` avant interpolation dans `.or(...)`. |
| `lib/core/services/file_upload_service.dart` | Contrôle de taille (`maxUploadSizeMB` enfin appliqué), liste blanche d'extensions, `maxWidth/maxHeight: 1920` + `imageQuality: 85`, **suppression du repli silencieux** vers le bucket `logements`. |

#### Journalisation

`lib/core/utils/app_logger.dart` **créé** — niveaux `d`/`i` compilés hors du binaire en release via `kDebugMode`.

**326 appels `print()` convertis** automatiquement (`❌` → `AppLogger.e`, `⚠️` → `AppLogger.w`, sinon `AppLogger.d`), et **11 traces sensibles supprimées manuellement** :

- clé API KKiaPay, payload de paiement, URL base64 du widget
- jetons Google (`accessToken`, `idToken`) — fuite la plus grave
- e-mail de session au démarrage, `user_metadata` complet
- montant, e-mail, téléphone et nom du payeur

**Résultat : 0 `print()` dans `lib/`.**

#### Bugs corrigés

| Fichier | Bug |
|---|---|
| `auth_repository.dart:109,113` | `e.statusCode == 429` → `== '429'` : `statusCode` est un `String?`, les deux branches étaient mortes (VUL-15). |
| `reservation_provider.dart` | `if (ctx.mounted)` avant `Navigator.pop` dans le flux de paiement (VUL-16). |
| `profile_page.dart`, `favorite_list_detail_page.dart` | Idem ; messenger capturé avant l'`await` sur le presse-papiers. |
| `messaging_repository.dart` | N+1 : `Future.wait` remplace la boucle séquentielle, `indexOf` en O(n²) éliminé (VUL-18). |
| `divinite_repository.dart` | Cast redondant supprimé. |

#### Qualité

- **28 `FutureProvider.family` → `autoDispose.family`** (VUL-19)
- **127 `withOpacity()` → `withValues(alpha:)`**
- `Radio.groupValue`/`onChanged` dépréciés → `RadioGroup` ancêtre
- `dart fix --apply` : 19 correctifs sur 13 fichiers
- **Fichiers supprimés** : `kkiapay_payment_service.dart` (230 lignes commentées contenant un faux paiement), `booking_page.dart` (remplacé par `_v2`)
- **10 dépendances inutilisées retirées** du `pubspec.yaml`, avec commentaire expliquant lesquelles réintroduire et quand
- 5 imports inutilisés supprimés, `assets/icons/` créé

### Seconde passe — VUL-10, VUL-11, VUL-17

Les trois vulnérabilités restantes ne dépendant ni de Supabase ni du keystore ont été traitées.

#### VUL-17 — Divulgation d'informations par les messages d'erreur ✅

| Fichier | Rôle |
|---|---|
| `lib/core/error/app_failure.dart` | **Nouveau** — hiérarchie scellée : `NetworkFailure`, `UnauthorizedFailure`, `NotFoundFailure`, `ValidationFailure`, `PaymentFailure`, `ConflictFailure`, `ServerFailure`. Chaque variante porte un message déjà rédigé pour l'utilisateur. |
| `lib/core/error/error_mapper.dart` | **Nouveau** — traduit `PostgrestException`, `AuthException`, `StorageException`, `FunctionException`, `SocketException` en `AppFailure`. Les codes SQLSTATE sont mappés (`23P01` → « ces dates viennent d'être réservées », `42501` → session invalide). Le détail brut part dans `AppLogger`, jamais à l'écran. |

- **67 `throw Exception('... : $e')` assainis** dans les 13 repositories : la sortie ne contient plus l'exception source.
- **22 affichages bruts remplacés** dans l'UI par `ErrorMapper.toMessage(error)`.
- Vérifié par un test dédié : 7 erreurs Supabase réalistes sont passées au mapper, et 18 fragments interdits (`supabase`, `postgrest`, `row-level`, `comptes`, `reservations`, `public.`, `.supabase.co`…) sont cherchés dans chaque message produit.

#### VUL-10 — Jetons de session en clair ✅

`lib/core/services/secure_local_storage.dart` **créé** : implémentation de `LocalStorage` adossée au **Keystore Android** et au **Keychain iOS** via `flutter_secure_storage`, injectée dans `Supabase.initialize`.

- **Migration automatique** : une session déjà présente dans `SharedPreferences` est déplacée vers le stockage chiffré au premier lancement, puis l'original en clair est effacé. Les utilisateurs connectés ne sont pas déconnectés.
- **Purge au logout** : `SupabaseService.signOut()` appelle `purgeAll()`, et `AuthRepository.signOut()` passe désormais par ce chemin.
- **Dégradation contrôlée** : si le Keystore est inutilisable, repli sur `SharedPreferences` avec un avertissement journalisé, plutôt qu'une impossibilité de se connecter.
- `minSdk` du projet : **24** — compatible avec `encryptedSharedPreferences: true` (requiert 23+).

#### VUL-11 — Absence de tests 🟨

**63 tests, tous au vert.** La logique métier a d'abord été extraite des repositories, où elle était mêlée aux appels réseau :

| Fichier créé | Contenu |
|---|---|
| `lib/features/booking/domain/booking_pricing.dart` | Calcul du montant, du nombre de nuits et répartition commission / projet / hôte. Fonctions pures. |
| `lib/features/booking/domain/date_range_rules.dart` | Chevauchement de périodes, statuts bloquants, validation de séjour. Branché dans `ReservationRepository.checkAvailability`. |

| Fichier de test | Cas |
|---|---|
| `test/unit/booking/booking_pricing_test.dart` | 18 — dont « la somme des parts égale toujours le total » sur 16 combinaisons, « l'hôte n'est jamais débité », refus d'un cumul de pourcentages > 100 % |
| `test/unit/booking/date_range_rules_test.dart` | 24 — dont les séjours adjacents (départ le jour de l'arrivée suivante = pas de conflit), la symétrie de la relation sur 36 paires, les statuts accentués |
| `test/unit/booking/reservation_model_test.dart` | 9 — mapper `fromJson`, champs optionnels, échec explicite sur donnée manquante |
| `test/unit/core/error_mapper_test.dart` | 11 — classification + garde-fou de non-divulgation |

`.github/workflows/ci.yml` **créé** : trois jobs — qualité (`format` → `analyze --fatal-infos` → `test --coverage`), **détection de secrets** (échoue si un identifiant de base, une clé privée ou un `print()` réapparaît), et build App Bundle obfusqué.

**Reste à couvrir** : widget tests des écrans critiques, tests d'intégration du parcours de réservation, tests RLS (ceux-ci figurent à l'étape 13 du runbook).

#### État des portes de qualité

```
dart format --set-exit-if-changed  →  0 fichier à reformater
flutter analyze --fatal-infos      →  No issues found!
flutter test                       →  63/63 passés
flutter build bundle               →  succès
```

### Ce qui n'a pas pu être fait ici

Ces points exigent un accès au dashboard Supabase, à la base de données, une clé secrète ou une coordination d'équipe. **Le SQL et le code sont écrits** : voir [RUNBOOK_SUPABASE.md](RUNBOOK_SUPABASE.md).

1. **Rotation du mot de passe PostgreSQL** et purge de l'historique Git (VUL-01) — runbook, étape 2
2. **Edge Function de vérification KKiaPay** (VUL-02) — runbook, étape 9
3. **Policies RLS** et trigger de création de profil (VUL-03, VUL-04) — runbook, étapes 4 et 5
4. **Génération du keystore de release** et changement d'`applicationId` (VUL-05) — `android/key.properties.example`
5. **Fonction PL/pgSQL atomique**, contrainte d'exclusion, correction du solde (VUL-12/13/14) — runbook, étapes 6 et 7
6. **Validation à l'exécution** — aucune de ces corrections n'a été testée sur un appareil. Les changements de comportement à vérifier en priorité : flux PKCE, migration du stockage de session, deep link, `usesCleartextTraffic`.
