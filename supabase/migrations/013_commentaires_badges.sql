-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 013 : commentaires sur les tops, signalements, badges
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 010).
-- N'efface rien ; relançable.
--
-- • comments : commentaires publics sous le top d'une personne
--   (suppression : l'auteur, le propriétaire du top, ou un admin)
-- • feedback.kind accepte 'signalement' (commentaire signalé → page admin)
-- • badges : catalogue des badges ; user_badges : badges obtenus ; profiles.badge_points
--   Les badges et leurs points sont attribués par la base (déclencheurs), jamais par l'appli.
--   Les exploits déjà réalisés sont récompensés rétroactivement en fin de migration.
-- ════════════════════════════════════════════════════════════════

-- ── Commentaires ────────────────────────────────────────────────
create table if not exists public.comments (
  id         uuid primary key default gen_random_uuid(),
  top_id     uuid not null references public.tops(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  body       text not null check (char_length(btrim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists comments_top_idx on public.comments(top_id, created_at);
create index if not exists comments_user_idx on public.comments(user_id);

alter table public.comments enable row level security;
drop policy if exists "lecture commentaires" on public.comments;
drop policy if exists "commenter" on public.comments;
drop policy if exists "suppr commentaire" on public.comments;
create policy "lecture commentaires" on public.comments for select to authenticated using (true);
create policy "commenter" on public.comments for insert to authenticated with check (user_id = auth.uid());
create policy "suppr commentaire" on public.comments for delete to authenticated using (
  user_id = auth.uid()
  or exists (select 1 from public.tops t where t.id = top_id and t.user_id = auth.uid())
  or public.is_admin()
);
revoke update on public.comments from anon, authenticated;

-- Anti-spam : 20 commentaires maximum par tranche de 10 minutes
create or replace function public.comments_rate_limit()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from comments where user_id = new.user_id and created_at > now() - interval '10 minutes') >= 20 then
    raise exception 'Doucement ! Trop de commentaires en peu de temps, réessaie dans quelques minutes.';
  end if;
  return new;
end $$;
drop trigger if exists comments_before_insert on public.comments;
create trigger comments_before_insert before insert on public.comments
  for each row execute function public.comments_rate_limit();

-- ── Signalements (réutilisent les retours) ─────────────────────
alter table public.feedback drop constraint if exists feedback_kind_check;
alter table public.feedback add constraint feedback_kind_check check (kind in ('bug', 'idee', 'avis', 'signalement'));

-- ── Badges ──────────────────────────────────────────────────────
alter table public.profiles add column if not exists badge_points int not null default 0;

create table if not exists public.badges (
  code      text primary key,
  metric    text not null,
  threshold int  not null,
  points    int  not null default 0,
  emoji     text not null,
  label     text not null,
  descr     text not null,
  sort      int  not null default 0
);
alter table public.badges enable row level security;
drop policy if exists "lecture badges" on public.badges;
create policy "lecture badges" on public.badges for select to authenticated using (true);

insert into public.badges (code, metric, threshold, points, emoji, label, descr, sort) values
  ('fill_10',    'fill',        10,  50, '🔟', 'Habitué',           'Remplir 10 tops',                                  10),
  ('fill_50',    'fill',        50, 150, '📚', 'Encyclopédie',      'Remplir 50 tops',                                  11),
  ('fill_100',   'fill',       100, 300, '🏛️', 'Légende',           'Remplir 100 tops',                                 12),
  ('create_1',   'create',       1,  30, '✏️', 'Créateur',          'Créer un sujet',                                   20),
  ('create_5',   'create',       5, 100, '🏗️', 'Bâtisseur',         'Créer 5 sujets',                                   21),
  ('topic_10',   'topic_fill',  10, 100, '🔥', 'Sujet à succès',    'Créer un sujet rempli par 10 personnes',           22),
  ('topic_50',   'topic_fill',  50, 300, '🚀', 'Sujet culte',       'Créer un sujet rempli par 50 personnes',           23),
  ('hi5top_5',   'hi5_top',      5,  50, '✋', 'Ça plaît',           'Recevoir 5 high fives sur un même top',            30),
  ('hi5top_20',  'hi5_top',     20, 200, '🌟', 'Star',              'Recevoir 20 high fives sur un même top',           31),
  ('hi5_50',     'hi5_total',   50, 100, '🙌', 'Populaire',         'Recevoir 50 high fives au total',                  32),
  ('debate_5',   'debate',       5, 100, '💬', 'Débat lancé',       '5 personnes ont commenté un même top',             40),
  ('debate_15',  'debate',      15, 250, '🌶️', 'Polémique',         '15 personnes ont commenté un même top',            41),
  ('talk_10',    'talk',        10,  50, '🗣️', 'Bavard',            'Commenter les tops de 10 personnes différentes',   42),
  ('give_20',    'give',        20,  30, '🤝', 'Généreux',          'Donner 20 high fives',                             50),
  ('sponsor_5',  'sponsor',      5, 100, '🎯', 'Chasseur de défis', 'Relever 5 défis sponsorisés',                      51)
on conflict (code) do update set metric = excluded.metric, threshold = excluded.threshold, points = excluded.points,
  emoji = excluded.emoji, label = excluded.label, descr = excluded.descr, sort = excluded.sort;

create table if not exists public.user_badges (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  badge      text not null references public.badges(code) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, badge)
);
alter table public.user_badges enable row level security;
drop policy if exists "lecture badges obtenus" on public.user_badges;
create policy "lecture badges obtenus" on public.user_badges for select to authenticated using (true);
revoke insert, update, delete on public.user_badges from anon, authenticated;

-- Compteurs d'une personne (les interactions avec soi-même ne comptent pas)
create or replace function public.badge_stats(uid uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'fill',       (select count(*) from tops where user_id = uid),
    'create',     (select count(*) from topics where created_by = uid),
    'topic_fill', (select coalesce(max(n), 0) from (select count(*) n from tops t join topics s on s.id = t.topic_id
                     where s.created_by = uid and t.user_id <> uid group by s.id) x),
    'hi5_top',    (select coalesce(max(n), 0) from (select count(*) n from likes l join tops t on t.id = l.top_id
                     where t.user_id = uid and l.user_id <> uid group by t.id) x),
    'hi5_total',  (select count(*) from likes l join tops t on t.id = l.top_id where t.user_id = uid and l.user_id <> uid),
    'debate',     (select coalesce(max(n), 0) from (select count(distinct c.user_id) n from comments c join tops t on t.id = c.top_id
                     where t.user_id = uid and c.user_id <> uid group by t.id) x),
    'talk',       (select count(distinct t.user_id) from comments c join tops t on t.id = c.top_id where c.user_id = uid and t.user_id <> uid),
    'give',       (select count(*) from likes l join tops t on t.id = l.top_id where l.user_id = uid and t.user_id <> uid),
    'sponsor',    (select count(distinct t.id) from tops t join sponsored_challenges c on c.topic_id = t.topic_id
                     and t.created_at between c.starts_at and c.ends_at where t.user_id = uid)
  );
$$;
revoke execute on function public.badge_stats(uuid) from public, anon;
grant execute on function public.badge_stats(uuid) to authenticated;

-- Attribue les badges atteints (une seule fois chacun) et crédite leurs points
create or replace function public.award_badges(uid uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  st  jsonb;
  pts int;
begin
  if uid is null then return; end if;
  st := badge_stats(uid);
  with ins as (
    insert into user_badges (user_id, badge)
    select uid, b.code from badges b where coalesce((st ->> b.metric)::int, 0) >= b.threshold
    on conflict do nothing
    returning badge
  )
  select coalesce(sum(b.points), 0) into pts from ins join badges b on b.code = ins.badge;
  if pts > 0 then
    update profiles set points = points + pts, badge_points = badge_points + pts where id = uid;
  end if;
end $$;
revoke execute on function public.award_badges(uuid) from public, anon, authenticated;

create or replace function public.badges_on_top() returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform award_badges(new.user_id);
  perform award_badges((select created_by from topics where id = new.topic_id));
  return new;
end $$;
create or replace function public.badges_on_topic() returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform award_badges(new.created_by);
  return new;
end $$;
create or replace function public.badges_on_reaction() returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform award_badges(new.user_id);
  perform award_badges((select user_id from tops where id = new.top_id));
  return new;
end $$;

drop trigger if exists tops_badges on public.tops;
create trigger tops_badges after insert on public.tops for each row execute function public.badges_on_top();
drop trigger if exists topics_badges on public.topics;
create trigger topics_badges after insert on public.topics for each row execute function public.badges_on_topic();
drop trigger if exists likes_badges on public.likes;
create trigger likes_badges after insert on public.likes for each row execute function public.badges_on_reaction();
drop trigger if exists comments_badges on public.comments;
create trigger comments_badges after insert on public.comments for each row execute function public.badges_on_reaction();

-- Rattrapage : les exploits déjà réalisés débloquent leurs badges
select public.award_badges(id) from public.profiles;
