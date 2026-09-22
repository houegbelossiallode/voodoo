-- supabase_triggers_fix.sql
-- Remplace la fonction de trigger pour créer un profil utilisateur lors de la confirmation
-- Assure que `nom` et `prenom` ne soient jamais NULL en extrayant user_metadata ou en utilisant des fallbacks

create or replace function public.create_user_profile_on_confirm()
returns trigger
language plpgsql
security definer
as $$
declare
  default_role_id int;
  given text;
  family text;
  fullname text;
begin
  -- Ne s'exécute que pour les nouveaux comptes confirmés ou les updates qui confirment
  if (TG_OP = 'INSERT' and (new.confirmed_at is not null or new.email_confirmed_at is not null)) then
    null;
  elsif (TG_OP = 'UPDATE' and (
    (old.confirmed_at is null and new.confirmed_at is not null)
    or (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  )) then
    null;
  else
    return new;
  end if;

  -- Vérifier si un profil existe déjà
  if exists (select 1 from public.users where supabase_id = new.id) then
    return new;
  end if;

  -- Récupérer l'id du rôle 'Visiteur' s'il existe
  select id into default_role_id from public.roles where libelle = 'Visiteur' limit 1;

  -- Extraire des champs usuels dans user_metadata
  given := null;
  family := null;
  fullname := null;

  if new.user_metadata is not null then
    begin
      given := coalesce(new.user_metadata ->> 'given_name', new.user_metadata ->> 'first_name', new.user_metadata ->> 'prenom', new.user_metadata ->> 'prenom', null);
      family := coalesce(new.user_metadata ->> 'family_name', new.user_metadata ->> 'last_name', new.user_metadata ->> 'nom', new.user_metadata ->> 'nom', null);
      fullname := coalesce(new.user_metadata ->> 'full_name', new.user_metadata ->> 'name', null);
    exception when others then
      -- si parsing échoue, ignorer et utiliser fallbacks
      given := null; family := null; fullname := null;
    end;
  end if;

  -- Si given missing mais fullname present -> split
  if (given is null or trim(given) = '') and fullname is not null then
    given := split_part(fullname, ' ', 1);
  end if;

  -- If family missing, try to take remainder of fullname
  if (family is null or trim(family) = '') and fullname is not null then
    if position(' ' in fullname) > 0 then
      family := trim(substring(fullname from position(' ' in fullname)+1));
    end if;
  end if;

  -- Final fallbacks to guarantee non-null
  given := coalesce(nullif(trim(given), ''), 'Utilisateur');
  family := coalesce(nullif(trim(family), ''), given);

  insert into public.users (
    supabase_id, nom, prenom, email, telephone, profession, langue, passions, bio, actif, role_id, created_at
  ) values (
    new.id,
    family,
    given,
    new.email,
    coalesce(new.user_metadata ->> 'telephone', ''),
    coalesce(new.user_metadata ->> 'profession', ''),
    array['fr'],
    array[]::text[],
    null,
    'OUI',
    coalesce(default_role_id, 1),
    now()
  ) on conflict (supabase_id) do update set email = excluded.email;

  return new;
end;
$$;

-- Attacher le trigger (si déjà présent, l'instruction CREATE TRIGGER échouera — supprimez l'ancien trigger avant d'exécuter)

-- DROP TRIGGER IF EXISTS trg_create_user_profile_on_auth_user ON auth.users;
create trigger trg_create_user_profile_on_auth_user
after insert or update on auth.users
for each row
execute procedure public.create_user_profile_on_confirm();

-- Notes:
-- 1) Exécutez ce script depuis Supabase SQL Editor en tant qu'administrateur.
-- 2) Après exécution, testez une confirmation d'email pour vérifier que `public.users` est créé avec des valeurs non-null pour `nom` et `prenom`.
-- 3) Cette fonction utilise `new.user_metadata` si disponible. Pour améliorer l'expérience, fournissez `user_metadata` lors de l'appel client à signUp (nom/prenom).
