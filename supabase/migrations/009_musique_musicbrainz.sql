-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 009 : musique reliée à MusicBrainz
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable. Nécessite les migrations 004 et 008.
--
-- • topics.entity_type accepte : artist (artistes / groupes), album, track (chansons)
-- • top_items.ext_id accepte les identifiants MusicBrainz : mb:artist:<mbid>, mb:album:<mbid>, mb:track:<mbid>
--   (MusicBrainz : base musicale ouverte, données sous licence CC0)
-- ════════════════════════════════════════════════════════════════

alter table public.topics drop constraint if exists topics_entity_type_check;
alter table public.topics
  add constraint topics_entity_type_check check (entity_type in ('movie', 'tv', 'artist', 'album', 'track'));

alter table public.top_items drop constraint if exists top_items_ext_id_check;
alter table public.top_items
  add constraint top_items_ext_id_check check (ext_id ~ '^(tmdb:(movie|tv):[0-9]+|wd:Q[0-9]+|mb:(artist|album|track):[0-9a-f-]{36})$');

-- Sujets officiels de musique
update public.topics set entity_type = 'album'
where entity_type is null and title in (
  'Top 5 albums de rap West Coast',
  'Top 5 albums de rap français',
  'Top 5 albums des Beatles',
  'Top 5 albums de jazz',
  'Top 5 albums de tous les temps'
);

update public.topics set entity_type = 'artist'
where entity_type is null and title in (
  'Top 5 groupes de rock',
  'Top 5 artistes à voir en concert',
  'Top 5 artistes électro',
  'Top 5 chanteuses internationales',
  'Top 5 chanteurs et chanteuses français'
);

update public.topics set entity_type = 'track'
where entity_type is null and title in (
  'Top 5 chansons françaises de tous les temps',
  'Top 5 tubes des années 90'
);

-- Sujets créés par les utilisateurs dans la catégorie Musique : on devine d'après le titre
-- (à corriger au besoin dans Table Editor > topics > entity_type)
update public.topics set entity_type = 'album'
where entity_type is null and not is_official and category = 'Musique' and title ~* 'albums?';
update public.topics set entity_type = 'track'
where entity_type is null and not is_official and category = 'Musique' and title ~* '(chansons?|morceaux|titres|tubes?|sons)';
update public.topics set entity_type = 'artist'
where entity_type is null and not is_official and category = 'Musique' and title ~* '(artistes?|groupes?|chanteu|rappeu|musiciens?|DJ)';
