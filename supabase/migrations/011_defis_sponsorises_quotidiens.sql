-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 011 : un défi sponsorisé différent chaque jour
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 010).
-- N'efface rien ; relançable (ne programme que les jours encore libres).
--
-- • 30 thèmes d'exemple « à la Danette » (marqués « Exemple de partenariat »)
-- • programmés un par jour (minuit → minuit, heure de Paris) sur les 365 prochains jours,
--   en tournant sur les 30 thèmes. Relancer la migration dans un an prolonge le calendrier.
-- • Pas d'alcool ni de tabac (publicité encadrée par la loi Évin).
-- Pour remplacer un jour par un vrai partenaire : Table Editor > sponsored_challenges.
-- ════════════════════════════════════════════════════════════════

drop table if exists public.tmp_sponsor_cat;
create table public.tmp_sponsor_cat (
  idx int, brand text, title text, category text, emoji text, color text, tagline text,
  cta_label text, cta_url text, sugg text[]
);
alter table public.tmp_sponsor_cat enable row level security;

insert into public.tmp_sponsor_cat values
 (0,  'Danette', 'Top 5 saveurs de Danette', 'Gastronomie', '🍮', '#5B2C14', 'On se lève tous pour… laquelle ? Classe tes 5 saveurs préférées !', 'Découvrir les saveurs', 'https://www.danette.fr',
      array['Chocolat','Vanille','Caramel','Chocolat noir','Praliné','Chocolat au lait','Café','Pistache']),
 (1,  'Haribo', 'Top 5 bonbons Haribo', 'Nostalgie', '🍬', '#C8102E', 'Haribo, c''est beau la vie… mais lequel est le meilleur ?', 'Voir les bonbons', 'https://www.haribo.com',
      array['Fraises Tagada','Dragibus','Crocodiles','Schtroumpfs','Ours d''Or','Happy Cola','Rotella','Chamallows','Car en Sac','Polka']),
 (2,  'LEGO', 'Top 5 univers LEGO', 'Jeux', '🧱', '#D01012', 'Brique après brique : quels univers LEGO t''ont fait rêver ?', 'Découvrir les sets', 'https://www.lego.com',
      array['Star Wars','Technic','City','Harry Potter','Ninjago','Creator','Marvel Super Heroes','Friends','Ideas','Architecture']),
 (3,  'Ben & Jerry''s', 'Top 5 parfums Ben & Jerry''s', 'Gastronomie', '🍦', '#3B5BA5', 'Un pot, une cuillère, zéro partage : ton classement ?', 'Voir les parfums', 'https://www.benjerry.fr',
      array['Cookie Dough','Chocolate Fudge Brownie','Caramel Chew Chew','Phish Food','Peanut Butter Cup','Strawberry Cheesecake','Half Baked','Chunky Monkey']),
 (4,  'Netflix', 'Top 5 séries originales Netflix', 'Séries', '🍿', '#B20710', 'Juste un dernier épisode… lesquelles t''ont tenu éveillé ?', 'Voir le catalogue', 'https://www.netflix.com',
      array['Stranger Things','La Casa de Papel','Squid Game','The Crown','Lupin','Dark','Mercredi','La Chronique des Bridgerton','Ozark','Narcos']),
 (5,  'IKEA', 'Top 5 produits IKEA', 'Lifestyle', '🪑', '#0058A3', 'Montés sans notice (ou presque) : tes indispensables IKEA ?', 'Voir les produits', 'https://www.ikea.com/fr',
      array['Bibliothèque Billy','Étagère Kallax','Fauteuil Poäng','Commode Malm','Table Lack','Sac Frakta','Boulettes de viande','Lit Hemnes','Canapé Klippan','Requin Blåhaj']),
 (6,  'Nintendo', 'Top 5 personnages Nintendo', 'Jeux', '🍄', '#E60012', 'Mario, Link, Pikachu… qui mérite la première marche ?', 'Découvrir Nintendo', 'https://www.nintendo.fr',
      array['Mario','Link','Pikachu','Kirby','Donkey Kong','Yoshi','Luigi','Samus','Bowser','Princesse Zelda']),
 (7,  'Kinder', 'Top 5 produits Kinder', 'Nostalgie', '🥚', '#E2001A', 'Goûter d''enfance ou plaisir coupable : ton top Kinder ?', 'Voir les produits', 'https://www.kinder.com/fr',
      array['Kinder Bueno','Kinder Surprise','Kinder Country','Kinder Délice','Kinder Maxi','Kinder Schoko-Bons','Kinder Pingui','Kinder Joy','Kinder Happy Hippo','Kinder Cards']),
 (8,  'Decathlon', 'Top 5 sports à pratiquer le week-end', 'Sport', '🏃', '#0082C3', 'Baskets aux pieds : quels sports te font bouger ?', 'Trouver son sport', 'https://www.decathlon.fr',
      array['Randonnée','Running','Vélo','Natation','Tennis','Padel','Yoga','Escalade','Football','Ski']),
 (9,  'Spotify', 'Top 5 genres musicaux', 'Musique', '🎧', '#1DB954', 'Ta playlist parle pour toi : quels genres tournent en boucle ?', 'Écouter', 'https://open.spotify.com',
      array['Pop','Rap','Rock','Électro','R&B','Variété française','Jazz','Reggae','Classique','Metal']),
 (10, 'Pokémon', 'Top 5 Pokémon', 'Jeux', '⚡', '#FFCB05', 'Attrapez-les tous… mais lesquels gardes-tu dans ton équipe ?', 'Découvrir Pokémon', 'https://www.pokemon.com/fr',
      array['Pikachu','Dracaufeu','Évoli','Mewtwo','Bulbizarre','Salamèche','Ronflex','Ectoplasma','Lucario','Mew']),
 (11, 'Disney', 'Top 5 grands classiques Disney', 'Cinéma', '🏰', '#113CCF', 'Hakuna Matata : quels classiques Disney ont bercé ton enfance ?', 'Voir les films', 'https://www.disney.fr',
      array['Le Roi lion','La Belle et la Bête','Aladdin','La Petite Sirène','La Reine des neiges','Mulan','Le Livre de la jungle','Raiponce','Blanche-Neige et les Sept Nains','Vaiana']),
 (12, 'Nespresso', 'Top 5 façons de boire ton café', 'Boissons', '☕', '#3A2A1E', 'What else ? Dis-nous comment tu prends ton café.', 'Découvrir', 'https://www.nespresso.com/fr',
      array['Espresso','Cappuccino','Latte macchiato','Café allongé','Ristretto','Café glacé','Noisette','Flat white']),
 (13, 'Air France', 'Top 5 destinations long-courrier', 'Voyages', '✈️', '#002157', 'Ceinture attachée : où t''envolerais-tu demain ?', 'Voir les destinations', 'https://www.airfrance.fr',
      array['New York','Tokyo','Montréal','Bangkok','Rio de Janeiro','Los Angeles','La Réunion','Le Cap','Singapour','Guadeloupe']),
 (14, 'Bonne Maman', 'Top 5 confitures', 'Gastronomie', '🍓', '#B5121B', 'Sur la tartine du dimanche : quelles confitures en tête ?', 'Voir les confitures', 'https://www.bonnemaman.fr',
      array['Fraise','Abricot','Framboise','Cerise noire','Figue','Myrtille','Orange amère','Mirabelle','Rhubarbe','Quatre fruits']),
 (15, 'LU', 'Top 5 biscuits LU', 'Nostalgie', '🍪', '#E2231A', 'Retour à la récré : quels biscuits LU sont les meilleurs ?', 'Voir les biscuits', 'https://www.lu.fr',
      array['Prince','Petit Écolier','Pim''s','Petit Beurre','Paille d''Or','Mikado','Granola','Pépito','TUC','Barquette']),
 (16, 'Oasis', 'Top 5 parfums de jus de fruits', 'Boissons', '🍊', '#F39200', 'Be fruit : quels parfums te désaltèrent le mieux ?', 'Voir les parfums', 'https://www.oasis.fr',
      array['Tropical','Orange','Pomme','Pêche','Fraise','Mangue','Ananas','Multifruit']),
 (17, 'Uber Eats', 'Top 5 cuisines à se faire livrer', 'Gastronomie', '🛵', '#06C167', 'Soir de flemme : qu''est-ce que tu commandes ?', 'Commander', 'https://www.ubereats.com/fr',
      array['Pizza','Burger','Sushi','Indien','Thaï','Libanais','Poke bowl','Tacos','Chinois','Italien']),
 (18, 'PlayStation', 'Top 5 licences PlayStation', 'Jeux', '🎮', '#003791', 'Manette en main : quelles sagas PlayStation sont cultes ?', 'Découvrir', 'https://www.playstation.com/fr-fr',
      array['God of War','The Last of Us','Uncharted','Gran Turismo','Marvel''s Spider-Man','Horizon','Ghost of Tsushima','Ratchet & Clank','Crash Bandicoot','Final Fantasy']),
 (19, 'Fnac', 'Top 5 genres de livres', 'Livres', '📚', '#E1A925', 'Ta pile à lire en dit long : quels genres dévores-tu ?', 'Trouver un livre', 'https://www.fnac.com',
      array['Polar','Roman','BD','Science-fiction','Fantasy','Manga','Biographie','Développement personnel','Histoire','Poésie']),
 (20, 'Renault', 'Top 5 Renault de légende', 'Auto & moto', '🚗', '#EFDF00', 'De la 4L à la R5 : quelles Renault ont marqué la route ?', 'Découvrir', 'https://www.renault.fr',
      array['Renault 5','4L','Clio','Twingo','Alpine A110','Espace','Mégane','Scénic','Captur','Kangoo']),
 (21, 'Panini', 'Top 5 Coupes du monde de football', 'Sport', '⚽', '#FFD100', 'Album complété ? Quelles Coupes du monde t''ont fait vibrer ?', 'Voir les albums', 'https://www.panini.fr',
      array['1998 en France','2018 en Russie','2022 au Qatar','2006 en Allemagne','1986 au Mexique','2014 au Brésil','1970 au Mexique','2010 en Afrique du Sud','1982 en Espagne','2002 en Corée et au Japon']),
 (22, 'Marvel', 'Top 5 super-héros Marvel', 'Cinéma', '🦸', '#EC1D24', 'Avengers, rassemblement ! Qui est ton héros n°1 ?', 'Découvrir', 'https://www.marvel.com',
      array['Iron Man','Spider-Man','Captain America','Thor','Black Panther','Hulk','Wolverine','Black Widow','Doctor Strange','Deadpool']),
 (23, 'Hasbro', 'Top 5 jeux de société classiques', 'Jeux', '🎲', '#0D4FA8', 'Soirée jeux : lequel sort de l''armoire en premier ?', 'Voir les jeux', 'https://shop.hasbro.com',
      array['Monopoly','Trivial Pursuit','Cluedo','Puissance 4','Scrabble','Risk','Jenga','Pictionary','Twister','Docteur Maboul']),
 (24, 'Picard', 'Top 5 desserts glacés', 'Gastronomie', '🍨', '#00A0DF', 'Le congélo du dimanche soir : quel dessert glacé gagne ?', 'Voir les desserts', 'https://www.picard.fr',
      array['Bûche glacée','Vacherin','Profiteroles','Sorbet citron','Nougat glacé','Omelette norvégienne','Mochis glacés','Cônes vanille']),
 (25, 'SNCF', 'Top 5 villes où aller en train', 'Voyages', '🚄', '#A1006B', 'Billet en poche : quelle ville rejoindre le week-end prochain ?', 'Voir les trains', 'https://www.sncf-connect.com',
      array['Marseille','Bordeaux','Lyon','Strasbourg','Nantes','Lille','Montpellier','Nice','Rennes','La Rochelle']),
 (26, 'Lacoste', 'Top 5 sports de raquette', 'Sport', '🎾', '#00563F', 'Jeu, set et match : quel sport de raquette préfères-tu ?', 'Découvrir', 'https://www.lacoste.com',
      array['Tennis','Padel','Badminton','Ping-pong','Squash','Pickleball']),
 (27, 'Duolingo', 'Top 5 langues à apprendre', 'Lifestyle', '🦉', '#58CC02', 'Ta série Duolingo te regarde : quelles langues rêves-tu de parler ?', 'Commencer', 'https://www.duolingo.com',
      array['Anglais','Espagnol','Italien','Japonais','Allemand','Portugais','Coréen','Chinois','Arabe','Russe']),
 (28, 'Pathé', 'Top 5 snacks au cinéma', 'Spectacles & sorties', '🎬', '#FFB400', 'Lumière éteinte, film lancé : qu''est-ce qu''il y a sur tes genoux ?', 'Voir les séances', 'https://www.pathe.fr',
      array['Pop-corn sucré','Pop-corn salé','Nachos','M&M''s','Glace','Soda','Bonbons','Chips']),
 (29, 'Michelin', 'Top 5 régions gastronomiques de France', 'Gastronomie', '⭐', '#27509B', 'Guide en main : quelle région régale le mieux ?', 'Explorer le guide', 'https://guide.michelin.com/fr',
      array['Lyon et le Beaujolais','Provence','Bourgogne','Alsace','Pays basque','Périgord','Bretagne','Normandie','Savoie','Bordelais']);

-- 1. Sujets (officiels) + suggestions
insert into public.topics (title, category, is_official)
select title, category, true from public.tmp_sponsor_cat
on conflict do nothing;

insert into public.topic_suggestions (topic_id, content, weight)
select tp.id, s.content, array_length(c.sugg, 1) - s.ord::int + 1
from public.tmp_sponsor_cat c
join public.topics tp on lower(tp.title) = lower(c.title)
cross join lateral unnest(c.sugg) with ordinality as s(content, ord)
on conflict do nothing;

-- 2. L'exemple Danette de 30 jours (migration 010) est retiré : Danette revient dans la rotation quotidienne.
--    Le sujet, les réponses déjà données et les points gagnés sont conservés.
delete from public.sponsored_challenges
where brand = 'Danette' and is_example and ends_at - starts_at > interval '2 days';

-- 3. Un défi par jour (heure de Paris) sur 365 jours, en tournant sur les 30 thèmes.
--    Le thème d'un jour dépend de sa date : relancer la migration redonne le même calendrier.
insert into public.sponsored_challenges (topic_id, brand, tagline, emoji, color, bonus_points, cta_label, cta_url, starts_at, ends_at, is_example)
select tp.id, c.brand, c.tagline, c.emoji, c.color, 100, c.cta_label, c.cta_url,
       d::timestamp at time zone 'Europe/Paris',
       (d + 1)::timestamp at time zone 'Europe/Paris',
       true
from generate_series((now() at time zone 'Europe/Paris')::date, (now() at time zone 'Europe/Paris')::date + 364, interval '1 day') as g(d0)
cross join lateral (select g.d0::date as d) dd
join public.tmp_sponsor_cat c on c.idx = ((dd.d - date '2026-01-01') % 30)
join public.topics tp on lower(tp.title) = lower(c.title)
where not exists (
  select 1 from public.sponsored_challenges x
  where x.starts_at < (dd.d + 1)::timestamp at time zone 'Europe/Paris'
    and x.ends_at   > dd.d::timestamp at time zone 'Europe/Paris'
);

-- 4. Les profils de démo (s'il en reste) remplissent ~60 % des nouveaux sujets
insert into public.tops (topic_id, user_id, created_at)
select t.id, p.id, now() - random() * interval '3 days'
from public.topics t cross join public.profiles p
where p.is_demo and t.is_official and random() < 0.6
  and not exists (select 1 from public.tops x join public.profiles px on px.id = x.user_id where x.topic_id = t.id and px.is_demo)
on conflict do nothing;

insert into public.top_items (top_id, rank, content)
select x.top_id, x.rk, x.content
from (
  select tp.id as top_id, s.content,
         row_number() over (partition by tp.id order by power(random(), 1.0 / s.weight) desc) as rk
  from public.tops tp
  join public.profiles p on p.id = tp.user_id and p.is_demo
  join public.topic_suggestions s on s.topic_id = tp.topic_id
  where not exists (select 1 from public.top_items i where i.top_id = tp.id)
) x
where x.rk <= 5
on conflict do nothing;

drop table if exists public.tmp_sponsor_cat;
