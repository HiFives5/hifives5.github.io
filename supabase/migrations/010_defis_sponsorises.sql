-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 010 : défis sponsorisés
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable.
--
-- Un défi sponsorisé = un sujet mis en avant sur l'accueil aux couleurs d'une marque,
-- avec un bonus de points (calculé par la base, uniquement pendant la période du défi).
-- Gestion : Table Editor > sponsored_challenges (modifiable par les admins uniquement).
-- ════════════════════════════════════════════════════════════════

-- Points bonus cumulés (non modifiables depuis l'appli : hors des droits de mise à jour)
alter table public.profiles add column if not exists bonus_points int not null default 0;

create table if not exists public.sponsored_challenges (
  id           uuid primary key default gen_random_uuid(),
  topic_id     uuid not null references public.topics(id) on delete cascade,
  brand        text not null check (char_length(brand) between 1 and 60),
  tagline      text check (char_length(tagline) <= 140),
  emoji        text check (char_length(emoji) <= 8),
  logo_url     text check (logo_url ~ '^https://' and char_length(logo_url) <= 300),
  color        text not null default '#5B2C14' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  bonus_points int  not null default 100 check (bonus_points between 0 and 1000),
  cta_label    text check (char_length(cta_label) <= 40),
  cta_url      text check (cta_url ~ '^https://' and char_length(cta_url) <= 300),
  starts_at    timestamptz not null default now(),
  ends_at      timestamptz not null default now() + interval '7 days',
  is_example   boolean not null default true,   -- « Exemple de partenariat » tant qu'aucun accord n'est signé
  created_at   timestamptz not null default now()
);

alter table public.sponsored_challenges enable row level security;
drop policy if exists "lecture défis sponsorisés" on public.sponsored_challenges;
drop policy if exists "admin gère les défis sponsorisés" on public.sponsored_challenges;
create policy "lecture défis sponsorisés" on public.sponsored_challenges for select to authenticated using (true);
create policy "admin gère les défis sponsorisés" on public.sponsored_challenges for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Points : +50 par top, + le bonus du défi sponsorisé en cours sur ce sujet
create or replace function public.on_top_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  b int;
begin
  select coalesce(max(bonus_points), 0) into b
  from sponsored_challenges
  where topic_id = new.topic_id and now() between starts_at and ends_at;
  update profiles
  set points = points + 50 + b, tops_filled = tops_filled + 1, bonus_points = bonus_points + b
  where id = new.user_id;
  return new;
end $$;

-- ── Exemple : défi « saveurs Danette » (marqué « Exemple de partenariat ») ──
with t as (
  insert into public.topics (title, category, is_official)
  values ('Top 5 saveurs de Danette', 'Gastronomie', true)
  on conflict do nothing
  returning id
),
sugg(content, weight) as (values
  ('Chocolat', 8), ('Vanille', 7), ('Caramel', 6), ('Chocolat noir', 5),
  ('Praliné', 4), ('Chocolat au lait', 3), ('Café', 2), ('Pistache', 1)
),
s as (
  insert into public.topic_suggestions (topic_id, content, weight)
  select t.id, sugg.content, sugg.weight from t, sugg
  on conflict do nothing
)
insert into public.sponsored_challenges (topic_id, brand, tagline, emoji, color, bonus_points, cta_label, cta_url, ends_at, is_example)
select t.id, 'Danette', 'On se lève tous pour… laquelle ? Classe tes 5 saveurs préférées !', '🍮', '#5B2C14', 100,
       'Découvrir les saveurs', 'https://www.danette.fr', now() + interval '30 days', true
from t;

-- Les profils de démo (s'il en reste) remplissent ~60 % des sujets officiels encore vides pour eux
insert into public.tops (topic_id, user_id, created_at)
select t.id, p.id, now() - random() * interval '3 days'
from public.topics t cross join public.profiles p
where p.is_demo and t.is_official and random() < 0.6
  and not exists (select 1 from public.tops x join public.profiles px on px.id = x.user_id where x.topic_id = t.id and px.is_demo)
on conflict do nothing;

insert into public.top_items (top_id, rank, content)
select x.top_id, x.rk, x.content
from (
  select tp.id as top_id, s.content,
         row_number() over (partition by tp.id order by power(random(), 1.0 / s.weight) desc) as rk
  from public.tops tp
  join public.profiles p on p.id = tp.user_id and p.is_demo
  join public.topic_suggestions s on s.topic_id = tp.topic_id
  where not exists (select 1 from public.top_items i where i.top_id = tp.id)
) x
where x.rk <= 5
on conflict do nothing;
