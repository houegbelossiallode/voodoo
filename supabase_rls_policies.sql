-- ==============================================================================
-- SCRIPT DE SÉCURISATION RLS (ROW LEVEL SECURITY) POUR VODOOHOST (SUPABASE)
-- À exécuter directement dans Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. ACTIVATION DU RLS SUR TOUTES LES TABLES CLÉS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favori_logements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logement_disponibilites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avis ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. TABLE 'USERS' : Protections des Profils & Prévention d'Élévation de Privilèges
-- ------------------------------------------------------------------------------
-- Supprimer les anciennes règles permissives si existantes
DROP POLICY IF EXISTS "Public profile read" ON public.users;
DROP POLICY IF EXISTS "User update own profile" ON public.users;
DROP POLICY IF EXISTS "Deny role modification" ON public.users;

-- Lecture : Un utilisateur ne peut voir que son propre profil (ou les infos publiques de l'hôte)
CREATE POLICY "Users can view own profile" 
ON public.users 
FOR SELECT 
USING (auth.uid() = supabase_id);

-- Modification : Un utilisateur ne peut modifier QUE son propre profil
CREATE POLICY "Users can update own profile" 
ON public.users 
FOR UPDATE 
USING (auth.uid() = supabase_id)
WITH CHECK (
  auth.uid() = supabase_id 
  -- Interdiction absolue d'élever ses privilèges (role_id et actif restent inchangés)
  AND role_id = (SELECT role_id FROM public.users WHERE supabase_id = auth.uid())
  AND actif = (SELECT actif FROM public.users WHERE supabase_id = auth.uid())
);

-- Insertion : Seul le système d'authentification crée son compte
CREATE POLICY "Users can insert own profile" 
ON public.users 
FOR INSERT 
WITH CHECK (auth.uid() = supabase_id);


-- ------------------------------------------------------------------------------
-- 3. TABLE 'RESERVATIONS' : Isolation Stricte des Réservations
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "User read own reservations" ON public.reservations;
DROP POLICY IF EXISTS "User create own reservations" ON public.reservations;

-- Un client ne voit que ses propres réservations, un hôte voit les réservations de ses logements
CREATE POLICY "Users can view relevant reservations" 
ON public.reservations 
FOR SELECT 
USING (
  user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  OR 
  logement_id IN (
    SELECT id FROM public.logements 
    WHERE user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  )
);

-- Un utilisateur ne peut créer une réservation que sous son propre ID
CREATE POLICY "Users can create own reservations" 
ON public.reservations 
FOR INSERT 
WITH CHECK (
  user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
);


-- ------------------------------------------------------------------------------
-- 4. TABLE 'FAVORITES' et 'FAVORI_LOGEMENTS' : Isolation des Favoris
-- ------------------------------------------------------------------------------
CREATE POLICY "Users manage own favorites" 
ON public.favorites 
FOR ALL 
USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()))
WITH CHECK (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));

CREATE POLICY "Users manage own favorite logements" 
ON public.favori_logements 
FOR ALL 
USING (
  favorite_id IN (
    SELECT id FROM public.favorites 
    WHERE user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  )
);


-- ------------------------------------------------------------------------------
-- 5. TABLES 'CONVERSATIONS' ET 'MESSAGES' : Sécurisation de la Messagerie Privée
-- ------------------------------------------------------------------------------
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own conversations" 
ON public.conversations 
FOR SELECT 
USING (
  visiteur_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  OR 
  hote_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
);

CREATE POLICY "Users create conversations" 
ON public.conversations 
FOR INSERT 
WITH CHECK (
  visiteur_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  OR 
  hote_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
);

CREATE POLICY "Users read own messages" 
ON public.messages 
FOR SELECT 
USING (
  conversation_id IN (
    SELECT id FROM public.conversations 
    WHERE visiteur_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
       OR hote_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  )
);

CREATE POLICY "Users send own messages" 
ON public.messages 
FOR INSERT 
WITH CHECK (
  sender_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
);


-- ------------------------------------------------------------------------------
-- 6. TABLES PUBLIQUES (LOGEMENTS, DISPONIBILITÉS, AVIS) : Lecture Publique, Édition Restreinte
-- ------------------------------------------------------------------------------
-- Tout le monde (même non connecté) peut voir les logements et leur disponibilité
CREATE POLICY "Public read logements" ON public.logements FOR SELECT USING (true);
CREATE POLICY "Public read disponibilites" ON public.logement_disponibilites FOR SELECT USING (true);
CREATE POLICY "Public read avis" ON public.avis FOR SELECT USING (true);

-- Seul l'hôte propriétaire du logement peut modifier son logement et ses disponibilités
CREATE POLICY "Host update own logement" 
ON public.logements 
FOR UPDATE 
USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));

CREATE POLICY "Host manage own disponibilites" 
ON public.logement_disponibilites 
FOR ALL 
USING (
  logement_id IN (
    SELECT id FROM public.logements 
    WHERE user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())
  )
);
