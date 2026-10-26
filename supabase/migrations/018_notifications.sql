-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 018 : centre de notifications 🔔
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 013).
-- N'efface rien ; relançable.
--
-- • notifications : une ligne par événement pour son destinataire (lu / non lu ; pushed_at servira au push)
--   - comment  : commentaire sur un de mes tops
--   - hi5      : high fives reçus sur un top (regroupés tant que non lus)
--   - badge    : badge débloqué            - level : passage de niveau
--   - invite   : un ami a rempli le top que je lui ai partagé
--   - soulmate : nouvelle âme sœur détectée par le radar (calculé dans l'appli)
-- • profiles.notif_prefs : réglages par type ({"comment": false, …} ; absent = activé)
-- Les notifications sont créées par la base (déclencheurs), jamais librement par l'appli.
-- ════════════════════════════════════════════════════════════════

alter table public.profiles add column if not exists notif_prefs jsonb not null default '{}'::jsonb;
grant update (notif_prefs) on public.profiles to authenticated;

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  kind       text not null check (kind in ('comment', 'hi5', 'badge', 'level', 'invite', 'soulmate', 'daily')),
  actor_id   uuid references public.profiles(id) on delete cascade,
  top_id     uuid references public.tops(id) on delete cascade,
  topic_id   uuid references public.topics(id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at    timestamptz,
  pushed_at  timestamptz
);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);
create unique index if not exists notifications_invite_uniq on public.notifications(user_id, actor_id, topic_id) where kind = 'invite';
create unique index if not exists notifications_soulmate_uniq on public.notifications(user_id, actor_id) where kind = 'soulmate';

alter table public.notifications enable row level security;
drop policy if exists "lire ses notifications" on public.notifications;
drop policy if exists "marquer ses notifications" on public.notifications;
drop policy if exists "supprimer ses notifications" on public.notifications;
drop policy if exists "radar âme sœur" on public.notifications;
create policy "lire ses notifications" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "marquer ses notifications" on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "supprimer ses notifications" on public.notifications for delete to authenticated using (user_id = auth.uid());
-- Le radar est calculé dans l'appli : on ne peut s'inscrire qu'à soi-même une âme sœur
create policy "radar âme sœur" on public.notifications for insert to authenticated
  with check (user_id = auth.uid() and kind = 'soulmate' and actor_id is not null and actor_id <> auth.uid());
revoke update on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

-- Réglage d'un type pour une personne (activé par défaut)
create or replace function public.notif_on(uid uuid, k text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select (notif_prefs ->> k)::boolean from profiles where id = uid), true);
$$;

-- Niveau (même échelle que l'appli)
create or replace function public.level_of(pts int)
returns int language sql immutable as $$
  select count(*)::int from unnest(array[0, 150, 400, 800, 1500, 2500, 4000, 6500, 10000, 15000]) t where pts >= t;
$$;

-- Commentaire sur un de mes tops
create or replace function public.notif_on_comment() returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; tp uuid;
begin
  select user_id, topic_id into owner, tp from tops where id = new.top_id;
  if owner is not null and owner <> new.user_id and notif_on(owner, 'comment') then
    insert into notifications (user_id, kind, actor_id, top_id, topic_id, data)
    values (owner, 'comment', new.user_id, new.top_id, tp, jsonb_build_object('body', left(new.body, 90)));
  end if;
  return new;
end $$;
drop trigger if exists comments_notif on public.comments;
create trigger comments_notif after insert on public.comments for each row execute function public.notif_on_comment();

-- High five : regroupé avec la notification non lue du même top
create or replace function public.notif_on_like() returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; tp uuid; nid uuid;
begin
  select user_id, topic_id into owner, tp from tops where id = new.top_id;
  if owner is null or owner = new.user_id or not notif_on(owner, 'hi5') then return new; end if;
  select id into nid from notifications where user_id = owner and kind = 'hi5' and top_id = new.top_id and read_at is null limit 1;
  if nid is null then
    insert into notifications (user_id, kind, actor_id, top_id, topic_id, data)
    values (owner, 'hi5', new.user_id, new.top_id, tp, jsonb_build_object('count', 1));
  else
    update notifications set actor_id = new.user_id, created_at = now(), pushed_at = null,
      data = jsonb_set(data, '{count}', to_jsonb(coalesce((data ->> 'count')::int, 1) + 1))
    where id = nid;
  end if;
  return new;
end $$;
drop trigger if exists likes_notif on public.likes;
create trigger likes_notif after insert on public.likes for each row execute function public.notif_on_like();

-- Badges : la même fonction, qui annonce désormais chaque nouveau badge
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
  ), n as (
    insert into notifications (user_id, kind, data)
    select uid, 'badge', jsonb_build_object('badge', b.code, 'emoji', b.emoji, 'label', b.label, 'points', b.points)
    from ins join badges b on b.code = ins.badge
    where notif_on(uid, 'progress')
  )
  select coalesce(sum(b.points), 0) into pts from ins join badges b on b.code = ins.badge;
  if pts > 0 then
    update profiles set points = points + pts, badge_points = badge_points + pts where id = uid;
  end if;
end $$;
revoke execute on function public.award_badges(uuid) from public, anon, authenticated;

-- Passage de niveau
create or replace function public.notif_on_level() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if level_of(new.points) > level_of(old.points) and notif_on(new.id, 'progress') then
    insert into notifications (user_id, kind, data) values (new.id, 'level', jsonb_build_object('level', level_of(new.points)));
  end if;
  return new;
end $$;
drop trigger if exists profiles_level_notif on public.profiles;
create trigger profiles_level_notif after update of points on public.profiles for each row execute function public.notif_on_level();

-- Invitation : la personne invitée a rempli le sujet partagé (vérifié : les deux ont un top sur ce sujet)
create or replace function public.notify_invite(inviter uuid, topic uuid, pct int)
returns void language plpgsql security definer set search_path = public as $$
begin
  if inviter is null or inviter = auth.uid() or not notif_on(inviter, 'invite') then return; end if;
  if not exists (select 1 from tops where user_id = auth.uid() and topic_id = topic)
     or not exists (select 1 from tops where user_id = inviter and topic_id = topic) then return; end if;
  insert into notifications (user_id, kind, actor_id, topic_id, data)
  values (inviter, 'invite', auth.uid(), topic, jsonb_build_object('pct', greatest(0, least(100, coalesce(pct, 0)))))
  on conflict do nothing;
end $$;
revoke execute on function public.notify_invite(uuid, uuid, int) from public, anon;
grant execute on function public.notify_invite(uuid, uuid, int) to authenticated;
