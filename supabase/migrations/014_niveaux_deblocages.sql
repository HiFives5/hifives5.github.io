-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 014 : niveaux et déblocages
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 013).
-- N'efface rien ; relançable.
--
-- Échelle (points) : 1 Débutant 0 · 2 Curieux 150 · 3 Explorateur 400 · 4 Connaisseur 800 · 5 Passionné 1 500
--                    6 Critique 2 500 · 7 Expert 4 000 · 8 Référence 6 500 · 9 Maître 10 000 · 10 Légende 15 000
-- Garde-fous vérifiés par la base :
--   • commenter : niveau 2 (150 pts)        • créer un sujet : niveau 3 (400 pts)
--   • titre sous le pseudo (un de ses badges) : niveau 4 (800 pts)
-- ════════════════════════════════════════════════════════════════

-- Points de la personne connectée (utilisé par les règles d'accès)
create or replace function public.my_points()
returns int language sql stable security definer set search_path = public as $$
  select coalesce((select points from profiles where id = auth.uid()), 0);
$$;
revoke execute on function public.my_points() from public, anon;
grant execute on function public.my_points() to authenticated;

-- Commenter : niveau 2
drop policy if exists "commenter" on public.comments;
create policy "commenter" on public.comments for insert to authenticated
  with check (user_id = auth.uid() and public.my_points() >= 150);

-- Créer un sujet : niveau 3
drop policy if exists "créer un sujet" on public.topics;
create policy "créer un sujet" on public.topics for insert to authenticated
  with check (created_by = auth.uid() and is_official = false and public.my_points() >= 400);

-- Titre sous le pseudo : un badge obtenu, à partir du niveau 4
alter table public.profiles add column if not exists title_badge text references public.badges(code) on delete set null;
grant update (title_badge) on public.profiles to authenticated;

create or replace function public.check_title_badge()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.title_badge is not null and new.title_badge is distinct from old.title_badge then
    if new.points < 800 then
      raise exception 'Le titre se débloque au niveau 4 (800 points).';
    end if;
    if not exists (select 1 from user_badges where user_id = new.id and badge = new.title_badge) then
      raise exception 'Ce badge ne fait pas partie des tiens.';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists profiles_title_badge on public.profiles;
create trigger profiles_title_badge before update of title_badge on public.profiles
  for each row execute function public.check_title_badge();
