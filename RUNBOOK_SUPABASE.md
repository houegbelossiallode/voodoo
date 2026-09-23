# Runbook Supabase — sécurisation de VodooHost

> **Public** : la personne qui a accès au dashboard Supabase du projet.
> **Objectif** : fermer les vulnérabilités `VUL-01` à `VUL-04`, `VUL-07`, `VUL-12`, `VUL-13`, `VUL-14` décrites dans [AUDIT_SECURITE.md](AUDIT_SECURITE.md).
> **Durée** : 3 à 5 heures si tout se passe bien, une journée avec les vérifications.
> **Prérequis** : rôle *Owner* sur le projet Supabase, Node.js et la CLI Supabase installés.

---

## ⚠️ À lire avant de commencer

### Cette procédure interrompt le parcours de réservation

Les étapes 4 à 6 retirent au client le droit d'écrire dans les tables financières. **Tant que l'étape 8 (Edge Function) n'est pas déployée, aucune réservation ne peut aboutir.** C'est voulu : aujourd'hui n'importe qui peut réserver sans payer.

Si l'application est déjà en production avec des utilisateurs réels, planifie une fenêtre de maintenance et fais les étapes 1 à 8 **d'une traite**.

### Ordre non négociable

```
1. Sauvegarde              ← ne jamais sauter
2. Rotation mot de passe
3. Audit du schéma         ← détermine si le reste est applicable tel quel
4. Trigger de profil
5. RLS
6. Contrainte anti-doublon
7. Fonction atomique
8. Edge Function KKiaPay   ← rétablit le parcours de réservation
9. Storage
10. Réglages Auth
11. Côté application Flutter
12. Tests d'intrusion
```

### Une hypothèse que tu dois vérifier

Le code Flutter suppose une structure de tables que je n'ai **pas pu inspecter** (je n'ai eu accès qu'au code, pas à la base). L'**étape 3** te fait vérifier chaque hypothèse avant d'exécuter quoi que ce soit de destructeur. Si une vérification échoue, adapte le SQL plutôt que de le lancer tel quel.

---

## Étape 1 — Sauvegarde

Dashboard → **Database** → **Backups** → *Create backup* (ou, sur le plan gratuit, un export manuel) :

```bash
# Depuis ta machine, avec les identifiants ACTUELS (avant rotation)
pg_dump "postgresql://postgres.vbfgfbqgtattrajdmeit:<MOT_DE_PASSE_ACTUEL>@aws-0-eu-west-2.pooler.supabase.com:6543/postgres" \
  --no-owner --no-privileges -Fc -f vodoohost_backup_$(date +%Y%m%d).dump
```

Vérifie que le fichier fait plus de quelques kilooctets avant de continuer.

---

## Étape 2 — Rotation du mot de passe PostgreSQL · `VUL-01`

**Dashboard → Settings → Database → Reset database password.**

Génère un mot de passe long et aléatoire (32 caractères minimum), stocke-le dans un gestionnaire de mots de passe. **Ne le mets nulle part dans le dépôt.**

L'ancien mot de passe (`<ANCIEN_MOT_DE_PASSE>`) était en clair dans `lib/core/config/supabase_config.dart` et dans `.env.example`, tous deux versionnés. Il a été retiré du code, mais il reste dans l'historique Git.

### Purge de l'historique Git — à faire aussi

```bash
pip install git-filter-repo

cd "chemin/vers/voodoo"
printf '<ANCIEN_MOT_DE_PASSE>==>***REMOVED***\n' > /tmp/secrets.txt
git filter-repo --replace-text /tmp/secrets.txt --force

git push --force --all
git push --force --tags
rm /tmp/secrets.txt
```

> ⚠️ Prévient l'équipe : après un `filter-repo`, **tout le monde doit re-cloner**. Un `git pull` sur un ancien clone réintroduirait les commits purgés.

Vérification :

```bash
git log -S '<ANCIEN_MOT_DE_PASSE>' --all    # doit ne rien retourner
```

---

## Étape 3 — Audit du schéma existant

Lance ces requêtes dans **SQL Editor** et garde les résultats sous les yeux pour la suite.

### 3.1 — État actuel du RLS

```sql
SELECT relname AS table_name,
       relrowsecurity AS rls_active,
       (SELECT count(*) FROM pg_policies p
         WHERE p.schemaname = 'public' AND p.tablename = c.relname) AS nb_policies
FROM pg_class c
WHERE relnamespace = 'public'::regnamespace AND relkind = 'r'
ORDER BY relrowsecurity, relname;
```

**Lecture du résultat** : si la colonne `rls_active` est `false` sur `users`, `reservations`, `comptes` ou `transactions`, alors la clé `anon` publique de ton APK donne actuellement un accès **lecture et écriture libre** à ces tables. C'est le scénario que l'audit jugeait le plus probable.

### 3.2 — Hypothèses structurelles à confirmer

```sql
-- a) comptes.user_id doit être UNIQUE (requis par l'étape 7)
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.comptes'::regclass;

-- b) Type des clés primaires (le code Flutter suppose des int)
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('users','logements','reservations','comptes','projets')
  AND column_name IN ('id','user_id','logement_id','supabase_id','role_id')
ORDER BY table_name, column_name;

-- c) Valeurs de statut réellement présentes
SELECT statut, count(*) FROM public.reservations GROUP BY statut;
SELECT statut, count(*) FROM public.logement_disponibilites GROUP BY statut;

-- d) La constante de commission existe-t-elle ?
SELECT * FROM public.constances WHERE param = 'pourcentage';

-- e) Rôle par défaut
SELECT id, libelle, actif FROM public.roles ORDER BY id;
```

### 3.3 — Si `comptes.user_id` n'est pas unique

L'étape 7 en a besoin. Corrige d'abord les doublons éventuels, puis ajoute la contrainte :

```sql
-- Repérer les doublons
SELECT user_id, count(*), sum(solde)
FROM public.comptes GROUP BY user_id HAVING count(*) > 1;

-- ⚠️ À adapter : fusionne manuellement les soldes avant de dédupliquer.
ALTER TABLE public.comptes ADD CONSTRAINT comptes_user_id_key UNIQUE (user_id);
```

### 3.4 — Données de test à nettoyer

Avant de verrouiller, repère les réservations créées sans paiement réel pendant le développement :

```sql
SELECT r.id, r.reference, r.montant, r.statut, r.created_at
FROM public.reservations r
WHERE r.mode_paiement = 'kkiapay'
ORDER BY r.created_at DESC;
```

Toute ligne dont la `reference` ne correspond pas à une transaction KKiaPay réelle est une réservation frauduleuse ou de test. Elles ont crédité des soldes : décide de les supprimer et de recalculer les soldes concernés.

---

## Étape 4 — Trigger de création de profil · `VUL-03`

**Le problème** : aujourd'hui le profil est créé côté client avec un `role_id` lu depuis `user_metadata`, que l'utilisateur peut modifier lui-même via `auth.updateUser()`. Il peut donc s'attribuer n'importe quel rôle.

**La correction** : la création de profil passe côté serveur, avec le rôle forcé.

```sql
-- ============================================================================
-- VUL-03 — Création de profil côté serveur, rôle non manipulable
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role_id  int;
  v_meta     jsonb;
  v_prenom   text;
  v_nom      text;
  v_fullname text;
BEGIN
  -- Ne rien faire si le profil existe déjà
  IF EXISTS (SELECT 1 FROM public.users WHERE supabase_id = NEW.id) THEN
    RETURN NEW;
  END IF;

  -- Rôle FORCÉ à « Visiteur » : jamais lu depuis les métadonnées client.
  SELECT id INTO v_role_id FROM public.roles WHERE libelle = 'Visiteur' LIMIT 1;
  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'Rôle « Visiteur » introuvable dans public.roles';
  END IF;

  v_meta := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);

  v_prenom   := NULLIF(TRIM(COALESCE(v_meta->>'prenom',
                                     v_meta->>'given_name',
                                     v_meta->>'first_name', '')), '');
  v_nom      := NULLIF(TRIM(COALESCE(v_meta->>'nom',
                                     v_meta->>'family_name',
                                     v_meta->>'last_name', '')), '');
  v_fullname := NULLIF(TRIM(COALESCE(v_meta->>'full_name',
                                     v_meta->>'name', '')), '');

  -- Reconstruction depuis le nom complet si besoin
  IF v_prenom IS NULL AND v_fullname IS NOT NULL THEN
    v_prenom := split_part(v_fullname, ' ', 1);
  END IF;
  IF v_nom IS NULL AND v_fullname IS NOT NULL AND position(' ' in v_fullname) > 0 THEN
    v_nom := TRIM(substring(v_fullname from position(' ' in v_fullname) + 1));
  END IF;

  v_prenom := COALESCE(v_prenom, 'Nouveau');
  v_nom    := COALESCE(v_nom, 'Utilisateur');

  INSERT INTO public.users (
    supabase_id, nom, prenom, email, telephone, profession,
    langue, passions, bio, photo, actif, role_id, created_at
  ) VALUES (
    NEW.id,
    v_nom,
    v_prenom,
    NEW.email,
    COALESCE(v_meta->>'telephone', ''),
    COALESCE(v_meta->>'profession', ''),
    ARRAY['fr'],
    ARRAY[]::text[],
    NULLIF(v_meta->>'bio', ''),
    COALESCE(v_meta->>'avatar_url', v_meta->>'picture'),
    'OUI',
    v_role_id,          -- ← forcé, jamais v_meta->>'role_id'
    now()
  )
  ON CONFLICT (supabase_id) DO NOTHING;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_create_user_profile_on_auth_user ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

> **Note** : `raw_user_meta_data` est le nom correct de la colonne (l'ancien script utilisait `user_metadata`, qui n'existe pas sur `auth.users` — c'est probablement pourquoi le trigger avait été retiré).

### Changement de rôle légitime (Visiteur → Hôte)

Le rôle ne pouvant plus être choisi à l'inscription, il faut une voie contrôlée :

```sql
CREATE OR REPLACE FUNCTION public.request_role_change(p_role_libelle text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role_id int;
  v_user_id int;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE supabase_id = auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Profil introuvable';
  END IF;

  -- Liste blanche : seuls ces rôles sont demandables par l'utilisateur.
  IF p_role_libelle NOT IN ('Visiteur', 'Hote', 'Hôte') THEN
    RAISE EXCEPTION 'Rôle non autorisé';
  END IF;

  SELECT id INTO v_role_id FROM public.roles
  WHERE libelle = p_role_libelle AND actif = 'OUI';
  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'Rôle inconnu ou inactif';
  END IF;

  UPDATE public.users SET role_id = v_role_id, updated_at = now()
  WHERE id = v_user_id;
END $$;

REVOKE EXECUTE ON FUNCTION public.request_role_change FROM anon;
GRANT  EXECUTE ON FUNCTION public.request_role_change TO authenticated;
```

Adapte la liste blanche au libellé exact renvoyé par la requête 3.2(e).

---

## Étape 5 — Row Level Security complet · `VUL-04`

Copie ce bloc **en entier** dans SQL Editor. Il ne contient volontairement **aucun `EXCEPTION WHEN OTHERS`** : si quelque chose échoue, tu dois le voir.

```sql
-- ============================================================================
-- VUL-04 — RLS complet
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Fonction utilitaire : id applicatif de l'utilisateur courant
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_app_user_id()
RETURNS int
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$ SELECT id FROM public.users WHERE supabase_id = auth.uid() $$;

GRANT EXECUTE ON FUNCTION public.current_app_user_id() TO anon, authenticated;

-- ----------------------------------------------------------------------------
-- 5.2 Activation du RLS partout
-- ----------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','roles','pays','categories','type_logements','equipements',
    'logements','divinites','rituels','avis','projets','messages',
    'conversations','pointforts','favorites','favori_logements','constances',
    'equipement_logement','divinite_logement','rituel_logement','photos',
    'logement_disponibilites','reservations','contributions','paiements',
    'notifications','user_preferences','comptes','transactions',
    'revenu_plateformes'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_class
               WHERE relname = t AND relnamespace = 'public'::regnamespace) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t);
    ELSE
      RAISE NOTICE 'Table absente, ignorée : %', t;
    END IF;
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 5.3 Référentiels — lecture publique, écriture interdite
-- ----------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'roles','pays','categories','type_logements','equipements','divinites',
    'rituels','projets','pointforts','photos','constances',
    'equipement_logement','divinite_logement','rituel_logement'
  ] LOOP
    IF EXISTS (SELECT 1 FROM pg_class
               WHERE relname = t AND relnamespace = 'public'::regnamespace) THEN
      EXECUTE format('DROP POLICY IF EXISTS "public_read_%s" ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY "public_read_%s" ON public.%I FOR SELECT TO anon, authenticated USING (true)',
        t, t);
    END IF;
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 5.4 users — profil complet pour soi, vue publique pour les hôtes
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public profile read"        ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "User update own profile"    ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;

CREATE POLICY "users_select_own" ON public.users
FOR SELECT TO authenticated
USING (supabase_id = auth.uid());

-- Le profil public d'un hôte passe par une VUE, jamais par la table :
-- cela évite d'exposer email, téléphone et profession de tous les comptes.
CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = false) AS
SELECT u.id, u.nom, u.prenom, u.photo, u.bio, u.created_at
FROM public.users u
WHERE u.actif = 'OUI';

GRANT SELECT ON public.public_profiles TO anon, authenticated;

-- Mise à jour : ni le rôle, ni l'état actif, ni le rattachement auth
CREATE POLICY "users_update_own" ON public.users
FOR UPDATE TO authenticated
USING (supabase_id = auth.uid())
WITH CHECK (
  supabase_id = auth.uid()
  AND role_id  = (SELECT role_id FROM public.users WHERE supabase_id = auth.uid())
  AND actif    = (SELECT actif   FROM public.users WHERE supabase_id = auth.uid())
);

-- Aucune policy INSERT : seul le trigger de l'étape 4 crée les profils.
-- Aucune policy DELETE : la suppression de compte passe par une fonction dédiée.

-- ----------------------------------------------------------------------------
-- 5.5 logements / disponibilités / avis — lecture publique, écriture au propriétaire
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public read logements"       ON public.logements;
DROP POLICY IF EXISTS "Host update own logement"    ON public.logements;
DROP POLICY IF EXISTS "Public read disponibilites"  ON public.logement_disponibilites;
DROP POLICY IF EXISTS "Host manage own disponibilites" ON public.logement_disponibilites;
DROP POLICY IF EXISTS "Public read avis"            ON public.avis;

CREATE POLICY "logements_public_read" ON public.logements
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "logements_owner_insert" ON public.logements
FOR INSERT TO authenticated
WITH CHECK (user_id = public.current_app_user_id());

CREATE POLICY "logements_owner_update" ON public.logements
FOR UPDATE TO authenticated
USING (user_id = public.current_app_user_id())
WITH CHECK (user_id = public.current_app_user_id());

CREATE POLICY "logements_owner_delete" ON public.logements
FOR DELETE TO authenticated
USING (user_id = public.current_app_user_id());

CREATE POLICY "dispo_public_read" ON public.logement_disponibilites
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "dispo_owner_all" ON public.logement_disponibilites
FOR ALL TO authenticated
USING (logement_id IN (SELECT id FROM public.logements
                       WHERE user_id = public.current_app_user_id()))
WITH CHECK (logement_id IN (SELECT id FROM public.logements
                            WHERE user_id = public.current_app_user_id()));

CREATE POLICY "avis_public_read" ON public.avis
FOR SELECT TO anon, authenticated USING (true);

-- Un avis n'est déposable que par un voyageur ayant réellement séjourné.
CREATE POLICY "avis_insert_after_stay" ON public.avis
FOR INSERT TO authenticated
WITH CHECK (
  user_id = public.current_app_user_id()
  AND EXISTS (
    SELECT 1 FROM public.reservations r
    WHERE r.logement_id = avis.logement_id
      AND r.user_id     = public.current_app_user_id()
      AND r.statut IN ('PAYE','CONFIRMEE')
      AND r.date_fin <= CURRENT_DATE
  )
);

-- ----------------------------------------------------------------------------
-- 5.6 reservations — lecture voyageur + hôte, AUCUNE écriture client
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "User read own reservations"        ON public.reservations;
DROP POLICY IF EXISTS "User create own reservations"      ON public.reservations;
DROP POLICY IF EXISTS "Users can view relevant reservations" ON public.reservations;
DROP POLICY IF EXISTS "Users can create own reservations" ON public.reservations;

CREATE POLICY "reservations_select_related" ON public.reservations
FOR SELECT TO authenticated
USING (
  user_id = public.current_app_user_id()
  OR logement_id IN (SELECT id FROM public.logements
                     WHERE user_id = public.current_app_user_id())
);

-- ⚠️ Volontairement AUCUNE policy INSERT / UPDATE / DELETE.
-- Toute création passe par confirm_reservation() (étape 7), appelée par
-- l'Edge Function avec le service_role. C'est le cœur de la correction VUL-02.

-- ----------------------------------------------------------------------------
-- 5.7 Tables financières — lecture seule pour le propriétaire
-- ----------------------------------------------------------------------------
CREATE POLICY "comptes_select_own" ON public.comptes
FOR SELECT TO authenticated
USING (user_id = public.current_app_user_id());

CREATE POLICY "transactions_select_own" ON public.transactions
FOR SELECT TO authenticated
USING (compte_id IN (SELECT id FROM public.comptes
                     WHERE user_id = public.current_app_user_id()));

CREATE POLICY "contributions_select_own" ON public.contributions
FOR SELECT TO authenticated
USING (reservation_id IN (SELECT id FROM public.reservations
                          WHERE user_id = public.current_app_user_id()));

-- revenu_plateformes : donnée interne, aucun accès client.
-- paiements : idem si la table est alimentée côté serveur.

-- ----------------------------------------------------------------------------
-- 5.8 Messagerie
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users view own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users create conversations"   ON public.conversations;
DROP POLICY IF EXISTS "Users read own messages"      ON public.messages;
DROP POLICY IF EXISTS "Users send own messages"      ON public.messages;

CREATE POLICY "conversations_select_participant" ON public.conversations
FOR SELECT TO authenticated
USING (visiteur_id = public.current_app_user_id()
    OR hote_id     = public.current_app_user_id());

CREATE POLICY "conversations_insert_participant" ON public.conversations
FOR INSERT TO authenticated
WITH CHECK (visiteur_id = public.current_app_user_id());

CREATE POLICY "conversations_update_participant" ON public.conversations
FOR UPDATE TO authenticated
USING (visiteur_id = public.current_app_user_id()
    OR hote_id     = public.current_app_user_id());

CREATE POLICY "messages_select_participant" ON public.messages
FOR SELECT TO authenticated
USING (conversation_id IN (
  SELECT id FROM public.conversations
  WHERE visiteur_id = public.current_app_user_id()
     OR hote_id     = public.current_app_user_id()));

-- L'expéditeur doit être soi-même ET participer à la conversation.
CREATE POLICY "messages_insert_own" ON public.messages
FOR INSERT TO authenticated
WITH CHECK (
  sender_id = public.current_app_user_id()
  AND conversation_id IN (
    SELECT id FROM public.conversations
    WHERE visiteur_id = public.current_app_user_id()
       OR hote_id     = public.current_app_user_id())
);

-- Marquage « lu » uniquement par le destinataire
CREATE POLICY "messages_update_recipient" ON public.messages
FOR UPDATE TO authenticated
USING (
  sender_id <> public.current_app_user_id()
  AND conversation_id IN (
    SELECT id FROM public.conversations
    WHERE visiteur_id = public.current_app_user_id()
       OR hote_id     = public.current_app_user_id())
);

-- ----------------------------------------------------------------------------
-- 5.9 Favoris, préférences, notifications
-- ----------------------------------------------------------------------------
CREATE POLICY "favorites_own_all" ON public.favorites
FOR ALL TO authenticated
USING      (user_id = public.current_app_user_id())
WITH CHECK (user_id = public.current_app_user_id());

CREATE POLICY "favori_logements_own_all" ON public.favori_logements
FOR ALL TO authenticated
USING (favorite_id IN (SELECT id FROM public.favorites
                       WHERE user_id = public.current_app_user_id()))
WITH CHECK (favorite_id IN (SELECT id FROM public.favorites
                            WHERE user_id = public.current_app_user_id()));

CREATE POLICY "user_preferences_own_all" ON public.user_preferences
FOR ALL TO authenticated
USING      (user_id = public.current_app_user_id())
WITH CHECK (user_id = public.current_app_user_id());

CREATE POLICY "notifications_own_all" ON public.notifications
FOR ALL TO authenticated
USING      (user_id = public.current_app_user_id())
WITH CHECK (user_id = public.current_app_user_id());
```

### Vérification immédiate

```sql
SELECT relname,
       relrowsecurity,
       (SELECT count(*) FROM pg_policies p
         WHERE p.schemaname='public' AND p.tablename=c.relname) AS policies
FROM pg_class c
WHERE relnamespace='public'::regnamespace AND relkind='r'
ORDER BY relrowsecurity, policies, relname;
```

Aucune ligne ne doit avoir `relrowsecurity = false`.

---

## Étape 6 — Contrainte anti-double-réservation · `VUL-13`

Aujourd'hui, la disponibilité est vérifiée à la sélection des dates, puis le paiement dure ~30 s, puis l'insertion se fait sans nouvelle vérification. Deux clients peuvent réserver les mêmes dates. Cette contrainte rend le conflit **structurellement impossible**, quel que soit le comportement du client.

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Purge préalable des chevauchements existants (à inspecter avant d'agir)
SELECT a.id AS res_a, b.id AS res_b, a.logement_id,
       a.date_debut, a.date_fin, b.date_debut, b.date_fin
FROM public.reservations a
JOIN public.reservations b
  ON a.logement_id = b.logement_id
 AND a.id < b.id
 AND daterange(a.date_debut, a.date_fin, '[)')
  && daterange(b.date_debut, b.date_fin, '[)')
WHERE a.statut IN ('PAYE','CONFIRMEE')
  AND b.statut IN ('PAYE','CONFIRMEE');

-- Puis, une fois les conflits résolus :
ALTER TABLE public.reservations
ADD CONSTRAINT no_overlapping_reservations
EXCLUDE USING gist (
  logement_id WITH =,
  daterange(date_debut, date_fin, '[)') WITH &&
) WHERE (statut IN ('PAYE','CONFIRMEE'));
```

> `'[)'` signifie borne de début incluse, borne de fin exclue : un départ le 10 et une arrivée le 10 ne sont **pas** en conflit. C'est le comportement attendu en hôtellerie, et il correspond à la logique du code Flutter (`reqDebut.isBefore(resFin) && reqFin.isAfter(resDebut)`).

Adapte la liste des statuts au résultat de la requête 3.2(c).

---

## Étape 7 — Réservation atomique · `VUL-02`, `VUL-12`, `VUL-14`

Cette fonction remplace les **11 écritures séquentielles** que le client Flutter effectuait. Elle est atomique par nature : soit tout passe, soit rien.

```sql
-- ============================================================================
-- VUL-02 / VUL-12 / VUL-14 — Réservation atomique côté serveur
-- ============================================================================

CREATE OR REPLACE FUNCTION public.confirm_reservation(
  p_logement_id   int,
  p_user_id       int,
  p_date_debut    date,
  p_date_fin      date,
  p_montant       numeric,
  p_nb_voyageurs  int,
  p_reference     text,
  p_projet_id     int DEFAULT NULL
)
RETURNS public.reservations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_res          public.reservations;
  v_pct          numeric;
  v_commission   numeric;
  v_part_projet  numeric := 0;
  v_hote_id      int;
  v_compte_id    int;
  v_montant_hote numeric;
  v_nb_nuits     int;
BEGIN
  -- Idempotence : un webhook peut être rejoué par KKiaPay.
  SELECT * INTO v_res FROM public.reservations WHERE reference = p_reference;
  IF FOUND THEN
    RETURN v_res;
  END IF;

  v_nb_nuits := p_date_fin - p_date_debut;
  IF v_nb_nuits <= 0 THEN
    RAISE EXCEPTION 'Dates invalides : la date de fin doit suivre la date de début';
  END IF;

  -- Commission plateforme
  SELECT val INTO v_pct FROM public.constances WHERE param = 'pourcentage';
  IF v_pct IS NULL THEN
    RAISE EXCEPTION 'Constante « pourcentage » absente de public.constances';
  END IF;
  v_commission := ROUND(p_montant * v_pct / 100, 2);

  -- Contribution projet
  IF p_projet_id IS NOT NULL THEN
    SELECT ROUND(p_montant * pourcentage_contribution / 100, 2)
      INTO v_part_projet
    FROM public.projets WHERE id = p_projet_id;
    v_part_projet := COALESCE(v_part_projet, 0);
  END IF;

  -- 1. Réservation (la contrainte d'exclusion de l'étape 6 protège du doublon)
  INSERT INTO public.reservations (
    logement_id, user_id, date_debut, date_fin, montant,
    nb_nuits, nb_voyageurs, mode_paiement, reference, projet_id,
    statut, created_at
  ) VALUES (
    p_logement_id, p_user_id, p_date_debut, p_date_fin, p_montant,
    v_nb_nuits, p_nb_voyageurs, 'kkiapay', p_reference, p_projet_id,
    'PAYE', now()
  )
  RETURNING * INTO v_res;

  -- 2. Revenu plateforme
  INSERT INTO public.revenu_plateformes (reservation_id, commission, part_projet, created_at)
  VALUES (v_res.id, v_commission, v_part_projet, now());

  -- 3. Contribution projet
  IF v_part_projet > 0 THEN
    INSERT INTO public.contributions
      (projet_id, reservation_id, montant_contribue, date_contribue, created_at)
    VALUES (p_projet_id, v_res.id, v_part_projet, CURRENT_DATE, now());
  END IF;

  -- 4. Crédit du compte hôte — atomique, sans read-modify-write (VUL-14)
  SELECT user_id INTO v_hote_id FROM public.logements WHERE id = p_logement_id;
  IF v_hote_id IS NULL THEN
    RAISE EXCEPTION 'Logement % introuvable', p_logement_id;
  END IF;

  v_montant_hote := p_montant - v_commission - v_part_projet;

  INSERT INTO public.comptes (user_id, solde, created_at)
  VALUES (v_hote_id, 0, now())
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE public.comptes
     SET solde = solde + v_montant_hote,
         updated_at = now()
   WHERE user_id = v_hote_id
  RETURNING id INTO v_compte_id;

  -- 5. Transaction
  INSERT INTO public.transactions (montant, type, compte_id, created_at)
  VALUES (v_montant_hote, 'credit', v_compte_id, now());

  RETURN v_res;
END $$;

-- Personne d'autre que le service_role ne peut l'appeler.
REVOKE EXECUTE ON FUNCTION public.confirm_reservation FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.confirm_reservation TO service_role;
```

### Annulation

```sql
CREATE OR REPLACE FUNCTION public.cancel_reservation(p_reservation_id int)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_res public.reservations;
BEGIN
  SELECT * INTO v_res FROM public.reservations WHERE id = p_reservation_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Réservation introuvable'; END IF;

  IF v_res.user_id <> public.current_app_user_id() THEN
    RAISE EXCEPTION 'Non autorisé';
  END IF;
  IF v_res.date_debut <= CURRENT_DATE THEN
    RAISE EXCEPTION 'Séjour déjà commencé : annulation impossible';
  END IF;

  UPDATE public.reservations
     SET statut = 'ANNULEE', updated_at = now()
   WHERE id = p_reservation_id;

  -- TODO métier : définir la politique de remboursement et débiter le compte hôte.
END $$;

GRANT EXECUTE ON FUNCTION public.cancel_reservation TO authenticated;
```

---

## Étape 8 — Recherche de rituels par RPC · `VUL-07`

Le client construisait un filtre PostgREST par concaténation (`.or('titre.ilike.%$query%,...')`), ce qui permettait de réécrire la clause `WHERE`. Un échappement a été mis en place côté Flutter, mais la vraie correction est un paramètre typé.

```sql
CREATE OR REPLACE FUNCTION public.search_rituels(p_query text)
RETURNS SETOF public.rituels
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT * FROM public.rituels
  WHERE actif = 'OUI'
    AND (titre ILIKE '%' || p_query || '%'
      OR description ILIKE '%' || p_query || '%')
  ORDER BY titre
  LIMIT 100;
$$;

GRANT EXECUTE ON FUNCTION public.search_rituels(text) TO anon, authenticated;
```

---

## Étape 9 — Edge Function de vérification du paiement · `VUL-02`

C'est **la** correction qui ferme le trou financier. Sans elle, les étapes précédentes bloquent simplement les réservations.

### 9.1 — Initialisation

```bash
npm install -g supabase
supabase login
supabase link --project-ref vbfgfbqgtattrajdmeit
supabase functions new confirm-payment
```

### 9.2 — Code

`supabase/functions/confirm-payment/index.ts` :

```ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const KKIAPAY_PRIVATE_KEY = Deno.env.get('KKIAPAY_PRIVATE_KEY')!
const KKIAPAY_SECRET_KEY  = Deno.env.get('KKIAPAY_SECRET_KEY')!
const KKIAPAY_PUBLIC_KEY  = Deno.env.get('KKIAPAY_PUBLIC_KEY')!
const KKIAPAY_API         = Deno.env.get('KKIAPAY_API')
  ?? 'https://api.kkiapay.me/api/v1/transactions/status'

const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

/** Tolérance d'écart entre montant payé et montant attendu, en XOF. */
const AMOUNT_TOLERANCE = 1

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    // ---- 1. Identifier l'appelant via son JWT -------------------------------
    const authHeader = req.headers.get('Authorization') ?? ''
    const jwt = authHeader.replace('Bearer ', '')
    const { data: authData, error: authErr } = await admin.auth.getUser(jwt)
    if (authErr || !authData.user) {
      return json({ error: 'Non authentifié' }, 401)
    }

    const { data: profile } = await admin
      .from('users')
      .select('id')
      .eq('supabase_id', authData.user.id)
      .single()

    if (!profile) return json({ error: 'Profil introuvable' }, 403)

    // ---- 2. Lire la demande ------------------------------------------------
    const { transactionId, logementId, dateDebut, dateFin,
            nbVoyageurs, projetId } = await req.json()

    if (!transactionId || !logementId || !dateDebut || !dateFin) {
      return json({ error: 'Paramètres manquants' }, 400)
    }

    // ---- 3. Vérifier la transaction auprès de KKiaPay ----------------------
    // ⚠️ Confirme les noms d'en-têtes dans la doc KKiaPay en vigueur.
    const kkRes = await fetch(KKIAPAY_API, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key':     KKIAPAY_PUBLIC_KEY,
        'x-private-key': KKIAPAY_PRIVATE_KEY,
        'x-secret-key':  KKIAPAY_SECRET_KEY,
      },
      body: JSON.stringify({ transactionId }),
    })

    if (!kkRes.ok) {
      console.error('KKiaPay HTTP', kkRes.status)
      return json({ error: 'Vérification du paiement impossible' }, 502)
    }

    const tx = await kkRes.json()
    if (tx.status !== 'SUCCESS') {
      return json({ error: 'Paiement non confirmé', status: tx.status }, 402)
    }

    // ---- 4. Recalculer le montant CÔTÉ SERVEUR -----------------------------
    // Le montant envoyé par le client n'est jamais pris pour argent comptant.
    const { data: logement, error: logErr } = await admin
      .from('logements')
      .select('id, prix_par_nuit, nb_voyageur_max')
      .eq('id', logementId)
      .single()

    if (logErr || !logement) return json({ error: 'Logement introuvable' }, 404)

    const d1 = new Date(dateDebut)
    const d2 = new Date(dateFin)
    const nbNuits = Math.round((d2.getTime() - d1.getTime()) / 86_400_000)

    if (nbNuits <= 0) return json({ error: 'Dates invalides' }, 400)
    if (nbVoyageurs > logement.nb_voyageur_max) {
      return json({ error: 'Trop de voyageurs pour ce logement' }, 400)
    }

    const montantAttendu = nbNuits * Number(logement.prix_par_nuit)

    if (Math.abs(Number(tx.amount) - montantAttendu) > AMOUNT_TOLERANCE) {
      console.error('Écart de montant', {
        paye: tx.amount, attendu: montantAttendu, transactionId,
      })
      return json({
        error: 'Montant incohérent — la transaction sera examinée',
      }, 409)
    }

    // ---- 5. Écriture atomique ---------------------------------------------
    const { data: reservation, error: rpcErr } = await admin.rpc(
      'confirm_reservation',
      {
        p_logement_id:  logementId,
        p_user_id:      profile.id,
        p_date_debut:   dateDebut,
        p_date_fin:     dateFin,
        p_montant:      montantAttendu,
        p_nb_voyageurs: nbVoyageurs,
        p_reference:    transactionId,
        p_projet_id:    projetId ?? null,
      },
    )

    if (rpcErr) {
      // La contrainte d'exclusion remonte ici en cas de dates déjà prises.
      console.error('confirm_reservation', rpcErr)
      const dejaPris = rpcErr.message?.includes('no_overlapping_reservations')
      return json({
        error: dejaPris
          ? 'Ces dates viennent d\'être réservées. Le paiement sera remboursé.'
          : 'Enregistrement impossible',
      }, dejaPris ? 409 : 500)
    }

    return json({ reservation }, 200)

  } catch (e) {
    console.error(e)
    return json({ error: 'Erreur interne' }, 500)
  }
})

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
```

### 9.3 — Déploiement

```bash
supabase secrets set KKIAPAY_PRIVATE_KEY="ta_cle_privee"
supabase secrets set KKIAPAY_SECRET_KEY="ta_cle_secrete"
supabase secrets set KKIAPAY_PUBLIC_KEY="2fd08370652e11efbf02478c5adba4b8"

supabase functions deploy confirm-payment

supabase secrets list      # vérifie : aucune valeur ne doit s'afficher en clair
```

> 🔑 **Les clés privée et secrète KKiaPay ne doivent jamais apparaître dans le code Flutter.** Si elles y figuraient à un moment, régénère-les depuis le dashboard KKiaPay.

---

## Étape 10 — Politiques Storage · `VUL-09`

```sql
-- Lecture publique des photos de logements et profils
CREATE POLICY "storage_public_read"
ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id IN ('logements','profils','rituels'));

-- Chaque utilisateur n'écrit que dans son propre dossier
CREATE POLICY "storage_own_folder_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id IN ('logements','profils','rituels','message-attachments')
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "storage_own_folder_update"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id IN ('logements','profils','rituels','message-attachments')
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "storage_own_folder_delete"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id IN ('logements','profils','rituels','message-attachments')
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

Dashboard → **Storage** → chaque bucket → *Settings* :
- **File size limit** : `10 MB` (aligné sur `SupabaseConfig.maxUploadSizeMB`)
- **Allowed MIME types** : `image/jpeg, image/png, image/webp, image/gif`

> ⚠️ La policy ci-dessus impose que les fichiers soient rangés dans un dossier nommé d'après l'`auth.uid()`. Le code Flutter actuel écrit à la racine ou dans `conversation_<id>/`. **Soit** tu adaptes `FileUploadService.uploadFile` pour préfixer par l'uid, **soit** tu assouplis la policy. Voir étape 12.

---

## Étape 11 — Réglages du dashboard Auth

**Authentication → URL Configuration**
- *Site URL* : l'URL de ton site, ou `vodoohost://auth/callback` si pas de site web
- *Redirect URLs* : ajouter `vodoohost://auth/callback`

**Authentication → Providers → Email**
- ✅ *Confirm email* **activé** (le flag `disableEmailConfirmation` a été neutralisé côté app, mais la source de vérité est ici)
- *Minimum password length* : `8` au minimum — l'app annonce 6, ce qui est faible

**Authentication → Rate Limits**
- *Sign in / Sign up* : abaisser à `10` par heure et par IP
- *Token refresh* et *OTP* : garder les valeurs par défaut

**Authentication → Providers → Google**
- Vérifier que le *Client ID* correspond à celui de `Env.googleWebClientId`
- Après changement de l'`applicationId` Android, **redéclarer le SHA-1** du keystore de release

---

## Étape 12 — Modifications à faire côté Flutter

Une fois le serveur en place, l'application doit cesser d'écrire elle-même.

### 12.1 — `reservation_repository.dart`

Remplacer intégralement `createReservation()` (lignes 20 à 190) par un appel à l'Edge Function :

```dart
/// Confirme une réservation après paiement.
///
/// Le montant, la commission et le crédit de l'hôte sont calculés et écrits
/// CÔTÉ SERVEUR. Le client ne transmet que la référence de transaction et le
/// contexte de séjour : aucune valeur monétaire ne lui est plus accordée.
Future<Reservation> confirmReservation({
  required String transactionId,
  required int logementId,
  required DateTime dateDebut,
  required DateTime dateFin,
  required int nbVoyageurs,
  int? projetId,
}) async {
  final response = await _supabaseService.client.functions.invoke(
    'confirm-payment',
    body: {
      'transactionId': transactionId,
      'logementId': logementId,
      'dateDebut': dateDebut.toIso8601String().split('T').first,
      'dateFin': dateFin.toIso8601String().split('T').first,
      'nbVoyageurs': nbVoyageurs,
      'projetId': projetId,
    },
  );

  if (response.status != 200) {
    final message = (response.data is Map)
        ? response.data['error']?.toString()
        : null;
    throw Exception(message ?? 'La confirmation du paiement a échoué.');
  }

  return Reservation.fromJson(
    (response.data as Map<String, dynamic>)['reservation']
        as Map<String, dynamic>,
  );
}
```

Puis, dans `reservation_provider.dart`, remplacer l'appel à `_repository.createReservation(...)` par `confirmReservation(...)` en supprimant les paramètres `montant`, `nbNuits`, `modePaiement` et `userId`.

### 12.2 — `ritual_repository.dart`

```dart
final response = await _supabaseService.client
    .rpc('search_rituels', params: {'p_query': query});

final rituals = (response as List)
    .map((json) => Ritual.fromJson(json as Map<String, dynamic>))
    .toList();
```

La méthode `_sanitizeFilterValue()` devient alors superflue et peut être supprimée.

### 12.3 — `auth_repository.dart`

Le trigger de l'étape 4 crée désormais le profil. Côté client :

- Retirer `'role_id': roleId` de l'appel `signUp(data: {...})` (ligne ~59)
- Supprimer la méthode `_createProfileFromMetadata()` et ses appels
- Remplacer `createOAuthProfile(... roleId ...)` par un appel à `rpc('request_role_change', params: {'p_role_libelle': ...})` après création

### 12.4 — Profils d'hôtes

Les écrans lisant `users` pour afficher un hôte doivent viser la vue :

```dart
await _supabase.from('public_profiles').select().eq('id', hostId).single();
```

Concerné : `accommodation_details_repository.dart` (méthode `getHostInfo`).

### 12.5 — Upload dans le dossier de l'utilisateur

Pour respecter la policy Storage de l'étape 10, dans `FileUploadService.uploadFile` :

```dart
final uid = _supabaseService.client.auth.currentUser?.id;
if (uid == null) throw Exception('Session expirée');
final String filePath =
    folder != null ? '$uid/$folder/$fileName' : '$uid/$fileName';
```

---

## Étape 13 — Tests d'intrusion

Après déploiement, lance ce script avec la clé **`anon`** (celle de l'APK). **Chaque cas doit échouer.**

```js
// test_rls.mjs  —  node test_rls.mjs
import { createClient } from '@supabase/supabase-js'

const url  = 'https://vbfgfbqgtattrajdmeit.supabase.co'
const anon = 'TA_CLE_ANON'
const sb   = createClient(url, anon)

// Connecte-toi avec un compte de test réel
await sb.auth.signInWithPassword({
  email: 'test@example.com', password: 'motdepassetest',
})

const essai = async (nom, fn) => {
  const { error } = await fn()
  console.log(error ? `✅ ${nom} — bloqué` : `❌ ${nom} — PASSÉ (faille !)`)
}

// 1. Réservation gratuite
await essai('Insertion de réservation', () =>
  sb.from('reservations').insert({
    logement_id: 1, user_id: 1, date_debut: '2026-12-01',
    date_fin: '2026-12-05', montant: 1, nb_nuits: 4,
    nb_voyageurs: 1, mode_paiement: 'kkiapay',
    reference: 'FRAUDE', statut: 'PAYE',
  }))

// 2. Crédit de solde arbitraire
await essai('Mise à jour de solde', () =>
  sb.from('comptes').update({ solde: 9_999_999 }).eq('id', 1))

// 3. Élévation de privilèges
await essai('Changement de role_id', () =>
  sb.from('users').update({ role_id: 1 }).eq('id', 1))

// 4. Lecture des profils d'autrui
await essai('Lecture de tous les users', async () => {
  const { data, error } = await sb.from('users').select('email, telephone')
  return { error: error ?? (data?.length > 1 ? null : new Error('ok')) }
})

// 5. Transaction forgée
await essai('Insertion de transaction', () =>
  sb.from('transactions').insert({ montant: 500000, type: 'credit', compte_id: 1 }))

// 6. Appel direct de la fonction de réservation
await essai('RPC confirm_reservation', () =>
  sb.rpc('confirm_reservation', {
    p_logement_id: 1, p_user_id: 1,
    p_date_debut: '2026-12-01', p_date_fin: '2026-12-05',
    p_montant: 1, p_nb_voyageurs: 1, p_reference: 'DIRECT',
  }))

// 7. Injection de filtre PostgREST
await essai('Injection dans search_rituels', () =>
  sb.rpc('search_rituels', { p_query: "x%',id.gt.0,titre.ilike.'%" }))

// 8. Lecture des revenus plateforme
await essai('Lecture revenu_plateformes', async () => {
  const { data, error } = await sb.from('revenu_plateformes').select('*')
  return { error: error ?? (data?.length ? null : new Error('ok')) }
})
```

**Un seul `❌` signifie que l'étape correspondante n'est pas correctement appliquée.**

### Test fonctionnel du parcours nominal

Avec le sandbox KKiaPay, enchaîne : recherche → détail → sélection de dates → paiement → vérifier que la réservation apparaît bien. Puis, dans le SQL Editor :

```sql
SELECT r.id, r.reference, r.montant, r.statut,
       rp.commission, rp.part_projet,
       c.solde AS solde_hote
FROM public.reservations r
JOIN public.revenu_plateformes rp ON rp.reservation_id = r.id
JOIN public.logements l ON l.id = r.logement_id
JOIN public.comptes c ON c.user_id = l.user_id
ORDER BY r.created_at DESC LIMIT 5;
```

Vérifie que `montant = commission + part_projet + (crédit du solde)`.

---

## Étape 14 — Retour arrière

Si quelque chose casse en production et que tu dois rétablir le service en urgence :

```sql
-- Désactive UNIQUEMENT la table qui pose problème, jamais toutes.
ALTER TABLE public.<table> DISABLE ROW LEVEL SECURITY;
```

> ⚠️ Désactiver le RLS rouvre la faille. À ne faire que le temps du diagnostic, jamais comme solution durable. Note l'heure, corrige, réactive.

Restauration complète :

```bash
pg_restore --clean --if-exists --no-owner --no-privileges \
  -d "postgresql://postgres.<ref>:<NOUVEAU_MDP>@aws-0-eu-west-2.pooler.supabase.com:6543/postgres" \
  vodoohost_backup_YYYYMMDD.dump
```

---

## Checklist finale

### Côté Supabase

- [ ] Sauvegarde effectuée et vérifiée
- [ ] Mot de passe PostgreSQL tourné
- [ ] Audit du schéma fait, hypothèses confirmées
- [ ] `comptes.user_id` est `UNIQUE`
- [ ] Réservations de test frauduleuses purgées, soldes recalculés
- [ ] Trigger `on_auth_user_created` actif
- [ ] RLS actif sur **toutes** les tables, aucune à `false`
- [ ] Contrainte `no_overlapping_reservations` posée
- [ ] `confirm_reservation()` créée, `EXECUTE` révoqué pour `anon`/`authenticated`
- [ ] `search_rituels()` créée
- [ ] Edge Function `confirm-payment` déployée, secrets posés
- [ ] Policies Storage + limites MIME/taille
- [ ] Réglages Auth : redirect URLs, confirmation e-mail, rate limits
- [ ] Les 8 tests d'intrusion retournent tous `✅`
- [ ] Parcours de réservation testé en sandbox, montants cohérents

### Hors Supabase — indispensable aussi

- [ ] Historique Git purgé, équipe prévenue de re-cloner
- [ ] Keystore de release généré, `android/key.properties` créé
- [ ] `applicationId` changé, `google-services.json` régénéré, SHA-1 redéclaré
- [ ] Modifications Flutter de l'étape 12 appliquées
- [ ] Application testée à l'exécution : PKCE, deep link, images, réservation

### Risques résiduels assumés

Ces points resteront ouverts après ce runbook. Ils sont documentés dans [AUDIT_SECURITE.md](AUDIT_SECURITE.md) :

- **VUL-10** — jetons de session en clair dans `SharedPreferences`
- **VUL-11** — aucun test automatisé sur le calcul de commission
- **VUL-17** — messages d'erreur exposant les noms de tables à l'utilisateur

---

## Ce que ce runbook ferme

| Vulnérabilité | Étape |
|---|---|
| `VUL-01` Mot de passe versionné | 2 |
| `VUL-02` Paiement non vérifié | 7 + 9 |
| `VUL-03` Élévation de privilèges | 4 |
| `VUL-04` RLS inactif | 5 |
| `VUL-07` Injection PostgREST | 8 |
| `VUL-09` Uploads non contrôlés | 10 |
| `VUL-12` Réservation non atomique | 7 |
| `VUL-13` Double réservation | 6 |
| `VUL-14` Race sur le solde | 7 |
