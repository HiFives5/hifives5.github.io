-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 012 : musique reliée à Deezer
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 009).
-- N'efface rien ; relançable.
--
-- top_items.ext_id accepte les identifiants Deezer : dz:artist:<id>, dz:album:<id>, dz:track:<id>
-- (les anciennes réponses MusicBrainz mb:… restent valables)
-- ════════════════════════════════════════════════════════════════

alter table public.top_items drop constraint if exists top_items_ext_id_check;
alter table public.top_items
  add constraint top_items_ext_id_check check (ext_id ~ '^(tmdb:(movie|tv):[0-9]+|wd:Q[0-9]+|mb:(artist|album|track):[0-9a-f-]{36}|dz:(artist|album|track):[0-9]+)$');
