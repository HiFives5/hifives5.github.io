-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 003 : retours utilisateurs + administrateur
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien.
--
-- Ensuite, pour te déclarer administrateur (à faire une seule fois) :
--   update public.profiles set is_admin = true where handle = '@ton_pseudo';
-- ════════════════════════════════════════════════════════════════

-- Rôle administrateur : non modifiable depuis l'appli (pas dans les droits de mise à jour)
alter table public.profiles add column if not exists is_admin boolean not null default false;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

create table if not exists public.feedback (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  kind       text not null default 'avis' check (kind in ('bug', 'idee', 'avis')),
  rating     int check (rating between 1 and 5),
  message    text not null check (char_length(message) between 1 and 2000),
  page       text,              -- écran où était l'utilisateur
  user_agent text,              -- téléphone / navigateur (utile pour les bugs)
  status     text not null default 'nouveau' check (status in ('nouveau', 'en_cours', 'traite', 'rejete')),
  reply      text check (char_length(reply) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists feedback_status_idx on public.feedback(status, created_at desc);

create or replace function public.feedback_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists feedback_updated on public.feedback;
create trigger feedback_updated before update on public.feedback
  for each row execute function public.feedback_touch();

alter table public.feedback enable row level security;

drop policy if exists "envoyer un retour" on public.feedback;
drop policy if exists "lire ses retours ou admin" on public.feedback;
drop policy if exists "admin traite les retours" on public.feedback;
drop policy if exists "admin supprime les retours" on public.feedback;

-- Chacun envoie ses propres retours (statut et réponse imposés)
create policy "envoyer un retour" on public.feedback for insert to authenticated
  with check (user_id = auth.uid() and status = 'nouveau' and reply is null);
-- Chacun voit ses retours ; l'admin voit tout
create policy "lire ses retours ou admin" on public.feedback for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
-- Seul l'admin change le statut / répond / supprime
create policy "admin traite les retours" on public.feedback for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "admin supprime les retours" on public.feedback for delete to authenticated
  using (public.is_admin());

revoke update on public.feedback from anon, authenticated;
grant update (status, reply) on public.feedback to authenticated;
