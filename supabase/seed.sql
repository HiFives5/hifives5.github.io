-- ════════════════════════════════════════════════════════════════
-- HiFives — contenu de départ
-- À exécuter APRÈS schema.sql (SQL Editor > New query > Run).
-- Peut être relancé sans créer de doublons.
--
-- 1. 40 sujets officiels (5 par catégorie) + ~10 suggestions chacun
-- 2. 16 profils de démo (is_demo = true) qui remplissent ~60 % des sujets
--    → pour vider la démo plus tard : purge_demo.sql
-- ════════════════════════════════════════════════════════════════

-- ── 1. SUJETS + SUGGESTIONS ─────────────────────────────────────
-- Les suggestions sont classées de la plus à la moins populaire.
with data(category, title, sugg) as (values
  -- CINÉMA
  ('Cinéma', 'Top 5 films italiens de tous les temps', array[
    'La vita è bella', 'Le Bon, la Brute et le Truand', 'Cinema Paradiso', 'La dolce vita',
    'Il était une fois dans l''Ouest', 'Le Voleur de bicyclette', '8½', 'La grande bellezza', 'Le Guépard', 'Il Postino']),
  ('Cinéma', 'Top 5 films de Tarantino', array[
    'Pulp Fiction', 'Reservoir Dogs', 'Django Unchained', 'Inglourious Basterds', 'Kill Bill vol. 1',
    'Jackie Brown', 'Once Upon a Time… in Hollywood', 'Kill Bill vol. 2', 'Les Huit Salopards', 'Boulevard de la mort']),
  ('Cinéma', 'Top 5 comédies françaises', array[
    'Le Dîner de cons', 'Les Visiteurs', 'La Cité de la peur', 'OSS 117 : Le Caire, nid d''espions', 'Intouchables',
    'Le Père Noël est une ordure', 'Astérix et Obélix : Mission Cléopâtre', 'La Grande Vadrouille', 'Bienvenue chez les Ch''tis', 'Le Grand Blond avec une chaussure noire']),
  ('Cinéma', 'Top 5 films de science-fiction', array[
    'Interstellar', 'Matrix', 'Blade Runner', 'Retour vers le futur', '2001 : l''Odyssée de l''espace',
    'Alien', 'Star Wars : L''Empire contre-attaque', 'Inception', 'Terminator 2', 'Dune']),
  ('Cinéma', 'Top 5 films d''animation', array[
    'Le Voyage de Chihiro', 'Le Roi lion', 'Toy Story', 'Là-haut', 'Mon voisin Totoro',
    'Ratatouille', 'Wall-E', 'Princesse Mononoké', 'Vice-versa', 'Coco']),

  -- MUSIQUE
  ('Musique', 'Top 5 albums de rap West Coast', array[
    'The Chronic — Dr. Dre', 'Doggystyle — Snoop Dogg', '2001 — Dr. Dre', 'All Eyez on Me — 2Pac',
    'good kid, m.A.A.d city — Kendrick Lamar', 'To Pimp a Butterfly — Kendrick Lamar', 'Straight Outta Compton — N.W.A',
    'Me Against the World — 2Pac', 'The Documentary — The Game', 'Regulate… G Funk Era — Warren G']),
  ('Musique', 'Top 5 albums de rap français', array[
    'L''École du micro d''argent — IAM', 'Dans la légende — PNL', 'Ouest Side — Booba', 'Suprême NTM — NTM',
    'Civilisation — Orelsan', 'Ipséité — Damso', 'Mauvais œil — Lunatic', 'Or Noir — Kaaris', 'Temps mort — Booba', 'Deux frères — PNL']),
  ('Musique', 'Top 5 albums des Beatles', array[
    'Abbey Road', 'The White Album', 'Revolver', 'Sgt. Pepper''s Lonely Hearts Club Band', 'Rubber Soul',
    'Let It Be', 'A Hard Day''s Night', 'Help!', 'Magical Mystery Tour', 'Please Please Me']),
  ('Musique', 'Top 5 chansons françaises de tous les temps', array[
    'Ne me quitte pas — Jacques Brel', 'La Bohème — Charles Aznavour', 'La Vie en rose — Édith Piaf', 'Le Sud — Nino Ferrer',
    'Foule sentimentale — Alain Souchon', 'Comme d''habitude — Claude François', 'Les Champs-Élysées — Joe Dassin',
    'L''Aventurier — Indochine', 'Alors on danse — Stromae', 'Je te promets — Johnny Hallyday']),
  ('Musique', 'Top 5 groupes de rock', array[
    'Queen', 'The Beatles', 'Led Zeppelin', 'Pink Floyd', 'The Rolling Stones',
    'Nirvana', 'AC/DC', 'Radiohead', 'U2', 'Metallica']),

  -- VOYAGES
  ('Voyages', 'Top 5 destinations en Italie', array[
    'Rome', 'Florence', 'Venise', 'Côte amalfitaine', 'Cinque Terre',
    'Sicile', 'Toscane', 'Lac de Côme', 'Naples', 'Sardaigne']),
  ('Voyages', 'Top 5 villes européennes', array[
    'Barcelone', 'Lisbonne', 'Rome', 'Amsterdam', 'Prague',
    'Paris', 'Londres', 'Berlin', 'Vienne', 'Budapest']),
  ('Voyages', 'Top 5 plages du monde', array[
    'Maldives', 'Bora Bora', 'Anse Source d''Argent — Seychelles', 'Navagio — Grèce', 'Palombaggia — Corse',
    'Whitehaven Beach — Australie', 'Tulum — Mexique', 'Zanzibar', 'Copacabana — Brésil', 'Bali']),
  ('Voyages', 'Top 5 destinations pour un week-end en France', array[
    'Annecy', 'Biarritz', 'Marseille', 'Bordeaux', 'Saint-Malo',
    'Étretat', 'Colmar', 'Arcachon', 'Lyon', 'Chamonix']),
  ('Voyages', 'Top 5 pays à visiter une fois dans sa vie', array[
    'Japon', 'Islande', 'Nouvelle-Zélande', 'Pérou', 'Canada',
    'Italie', 'Thaïlande', 'Maroc', 'Norvège', 'Afrique du Sud']),

  -- SPORT
  ('Sport', 'Top 5 clubs de foot préférés', array[
    'PSG', 'Olympique de Marseille', 'Real Madrid', 'FC Barcelone', 'Olympique Lyonnais',
    'Liverpool', 'Manchester United', 'AC Milan', 'Juventus', 'Bayern Munich']),
  ('Sport', 'Top 5 footballeurs de tous les temps', array[
    'Lionel Messi', 'Pelé', 'Diego Maradona', 'Cristiano Ronaldo', 'Zinédine Zidane',
    'Johan Cruyff', 'Ronaldo (R9)', 'Ronaldinho', 'Franz Beckenbauer', 'Kylian Mbappé']),
  ('Sport', 'Top 5 golfeurs de tous les temps', array[
    'Tiger Woods', 'Jack Nicklaus', 'Arnold Palmer', 'Seve Ballesteros', 'Ben Hogan',
    'Rory McIlroy', 'Gary Player', 'Phil Mickelson', 'Scottie Scheffler', 'Ernie Els']),
  ('Sport', 'Top 5 moments sportifs inoubliables', array[
    'France championne du monde 1998', 'Finale Argentine-France 2022', 'Le 9,58 s d''Usain Bolt', 'La main de Dieu de Maradona',
    'France championne du monde 2018', 'Le coup de boule de Zidane 2006', 'La remontada Barça-PSG 2017',
    'Tiger Woods au Masters 2019', 'Les 8 médailles d''or de Phelps à Pékin', 'Le 10/10 de Nadia Comăneci']),
  ('Sport', 'Top 5 sportifs français', array[
    'Zinédine Zidane', 'Teddy Riner', 'Antoine Dupont', 'Kylian Mbappé', 'Tony Parker',
    'Léon Marchand', 'Victor Wembanyama', 'Martin Fourcade', 'Marie-José Pérec', 'Yannick Noah']),

  -- SÉRIES
  ('Séries', 'Top 5 séries de tous les temps', array[
    'Breaking Bad', 'Game of Thrones', 'The Wire', 'Les Soprano', 'Friends',
    'Chernobyl', 'Succession', 'True Detective', 'Mad Men', 'The Office']),
  ('Séries', 'Top 5 séries Netflix', array[
    'La Casa de Papel', 'Stranger Things', 'Squid Game', 'Narcos', 'Peaky Blinders',
    'Dark', 'Black Mirror', 'The Crown', 'Lupin', 'Mindhunter']),
  ('Séries', 'Top 5 séries françaises', array[
    'Le Bureau des légendes', 'Kaamelott', 'Dix pour cent', 'Engrenages', 'Lupin',
    'Baron noir', 'Hippocrate', 'Les Revenants', 'Validé', 'Fais pas ci, fais pas ça']),
  ('Séries', 'Top 5 sitcoms', array[
    'Friends', 'The Office', 'How I Met Your Mother', 'Brooklyn Nine-Nine', 'Seinfeld',
    'Malcolm', 'The Big Bang Theory', 'Scrubs', 'Parks and Recreation', 'Modern Family']),
  ('Séries', 'Top 5 séries d''animation', array[
    'Les Simpson', 'Rick et Morty', 'South Park', 'Arcane', 'BoJack Horseman',
    'Futurama', 'Avatar : le dernier maître de l''air', 'One Piece', 'Dragon Ball Z', 'Family Guy']),

  -- GASTRONOMIE
  ('Gastronomie', 'Top 5 plats français', array[
    'Bœuf bourguignon', 'Raclette', 'Blanquette de veau', 'Tartiflette', 'Cassoulet',
    'Coq au vin', 'Pot-au-feu', 'Choucroute', 'Ratatouille', 'Quiche lorraine']),
  ('Gastronomie', 'Top 5 spécialités lyonnaises', array[
    'Quenelle de brochet', 'Saucisson brioché', 'Tarte aux pralines', 'Cervelle de canut', 'Tablier de sapeur',
    'Salade lyonnaise', 'Rosette de Lyon', 'Bugnes', 'Andouillette', 'Gratin dauphinois']),
  ('Gastronomie', 'Top 5 pizzas', array[
    'Margherita', 'Regina', '4 fromages', 'Calzone', 'Diavola',
    'Napolitaine', 'Burrata', 'Savoyarde', 'Capricciosa', 'Végétarienne']),
  ('Gastronomie', 'Top 5 fromages', array[
    'Comté', 'Roquefort', 'Camembert', 'Reblochon', 'Saint-Nectaire',
    'Beaufort', 'Brie de Meaux', 'Mont d''Or', 'Saint-Marcellin', 'Époisses']),
  ('Gastronomie', 'Top 5 cuisines du monde', array[
    'Italienne', 'Japonaise', 'Française', 'Libanaise', 'Mexicaine',
    'Thaïlandaise', 'Indienne', 'Marocaine', 'Coréenne', 'Grecque']),

  -- LIVRES
  ('Livres', 'Top 5 romans de tous les temps', array[
    '1984 — George Orwell', 'L''Étranger — Albert Camus', 'Le Comte de Monte-Cristo — Alexandre Dumas', 'Les Misérables — Victor Hugo',
    'Cent ans de solitude — Gabriel García Márquez', 'Le Petit Prince — Antoine de Saint-Exupéry', 'Crime et Châtiment — Dostoïevski',
    'Le Seigneur des anneaux — J.R.R. Tolkien', 'Madame Bovary — Gustave Flaubert', 'Harry Potter — J.K. Rowling']),
  ('Livres', 'Top 5 bandes dessinées', array[
    'Astérix', 'Tintin', 'Gaston Lagaffe', 'Lucky Luke', 'Blacksad',
    'Persepolis', 'Largo Winch', 'XIII', 'Thorgal', 'Les Vieux Fourneaux']),
  ('Livres', 'Top 5 mangas', array[
    'One Piece', 'Naruto', 'Dragon Ball', 'L''Attaque des Titans', 'Death Note',
    'Fullmetal Alchemist', 'Berserk', 'Slam Dunk', 'Hunter x Hunter', 'Demon Slayer']),
  ('Livres', 'Top 5 livres de développement personnel', array[
    'Atomic Habits', 'Les 4 accords toltèques', 'Le Pouvoir du moment présent', 'Père riche, père pauvre', 'L''Alchimiste',
    'Comment se faire des amis', 'Les 7 habitudes des gens très efficaces', 'Deep Work', 'Miracle Morning', 'Réfléchissez et devenez riche']),
  ('Livres', 'Top 5 livres de science-fiction', array[
    'Dune', 'Fondation', 'Le Problème à trois corps', 'Fahrenheit 451', 'Le Meilleur des mondes',
    'La Nuit des temps', 'Hypérion', 'La Horde du Contrevent', 'Neuromancien', 'Les Robots']),

  -- JEUX
  ('Jeux', 'Top 5 jeux vidéo de tous les temps', array[
    'The Legend of Zelda : Breath of the Wild', 'The Witcher 3', 'Red Dead Redemption 2', 'GTA V', 'Minecraft',
    'Super Mario 64', 'Elden Ring', 'Final Fantasy VII', 'Tetris', 'Half-Life 2']),
  ('Jeux', 'Top 5 jeux de société', array[
    'Catan', 'Les Aventuriers du Rail', 'Codenames', 'Dixit', 'Skyjo',
    '7 Wonders', 'Carcassonne', 'Azul', 'Unlock!', 'Monopoly']),
  ('Jeux', 'Top 5 jeux Nintendo', array[
    'Mario Kart 8', 'Zelda : Ocarina of Time', 'Super Smash Bros. Ultimate', 'Super Mario Odyssey', 'Pokémon Rouge / Bleu',
    'Animal Crossing', 'Zelda : Tears of the Kingdom', 'Super Mario Bros. 3', 'Donkey Kong Country', 'Metroid Prime']),
  ('Jeux', 'Top 5 jeux de cartes', array[
    'Tarot', 'Belote', 'Président', 'Uno', 'Poker',
    'Rami', 'Bataille', 'Blackjack', 'Solitaire', 'Skyjo']),
  ('Jeux', 'Top 5 jeux de ton enfance', array[
    'Pokémon', 'Tamagotchi', 'Crash Bandicoot', 'Les Sims', 'Super Mario Bros.',
    'Tetris', 'Spyro', 'Age of Empires II', 'Street Fighter II', 'Sonic'])
),
ins as (
  insert into public.topics (title, category, is_official)
  select title, category, true from data
  on conflict do nothing
  returning id, title
)
insert into public.topic_suggestions (topic_id, content, weight)
select i.id, s.content, array_length(d.sugg, 1) - s.ord::int + 1
from ins i
join data d on d.title = i.title
cross join lateral unnest(d.sugg) with ordinality as s(content, ord)
on conflict do nothing;

-- ── 2. PROFILS DE DÉMO ──────────────────────────────────────────
insert into public.profiles (name, handle, country, birth_year, gender, is_demo) values
  ('Camille', '@camille_demo', '🇫🇷 France',      1992, 'Femme', true),
  ('Hugo',    '@hugo_demo',    '🇫🇷 France',      1987, 'Homme', true),
  ('Léa',     '@lea_demo',     '🇫🇷 France',      2001, 'Femme', true),
  ('Thomas',  '@thomas_demo',  '🇫🇷 France',      1979, 'Homme', true),
  ('Inès',    '@ines_demo',    '🇫🇷 France',      1996, 'Femme', true),
  ('Karim',   '@karim_demo',   '🇫🇷 France',      1984, 'Homme', true),
  ('Manon',   '@manon_demo',   '🇫🇷 France',      1999, 'Femme', true),
  ('Julien',  '@julien_demo',  '🇫🇷 France',      1972, 'Homme', true),
  ('Sarah',   '@sarah_demo',   '🇧🇪 Belgique',    1990, 'Femme', true),
  ('Maxime',  '@maxime_demo',  '🇧🇪 Belgique',    2003, 'Homme', true),
  ('Chloé',   '@chloe_demo',   '🇨🇭 Suisse',      1986, 'Femme', true),
  ('Luca',    '@luca_demo',    '🇨🇭 Suisse',      1994, 'Homme', true),
  ('Emma',    '@emma_demo',    '🇬🇧 Royaume-Uni', 1998, 'Femme', true),
  ('Oliver',  '@oliver_demo',  '🇬🇧 Royaume-Uni', 1981, 'Homme', true),
  ('Sofia',   '@sofia_demo',   '🇺🇸 États-Unis',  1993, 'Femme', true),
  ('Alex',    '@alex_demo',    '🇺🇸 États-Unis',  1989, 'Autre', true)
on conflict (handle) do nothing;

-- Chaque profil démo remplit ~60 % des sujets officiels
insert into public.tops (topic_id, user_id, created_at)
select t.id, p.id, now() - random() * interval '30 days'
from public.topics t
cross join public.profiles p
where p.is_demo and t.is_official and random() < 0.6
on conflict do nothing;

-- 5 réponses tirées au hasard, pondérées par popularité
insert into public.top_items (top_id, rank, content)
select x.top_id, x.rk, x.content
from (
  select tp.id as top_id, s.content,
         row_number() over (partition by tp.id order by power(random(), 1.0 / s.weight) desc) as rk
  from public.tops tp
  join public.profiles p on p.id = tp.user_id and p.is_demo
  join public.topic_suggestions s on s.topic_id = tp.topic_id
) x
where x.rk <= 5
on conflict do nothing;

-- Quelques likes entre profils démo
insert into public.likes (top_id, user_id)
select tp.id, p.id
from public.tops tp
cross join public.profiles p
where p.is_demo and p.id <> tp.user_id and random() < 0.08
on conflict do nothing;
