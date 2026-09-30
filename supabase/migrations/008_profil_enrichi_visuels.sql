-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 008 : profil enrichi + visuels Wikidata
-- (suite aux retours « détaille le profil » et « ajoute des visuels »)
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable sans doublon.
--
-- • profiles.bio        : petit mot (160 caractères max)
-- • profiles.links      : identifiants sur d'autres applis, ex. {"instagram":"lionel"}
-- • profiles.avatar_url : photo de profil (stockée dans le bucket « avatars »)
-- • top_items.ext_id accepte aussi les identifiants Wikidata (wd:Q483020)
-- ════════════════════════════════════════════════════════════════

alter table public.profiles
  add column if not exists bio        text  check (char_length(bio) <= 160),
  add column if not exists links      jsonb not null default '{}'::jsonb
    check (jsonb_typeof(links) = 'object' and char_length(links::text) <= 700),
  add column if not exists avatar_url text  check (char_length(avatar_url) <= 300);

grant update (bio, links, avatar_url) on public.profiles to authenticated;

-- Photos de profil : lecture publique, écriture uniquement dans son propre dossier (<id>/…)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 512000, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 512000,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "avatars lecture" on storage.objects;
create policy "avatars lecture" on storage.objects for select using (bucket_id = 'avatars');
drop policy if exists "avatars ajout" on storage.objects;
create policy "avatars ajout" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "avatars maj" on storage.objects;
create policy "avatars maj" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "avatars suppression" on storage.objects;
create policy "avatars suppression" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Réponses choisies dans Wikidata (en plus de TMDB)
alter table public.top_items drop constraint if exists top_items_ext_id_check;
alter table public.top_items
  add constraint top_items_ext_id_check check (ext_id ~ '^(tmdb:(movie|tv):[0-9]+|wd:Q[0-9]+)$');
