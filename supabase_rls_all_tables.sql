-- ==============================================================================
-- SCRIPT DE SÉCURISATION RLS COMPLET (100% DES TABLES VODOOHOST)
-- À exécuter dans Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. ACTIVATION DU RLS SUR TOUTES LES TABLES DU PROJET
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pays ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.type_logements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.equipements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.logements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.divinites ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rituels ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.avis ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.projets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pointforts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.favori_logements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.constances ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.equipement_logement ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.divinite_logement ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rituel_logement ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.logement_disponibilites ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.comptes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.revenu_plateformes ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. TABLES RÉFÉRENTIELLES ET DÉCOUVRABILITÉ (LECTURE PUBLIQUE, ÉDITION INTERDITE)
-- ------------------------------------------------------------------------------
DO $$ 
BEGIN
    -- Rôles, Pays, Catégories, Types de logements, Équipements, Divinités, Rituels, Projets, Pointforts, Photos, Constances
    EXECUTE 'CREATE POLICY "Public read roles" ON public.roles FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read pays" ON public.pays FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read categories" ON public.categories FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read type_logements" ON public.type_logements FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read equipements" ON public.equipements FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read divinites" ON public.divinites FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read rituels" ON public.rituels FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read projets" ON public.projets FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read pointforts" ON public.pointforts FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read photos" ON public.photos FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read constances" ON public.constances FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read equipement_logement" ON public.equipement_logement FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read divinite_logement" ON public.divinite_logement FOR SELECT USING (true);';
    EXECUTE 'CREATE POLICY "Public read rituel_logement" ON public.rituel_logement FOR SELECT USING (true);';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ------------------------------------------------------------------------------
-- 3. TABLES DE PAIEMENT, TRANSACTIONS & FINANCES (STRICTEMENT PRIVÉES AU PROPRIÉTAIRE)
-- ------------------------------------------------------------------------------
DO $$ 
BEGIN
    -- Paiements & Transactions
    EXECUTE 'CREATE POLICY "Users read own paiements" ON public.paiements FOR SELECT USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
    EXECUTE 'CREATE POLICY "Users read own transactions" ON public.transactions FOR SELECT USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
    EXECUTE 'CREATE POLICY "Users read own comptes" ON public.comptes FOR SELECT USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
    EXECUTE 'CREATE POLICY "Users read own contributions" ON public.contributions FOR SELECT USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ------------------------------------------------------------------------------
-- 4. TABLE 'NOTIFICATIONS' & 'USER_PREFERENCES' (STRICTEMENT PRIVÉES)
-- ------------------------------------------------------------------------------
DO $$ 
BEGIN
    EXECUTE 'CREATE POLICY "Users manage own notifications" ON public.notifications FOR ALL USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())) WITH CHECK (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
    EXECUTE 'CREATE POLICY "Users manage own preferences" ON public.user_preferences FOR ALL USING (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid())) WITH CHECK (user_id = (SELECT id FROM public.users WHERE supabase_id = auth.uid()));';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
