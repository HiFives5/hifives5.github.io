-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 019 : notifications push
-- À exécuter APRÈS avoir créé l'Edge Function « hifives-push » (supabase/functions/hifives-push/index.ts),
-- dans Supabase > SQL Editor > New query > Run (après la 018). N'efface rien ; relançable.
--
-- • push_subscriptions : les téléphones de chacun qui acceptent les notifications
-- • push_config : clés VAPID générées et gardées par la fonction (aucune règle d'accès : lisible
--   uniquement côté serveur, jamais depuis l'appli)
-- • tâche planifiée (pg_cron + pg_net) : appelle la fonction chaque minute ; c'est elle qui envoie les
--   notifications en attente (groupées par personne, rien entre 22 h et 8 h) et le rappel du défi à 18 h.
--   La clé utilisée est la clé publique « anon » de l'appli (déjà présente dans app/index.html).
-- ════════════════════════════════════════════════════════════════

create table if not exists public.push_subscriptions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  endpoint     text not null unique check (endpoint ~ '^https://' and char_length(endpoint) <= 1000),
  p256dh       text not null check (char_length(p256dh) <= 200),
  auth         text not null check (char_length(auth) <= 100),
  ua           text check (char_length(ua) <= 300),
  last_push_at timestamptz,
  created_at   timestamptz not null default now()
);
create index if not exists push_subscriptions_user_idx on public.push_subscriptions(user_id);
alter table public.push_subscriptions enable row level security;
drop policy if exists "mes abonnements push" on public.push_subscriptions;
create policy "mes abonnements push" on public.push_subscriptions for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create table if not exists public.push_config (
  key   text primary key,
  value jsonb not null
);
alter table public.push_config enable row level security;   -- aucune règle : réservé au serveur

-- Appel de la fonction chaque minute
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;
select cron.unschedule('hifives-push') where exists (select 1 from cron.job where jobname = 'hifives-push');
select cron.schedule('hifives-push', '* * * * *', $cron$
  select net.http_post(
    url := 'https://nhqlirthmhkabshdepqb.supabase.co/functions/v1/hifives-push',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ocWxpcnRobWhrYWJzaGRlcHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwMzE0NjksImV4cCI6MjA5MjYwNzQ2OX0.eSXHyFsIFWA_5wTczBRF7IdOUKjlBoUtKVY83wl289c'),
    body := '{}'::jsonb
  );
$cron$);
