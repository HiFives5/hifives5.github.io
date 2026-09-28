-- ════════════════════════════════════════════════════════════════
-- HiFives — schéma v2
-- À coller dans Supabase > SQL Editor > New query, puis "Run".
--
-- ⚠️ Supprime les anciennes tables (les tops de test sont perdus).
--    Les comptes (auth.users) sont conservés : un profil est recréé
--    automatiquement pour chacun.
-- ════════════════════════════════════════════════════════════════

drop table if exists public.likes cascade;
drop table if exists public.top_items cascade;
drop table if exists public.tops cascade;
drop table if exists public.topic_suggestions cascade;
drop table if exists public.topics cascade;
drop table if exists public.profiles cascade;

-- ── PROFILS ─────────────────────────────────────────────────────
-- Pas de clé étrangère vers auth.users : permet des profils "démo".
create table public.profiles (
  id           uuid primary key default gen_random_uuid(),
  name         text not null default '',
  handle       text not null unique,
  country      text,
  birth_year   int check (birth_year between 1900 and 2100),
  gender       text,
  points       int not null default 0,
  tops_created int not null default 0,
  tops_filled  int not null default 0,
  is_demo      boolean not null default false,
  created_at   timestamptz not null default now()
);

-- ── SUJETS (ex : "Top 5 films italiens") ────────────────────────
create table public.topics (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 3 and 120),
  category    text not null,
  created_by  uuid references public.profiles(id) on delete set null,
  is_official boolean not null default false,
  created_at  timestamptz not null default now()
);
create unique index topics_title_uniq on public.topics (lower(title));

-- Réponses proposées à la saisie (autocomplétion)
create table public.topic_suggestions (
  topic_id uuid not null references public.topics(id) on delete cascade,
  content  text not null,
  weight   int not null default 1,
  primary key (topic_id, content)
);

-- ── RÉPONSES : le top 5 d'un utilisateur pour un sujet ──────────
create table public.tops (
  id         uuid primary key default gen_random_uuid(),
  topic_id   uuid not null references public.topics(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (topic_id, user_id)
);
create index tops_topic_idx on public.tops(topic_id);

create table public.top_items (
  top_id  uuid not null references public.tops(id) on delete cascade,
  rank    int  not null check (rank between 1 and 5),
  content text not null check (char_length(content) between 1 and 100),
  -- forme normalisée, pour les stats et futures corrélations
  norm    text generated always as (lower(btrim(regexp_replace(content, '\s+', ' ', 'g')))) stored,
  primary key (top_id, rank)
);
create index top_items_norm_idx on public.top_items(norm);

create table public.likes (
  top_id     uuid not null references public.tops(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (top_id, user_id)
);

-- ── CRÉATION AUTOMATIQUE DU PROFIL À L'INSCRIPTION ──────────────
create or replace function public.ensure_profile(uid uuid, email text, meta jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  m jsonb := coalesce(meta, '{}'::jsonb);
  h text  := coalesce(nullif(m->>'handle', ''), split_part(email, '@', 1));
begin
  h := '@' || regexp_replace(ltrim(h, '@'), '[^A-Za-z0-9_.]', '', 'g');
  if h = '@' then h := '@user'; end if;
  if exists (select 1 from profiles where handle = h and id <> uid) then
    h := h || floor(random() * 9000 + 1000)::int;
  end if;
  insert into profiles (id, name, handle, country, birth_year, gender)
  values (uid,
          coalesce(nullif(m->>'name', ''), split_part(email, '@', 1)),
          h,
          nullif(m->>'country', ''),
          nullif(m->>'birth_year', '')::int,
          nullif(m->>'gender', ''))
  on conflict (id) do nothing;
end $$;
revoke execute on function public.ensure_profile(uuid, text, jsonb) from public, anon, authenticated;

create or replace function public.on_auth_user_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.ensure_profile(new.id, new.email, new.raw_user_meta_data);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.on_auth_user_created();

-- Recrée un profil pour les comptes déjà existants
select public.ensure_profile(id, email, raw_user_meta_data) from auth.users;

-- ── POINTS (calculés côté base, pas modifiables par l'appli) ────
create or replace function public.on_top_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update profiles set points = points + 50, tops_filled = tops_filled + 1 where id = new.user_id;
  return new;
end $$;
create trigger tops_after_insert after insert on public.tops
  for each row execute function public.on_top_inserted();

create or replace function public.on_topic_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.created_by is not null then
    update profiles set points = points + 20, tops_created = tops_created + 1 where id = new.created_by;
  end if;
  return new;
end $$;
create trigger topics_after_insert after insert on public.topics
  for each row execute function public.on_topic_inserted();

-- ── SÉCURITÉ (Row Level Security) ───────────────────────────────
alter table public.profiles          enable row level security;
alter table public.topics            enable row level security;
alter table public.topic_suggestions enable row level security;
alter table public.tops              enable row level security;
alter table public.top_items         enable row level security;
alter table public.likes             enable row level security;

create policy "lecture profils"  on public.profiles for select to authenticated using (true);
create policy "maj son profil"   on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
-- Seuls ces champs sont modifiables par l'utilisateur (pas les points)
revoke update on public.profiles from anon, authenticated;
grant update (name, handle, country, birth_year, gender) on public.profiles to authenticated;

create policy "lecture sujets"   on public.topics for select to authenticated using (true);
create policy "créer un sujet"   on public.topics for insert to authenticated
  with check (created_by = auth.uid() and is_official = false);

create policy "lecture suggestions" on public.topic_suggestions for select to authenticated using (true);

create policy "lecture tops"     on public.tops for select to authenticated using (true);
create policy "créer son top"    on public.tops for insert to authenticated with check (user_id = auth.uid());
create policy "suppr son top"    on public.tops for delete to authenticated using (user_id = auth.uid());

create policy "lecture items"    on public.top_items for select to authenticated using (true);
create policy "créer ses items"  on public.top_items for insert to authenticated
  with check (exists (select 1 from public.tops t where t.id = top_id and t.user_id = auth.uid()));
create policy "suppr ses items"  on public.top_items for delete to authenticated
  using (exists (select 1 from public.tops t where t.id = top_id and t.user_id = auth.uid()));

create policy "lecture likes"    on public.likes for select to authenticated using (true);
create policy "liker"            on public.likes for insert to authenticated with check (user_id = auth.uid());
create policy "unliker"          on public.likes for delete to authenticated using (user_id = auth.uid());
