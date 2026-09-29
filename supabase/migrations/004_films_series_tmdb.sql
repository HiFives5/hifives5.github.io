-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 004 : films et séries reliés à TMDB
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien.
--
-- • topics.entity_type : 'movie' (réponses = films), 'tv' (réponses = séries)
--   ou vide (texte libre).
-- • top_items.ext_id : identifiant TMDB de la réponse (ex. tmdb:movie:680),
--   + année et affiche. Deux personnes qui choisissent le même film ont le
--   même identifiant : plus de doublons ni de fautes d'orthographe.
-- ════════════════════════════════════════════════════════════════

alter table public.topics
  add column if not exists entity_type text check (entity_type in ('movie', 'tv'));

alter table public.top_items
  add column if not exists ext_id text check (ext_id ~ '^tmdb:(movie|tv):[0-9]+$'),
  add column if not exists year   int  check (year between 1850 and 2100),
  add column if not exists poster text check (char_length(poster) <= 200);
create index if not exists top_items_ext_idx on public.top_items(ext_id);

-- Sujets officiels dont les réponses sont des films
update public.topics set entity_type = 'movie'
where entity_type is null and title in (
  'Top 5 films italiens de tous les temps',
  'Top 5 films de Tarantino',
  'Top 5 comédies françaises',
  'Top 5 films de science-fiction',
  'Top 5 films d''animation',
  'Top 5 films d''horreur',
  'Top 5 films Pixar',
  'Top 5 films surcotés'
);

-- Sujets officiels dont les réponses sont des séries / programmes TV
update public.topics set entity_type = 'tv'
where entity_type is null and title in (
  'Top 5 séries de tous les temps',
  'Top 5 séries Netflix',
  'Top 5 séries françaises',
  'Top 5 sitcoms',
  'Top 5 séries d''animation',
  'Top 5 séries policières',
  'Top 5 dessins animés de ton enfance',
  'Top 5 émissions TV cultes'
);

-- Sujets créés par les utilisateurs : on devine d'après la catégorie et le titre
-- (à corriger au besoin dans Table Editor > topics > entity_type)
update public.topics set entity_type = 'tv'
where entity_type is null and not is_official and category = 'Séries' and title ~* 's[ée]ries?';
update public.topics set entity_type = 'movie'
where entity_type is null and not is_official and category = 'Cinéma' and title ~* 'films?';
