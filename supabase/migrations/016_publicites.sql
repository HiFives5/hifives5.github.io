-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 016 : régie publicitaire maison
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 003).
-- N'efface rien ; relançable.
--
-- • ads : bandeaux publicitaires gérés depuis la page admin de l'appli
--   (texte, emoji, couleur, lien, thème ciblé, dates, poids dans la rotation)
-- • compteurs d'affichages et de clics agrégés : aucun suivi individuel, aucun cookie
-- • lien : https://… ou action interne hifives:share (inviter des amis) / hifives:partner (devenir partenaire)
-- ════════════════════════════════════════════════════════════════

create table if not exists public.ads (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 1 and 60),
  body        text check (char_length(body) <= 140),
  emoji       text check (char_length(emoji) <= 8),
  color       text not null default '#FF5C2E' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  cta_label   text check (char_length(cta_label) <= 30),
  cta_url     text check (cta_url ~ '^(https://|hifives:(share|partner)$)' and char_length(cta_url) <= 300),
  category    text,                          -- thème ciblé (null = partout)
  weight      int  not null default 1 check (weight between 1 and 10),
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz,                   -- null = sans fin
  active      boolean not null default true,
  is_example  boolean not null default false,
  impressions int not null default 0,
  clicks      int not null default 0,
  created_at  timestamptz not null default now()
);

alter table public.ads enable row level security;
drop policy if exists "lecture pubs" on public.ads;
drop policy if exists "admin gère les pubs" on public.ads;
create policy "lecture pubs" on public.ads for select to authenticated using (active or public.is_admin());
create policy "admin gère les pubs" on public.ads for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Compteurs (appelés par l'appli ; seuls les totaux sont conservés)
create or replace function public.ad_seen(ids uuid[])
returns void language sql security definer set search_path = public as $$
  update ads set impressions = impressions + 1 where id = any(ids[1:10]) and active;
$$;
create or replace function public.ad_click(ad uuid)
returns void language sql security definer set search_path = public as $$
  update ads set clicks = clicks + 1 where id = ad and active;
$$;
revoke execute on function public.ad_seen(uuid[]) from public, anon;
revoke execute on function public.ad_click(uuid) from public, anon;
grant execute on function public.ad_seen(uuid[]) to authenticated;
grant execute on function public.ad_click(uuid) to authenticated;

-- Deux bandeaux « maison » pour démarrer (modifiables ou désactivables dans la page admin)
insert into public.ads (title, body, emoji, color, cta_label, cta_url, weight, is_example)
select * from (values
  ('Compare-toi à tes amis', 'Partage un top sur WhatsApp et découvre ta compatibilité avec eux.', '📤', '#25D366', 'Inviter', 'hifives:share', 2, true),
  ('Votre marque sur HiFives', 'Défis sponsorisés, bandeaux ciblés par thème : devenez partenaire.', '🤝', '#FF5C2E', 'Nous écrire', 'hifives:partner', 1, true)
) v(title, body, emoji, color, cta_label, cta_url, weight, is_example)
where not exists (select 1 from public.ads where is_example);
