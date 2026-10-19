-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 015 : nouvelles sources de suggestions
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 012).
-- N'efface rien ; relançable.
--
-- top_items.ext_id accepte aussi :
--   osm:<n|w|r><id>  lieux OpenStreetMap (villes, pays, îles, plages…)
--   off:<code-barres> produits Open Food Facts
-- (sans cette migration, l'appli enregistre ces réponses en texte simple)
-- ════════════════════════════════════════════════════════════════

alter table public.top_items drop constraint if exists top_items_ext_id_check;
alter table public.top_items
  add constraint top_items_ext_id_check check (ext_id ~ '^(tmdb:(movie|tv):[0-9]+|wd:Q[0-9]+|mb:(artist|album|track):[0-9a-f-]{36}|dz:(artist|album|track):[0-9]+|osm:[nwr][0-9]+|off:[0-9]{4,20})$');
