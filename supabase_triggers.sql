-- supabase_triggers.sql
-- Trigger pour créer automatiquement un enregistrement dans public.users
-- lorsque l'utilisateur confirme son email sur auth.users.
-- Déployez ce script depuis Supabase SQL Editor (exécuté par un rôle admin/service_role)

-- Fonction qui crée le profil si l'utilisateur est confirmé
create or replace function public.create_user_profile_on_confirm()
returns trigger as $$
begin
  -- Si l'insert contient déjà une preuve de confirmation -> créer
  -- Certains projets Supabase utilisent `confirmed_at`, d'autres `email_confirmed_at`.
  if (TG_OP = 'INSERT' and (new.confirmed_at is not null or new.email_confirmed_at is not null)) then
    null; -- on poursuit
  -- Si c'est une update qui met la confirmation pour la 1ère fois -> créer
  elsif (TG_OP = 'UPDATE' and (
    (old.confirmed_at is null and new.confirmed_at is not null)
    or (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  )) then
    null; -- on poursuit
  else
    return new;
  end if;

  -- Insérer uniquement si aucun profil n'existe déjà pour ce supabase_id
  insert into public.users (supabase_id, email, created_at, actif)
  select new.id, new.email, now(), 'OUI'
  where not exists (
    select 1 from public.users where supabase_id = new.id
  );

  return new;
end;
$$ language plpgsql security definer;

-- Trigger attaché à auth.users: se déclenche après insert ou update
create trigger trg_create_user_profile_on_auth_user
after insert or update on auth.users
for each row
execute procedure public.create_user_profile_on_confirm();

-- IMPORTANT:
-- 1) Exécutez ce script depuis le Supabase SQL Editor en tant qu'administrateur (le rôle par défaut de l'éditeur permet
--    généralement de créer une fonction SECURITY DEFINER capable de bypasser RLS si nécessaire).
-- 2) Vérifiez que la fonction est possédée par un rôle qui peut contourner RLS (ou ajustez les policies si vous préférez).
-- 3) Après déploiement, testez les scénarios : inscription (email confirmation activée), confirmation, puis connexion.
-- 4) Si vous préférez que le profil soit créé uniquement après connexion (et non à la confirmation), je peux également
--    implémenter la création côté application lors du premier login.
