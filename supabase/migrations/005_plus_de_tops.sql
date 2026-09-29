-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 005 : 23 nouveaux sujets officiels
-- (suite au retour utilisateur « plus de tops »)
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable sans doublon. Nécessite la migration 004.
-- ════════════════════════════════════════════════════════════════

with data(category, title, sugg) as (values
  ('Voyages', 'Top 5 capitales du monde', array[
    'Rome', 'Paris', 'Londres', 'Tokyo', 'Lisbonne', 'Amsterdam', 'Prague', 'Berlin', 'Vienne', 'Buenos Aires']),
  ('Voyages', 'Top 5 villes de France', array[
    'Lyon', 'Paris', 'Bordeaux', 'Marseille', 'Annecy', 'Nantes', 'Toulouse', 'Montpellier', 'Strasbourg', 'Nice']),
  ('Sport', 'Top 5 clubs de rugby', array[
    'Stade Toulousain', 'Stade Rochelais', 'RC Toulon', 'ASM Clermont Auvergne', 'Racing 92',
    'Stade Français', 'Union Bordeaux-Bègles', 'Castres Olympique', 'LOU Rugby', 'Montpellier Hérault Rugby']),
  ('Sport', 'Top 5 cyclistes de tous les temps', array[
    'Eddy Merckx', 'Bernard Hinault', 'Tadej Pogačar', 'Jacques Anquetil', 'Miguel Indurain',
    'Fausto Coppi', 'Jonas Vingegaard', 'Chris Froome', 'Laurent Fignon', 'Julian Alaphilippe']),
  ('Sport', 'Top 5 sports à regarder', array[
    'Football', 'Rugby', 'Tennis', 'Formule 1', 'Cyclisme', 'Basket', 'Golf', 'Handball', 'Athlétisme', 'Ski alpin']),
  ('Musique', 'Top 5 albums de tous les temps', array[
    'Thriller — Michael Jackson', 'The Dark Side of the Moon — Pink Floyd', 'Abbey Road — The Beatles', 'Nevermind — Nirvana',
    'Rumours — Fleetwood Mac', 'OK Computer — Radiohead', 'Back in Black — AC/DC', 'Random Access Memories — Daft Punk',
    'Kind of Blue — Miles Davis', 'Purple Rain — Prince']),
  ('Musique', 'Top 5 artistes électro', array[
    'Daft Punk', 'Justice', 'The Chemical Brothers', 'Jean-Michel Jarre', 'Air',
    'Avicii', 'David Guetta', 'Kavinsky', 'Martin Garrix', 'Deadmau5']),
  ('Musique', 'Top 5 chanteuses internationales', array[
    'Beyoncé', 'Adele', 'Amy Winehouse', 'Rihanna', 'Whitney Houston',
    'Madonna', 'Taylor Swift', 'Lady Gaga', 'Billie Eilish', 'Céline Dion']),
  ('Livres', 'Top 5 romans policiers', array[
    'Le Crime de l''Orient-Express', 'Millénium', 'Le Silence des agneaux', 'Ils étaient dix', 'Le Nom de la rose',
    'Les Rivières pourpres', 'Le Chien des Baskerville', 'Shutter Island', 'Gone Girl', 'La Vérité sur l''affaire Harry Quebert']),
  ('Livres', 'Top 5 sagas fantasy', array[
    'Le Seigneur des anneaux', 'Harry Potter', 'Le Trône de fer', 'Le Sorceleur', 'L''Assassin royal',
    'Les Chroniques de Narnia', 'La Roue du temps', 'La Passe-miroir', 'Les Annales du Disque-monde', 'Eragon']),
  ('Jeux', 'Top 5 jeux vidéo multijoueur', array[
    'Mario Kart', 'Fortnite', 'EA Sports FC', 'Call of Duty', 'League of Legends',
    'Rocket League', 'Minecraft', 'Counter-Strike', 'Among Us', 'Overwatch']),
  ('Gastronomie', 'Top 5 plats italiens', array[
    'Pizza margherita', 'Lasagnes', 'Pâtes à la carbonara', 'Risotto', 'Burrata',
    'Osso buco', 'Gnocchi', 'Pâtes au pesto', 'Vitello tonnato', 'Arancini']),
  ('Gastronomie', 'Top 5 fruits', array[
    'Mangue', 'Fraise', 'Cerise', 'Pêche', 'Framboise', 'Pastèque', 'Ananas', 'Abricot', 'Banane', 'Kiwi']),
  ('Boissons', 'Top 5 whiskys', array[
    'Lagavulin 16', 'Talisker 10', 'Nikka From the Barrel', 'Glenfiddich 12', 'Laphroaig 10',
    'Macallan 12', 'Yamazaki 12', 'Aberlour A''bunadh', 'Jameson', 'Jack Daniel''s']),
  ('Boissons', 'Top 5 boissons chaudes', array[
    'Espresso', 'Cappuccino', 'Chocolat chaud', 'Café crème', 'Thé vert',
    'Latte', 'Chaï latte', 'Matcha latte', 'Flat white', 'Thé noir']),
  ('Nature & animaux', 'Top 5 animaux marins', array[
    'Dauphin', 'Orque', 'Baleine à bosse', 'Tortue de mer', 'Pieuvre',
    'Requin-baleine', 'Raie manta', 'Loutre de mer', 'Hippocampe', 'Phoque']),
  ('Histoire & culture', 'Top 5 découvertes scientifiques', array[
    'La pénicilline', 'La théorie de la relativité', 'L''ADN', 'La gravitation', 'L''évolution des espèces',
    'La vaccination', 'La radioactivité', 'L''électricité', 'La mécanique quantique', 'Le Big Bang']),
  ('Histoire & culture', 'Top 5 châteaux de France', array[
    'Château de Versailles', 'Château de Chambord', 'Château de Chenonceau', 'Château de Fontainebleau', 'Vaux-le-Vicomte',
    'Château de Chantilly', 'Château d''Amboise', 'Château d''Azay-le-Rideau', 'Cité de Carcassonne', 'Château de Cheverny']),
  ('Tech & web', 'Top 5 téléphones de légende', array[
    'iPhone (2007)', 'Nokia 3310', 'BlackBerry Bold', 'Motorola Razr V3', 'iPhone 4',
    'Samsung Galaxy S', 'Nokia N95', 'Google Pixel', 'Sony Ericsson T68i', 'HTC Dream']),
  ('Personnalités', 'Top 5 sportives françaises', array[
    'Marie-José Pérec', 'Laure Manaudou', 'Amélie Mauresmo', 'Clarisse Agbegnenou', 'Jeannie Longo',
    'Marion Bartoli', 'Pauline Ferrand-Prévot', 'Marie Bochet', 'Estelle Mossely', 'Mélina Robert-Michon']),
  ('Débats & insolite', 'Top 5 excuses pour arriver en retard', array[
    'Les bouchons', 'Le réveil n''a pas sonné', 'Le métro en panne', 'Pas trouvé de place', 'Les enfants',
    'Le GPS s''est trompé', 'J''ai oublié mes clés', 'Un appel urgent', 'La pluie', 'Je croyais que c''était demain']),
  ('Lifestyle', 'Top 5 destinations de vacances en famille', array[
    'Bretagne', 'Côte d''Azur', 'Disneyland Paris', 'Espagne', 'Italie',
    'Alpes', 'Corse', 'Grèce', 'Portugal', 'Center Parcs']),
  ('Cinéma', 'Top 5 films des années 90', array[
    'Pulp Fiction', 'Forrest Gump', 'Le Silence des agneaux', 'Matrix', 'Les Évadés',
    'La Haine', 'Fight Club', 'Jurassic Park', 'Titanic', 'Le Roi lion']),
  ('Nostalgie', 'Top 5 séries TV des années 90', array[
    'Friends', 'Le Prince de Bel-Air', 'X-Files', 'Urgences', 'Sauvés par le gong',
    'Buffy contre les vampires', 'Beverly Hills 90210', 'Hélène et les Garçons', 'Twin Peaks', 'Les Simpson'])
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

-- Réponses = films / séries (recherche TMDB)
update public.topics set entity_type = 'movie' where entity_type is null and title = 'Top 5 films des années 90';
update public.topics set entity_type = 'tv'    where entity_type is null and title = 'Top 5 séries TV des années 90';

-- Les profils de démo (s'il en reste) remplissent ~60 % des sujets officiels encore vides pour eux
insert into public.tops (topic_id, user_id, created_at)
select t.id, p.id, now() - random() * interval '30 days'
from public.topics t
cross join public.profiles p
where p.is_demo and t.is_official and random() < 0.6
  and not exists (
    select 1 from public.tops x join public.profiles px on px.id = x.user_id
    where x.topic_id = t.id and px.is_demo)
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
