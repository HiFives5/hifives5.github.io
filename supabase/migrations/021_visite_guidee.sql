-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 021 : visite guidée des nouveautés
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run. N'efface rien ; relançable.
--
-- profiles.intro_seen : dernière version de la visite vue par le compte (0 = jamais).
-- Elle s'affiche une seule fois par compte (et non par téléphone), à l'ouverture suivante de l'appli.
-- ════════════════════════════════════════════════════════════════

alter table public.profiles add column if not exists intro_seen int not null default 0;
grant update (intro_seen) on public.profiles to authenticated;
