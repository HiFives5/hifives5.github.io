-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 020 : messagerie privée sur demande
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 018). N'efface rien ; relançable.
--
-- • conversations : une par paire de personnes ; le premier message est une DEMANDE
--   (status pending) : le destinataire l'accepte (ou répond) ou l'ignore ; ignorer est vraiment silencieux :
--   c'est noté dans conv_hidden, lisible par lui seul (pour l'expéditeur, la demande reste « en attente ») ;
--   un seul message tant que la demande n'est pas acceptée
-- • messages : texte seul, 1 000 caractères max, 30 messages / 10 min max par personne
-- • blocks : personnes bloquées (plus aucun message dans un sens ni dans l'autre)
-- • écrire : niveau 5 · Passionné (1 500 pts), vérifié par la base
-- • notifications « message » (cloche + push), regroupées par conversation, réglables
-- Toutes les écritures passent par des fonctions qui vérifient les règles ; les messages ne sont lisibles
-- que par les deux participants (un message signalé est recopié dans le signalement pour la modération).
-- ════════════════════════════════════════════════════════════════

create table if not exists public.conversations (
  id          uuid primary key default gen_random_uuid(),
  user_a      uuid not null references public.profiles(id) on delete cascade,
  user_b      uuid not null references public.profiles(id) on delete cascade,
  requester   uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'accepted', 'ignored')),
  last_at     timestamptz not null default now(),
  last_body   text,
  last_sender uuid,
  a_read_at   timestamptz,
  b_read_at   timestamptz,
  created_at  timestamptz not null default now(),
  check (user_a < user_b),
  unique (user_a, user_b)
);
create index if not exists conversations_b_idx on public.conversations(user_b);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  body            text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at      timestamptz not null default now()
);
create index if not exists messages_conv_idx on public.messages(conversation_id, created_at);
create index if not exists messages_sender_idx on public.messages(sender_id, created_at);

create table if not exists public.conv_hidden (
  user_id         uuid not null references public.profiles(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (user_id, conversation_id)
);

create table if not exists public.blocks (
  blocker    uuid not null references public.profiles(id) on delete cascade,
  blocked    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked)
);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.conv_hidden enable row level security;
drop policy if exists "mes demandes ignorées" on public.conv_hidden;
create policy "mes demandes ignorées" on public.conv_hidden for select to authenticated using (user_id = auth.uid());
drop policy if exists "mes conversations" on public.conversations;
drop policy if exists "messages de mes conversations" on public.messages;
drop policy if exists "admin supprime un message" on public.messages;
drop policy if exists "mes blocages" on public.blocks;
create policy "mes conversations" on public.conversations for select to authenticated
  using (auth.uid() in (user_a, user_b));
create policy "messages de mes conversations" on public.messages for select to authenticated
  using (exists (select 1 from public.conversations c where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b)));
create policy "admin supprime un message" on public.messages for delete to authenticated using (public.is_admin());
create policy "mes blocages" on public.blocks for select to authenticated using (blocker = auth.uid());
revoke insert, update, delete on public.conversations, public.messages, public.blocks, public.conv_hidden from anon, authenticated;
grant delete on public.messages to authenticated;   -- limité aux admins par la règle ci-dessus

-- Notifications : nouveau type « message »
alter table public.notifications drop constraint if exists notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check
  check (kind in ('comment', 'hi5', 'badge', 'level', 'invite', 'soulmate', 'daily', 'message'));

create or replace function public.is_blocked(x uuid, y uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from blocks where (blocker = x and blocked = y) or (blocker = y and blocked = x));
$$;

-- Envoyer un message (crée la demande si besoin ; répondre à une demande l'accepte)
create or replace function public.send_message(other uuid, body text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  a uuid; b uuid; c conversations%rowtype;
  txt text := btrim(coalesce(body, ''));
begin
  if me is null or other is null or other = me then raise exception 'Destinataire invalide.'; end if;
  if char_length(txt) < 1 or char_length(txt) > 1000 then raise exception 'Message vide ou trop long (1 000 caractères max).'; end if;
  if my_points() < 1500 then raise exception 'La messagerie se débloque au niveau 5 (1 500 points).'; end if;
  if is_blocked(me, other) then raise exception 'Conversation indisponible.'; end if;
  if not exists (select 1 from profiles where id = other) then raise exception 'Destinataire introuvable.'; end if;
  if (select count(*) from messages where sender_id = me and created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'Doucement ! Trop de messages en peu de temps, réessaie dans quelques minutes.';
  end if;
  a := least(me, other); b := greatest(me, other);
  select * into c from conversations where user_a = a and user_b = b for update;
  if not found then
    insert into conversations (user_a, user_b, requester) values (a, b, me) returning * into c;
  elsif c.status <> 'accepted' then
    if c.requester = me then raise exception 'Demande déjà envoyée : attends sa réponse.'; end if;
    update conversations set status = 'accepted' where id = c.id;   -- répondre = accepter
    delete from conv_hidden where user_id = me and conversation_id = c.id;
    c.status := 'accepted';
  end if;
  insert into messages (conversation_id, sender_id, body) values (c.id, me, txt);
  update conversations set last_at = now(), last_body = left(txt, 120), last_sender = me,
    a_read_at = case when me = user_a then now() else a_read_at end,
    b_read_at = case when me = user_b then now() else b_read_at end
  where id = c.id;
  return c.id;
end $$;

-- Accepter ou ignorer une demande reçue (ignorer reste invisible pour l'expéditeur)
create or replace function public.respond_request(conv uuid, accept boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from conversations where id = conv and auth.uid() in (user_a, user_b)
                 and requester <> auth.uid() and status <> 'accepted') then return; end if;
  if accept then
    update conversations set status = 'accepted' where id = conv;
    delete from conv_hidden where user_id = auth.uid() and conversation_id = conv;
  else
    insert into conv_hidden (user_id, conversation_id) values (auth.uid(), conv) on conflict do nothing;
  end if;
end $$;

create or replace function public.mark_conversation_read(conv uuid)
returns void language sql security definer set search_path = public as $$
  update conversations set
    a_read_at = case when auth.uid() = user_a then now() else a_read_at end,
    b_read_at = case when auth.uid() = user_b then now() else b_read_at end
  where id = conv and auth.uid() in (user_a, user_b);
$$;

create or replace function public.block_user(other uuid, block boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or other is null or other = auth.uid() then return; end if;
  if block then insert into blocks (blocker, blocked) values (auth.uid(), other) on conflict do nothing;
  else delete from blocks where blocker = auth.uid() and blocked = other; end if;
end $$;

revoke execute on function public.send_message(uuid, text) from public, anon;
revoke execute on function public.respond_request(uuid, boolean) from public, anon;
revoke execute on function public.mark_conversation_read(uuid) from public, anon;
revoke execute on function public.block_user(uuid, boolean) from public, anon;
revoke execute on function public.is_blocked(uuid, uuid) from public, anon;
grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.respond_request(uuid, boolean) to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
grant execute on function public.block_user(uuid, boolean) to authenticated;
grant execute on function public.is_blocked(uuid, uuid) to authenticated;

-- Notification au destinataire (regroupée par conversation tant qu'elle n'est pas lue)
create or replace function public.notif_on_message() returns trigger language plpgsql security definer set search_path = public as $$
declare c conversations%rowtype; dest uuid; nid uuid;
begin
  select * into c from conversations where id = new.conversation_id;
  dest := case when new.sender_id = c.user_a then c.user_b else c.user_a end;
  if exists (select 1 from conv_hidden where user_id = dest and conversation_id = c.id)
     or is_blocked(dest, new.sender_id) or not notif_on(dest, 'message') then return new; end if;
  select id into nid from notifications
  where user_id = dest and kind = 'message' and read_at is null and data ->> 'conv' = c.id::text limit 1;
  if nid is null then
    insert into notifications (user_id, kind, actor_id, data)
    values (dest, 'message', new.sender_id, jsonb_build_object('conv', c.id, 'body', left(new.body, 90), 'count', 1,
      'request', c.status = 'pending', 'text', case when c.status = 'pending' then 'Nouvelle demande de message' else 'Nouveau message' end));
  else
    update notifications set actor_id = new.sender_id, created_at = now(), pushed_at = null,
      data = data || jsonb_build_object('body', left(new.body, 90), 'count', coalesce((data ->> 'count')::int, 1) + 1)
    where id = nid;
  end if;
  return new;
end $$;
drop trigger if exists messages_notif on public.messages;
create trigger messages_notif after insert on public.messages for each row execute function public.notif_on_message();
