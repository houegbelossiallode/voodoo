-- supabase_triggers_remove.sql
-- Supprime le trigger et la fonction qui créent des profils à la confirmation
-- Exécutez ce script depuis Supabase SQL Editor (admin) ou via psql connecté au rôle approprié.

-- 1) Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS trg_create_user_profile_on_auth_user ON auth.users;

-- 2) Supprimer la fonction si elle existe
DROP FUNCTION IF EXISTS public.create_user_profile_on_confirm();

-- Note:
-- Exécuter ces commandes annulera la création automatique de profils lors de la confirmation.
-- Après exécution, vous pouvez soit:
--  - laisser la création côté client comme avant, ou
--  - déployer ensuite une version corrigée de la fonction (supabase_triggers_fix.sql) si vous souhaitez réintroduire un trigger amélioré.
