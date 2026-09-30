-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 006 : listes de référence « football »
-- (suite au retour utilisateur « base de données pour les thèmes sport »)
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable sans doublon.
--
-- Enrichit le pool de suggestions (autocomplétion) des sujets football :
-- en tapant, on te propose l'orthographe officielle. La saisie libre reste possible.
-- ════════════════════════════════════════════════════════════════

-- Nouveaux sujets football officiels
insert into public.topics (title, category, is_official)
values
  ('Top 5 équipes nationales de football', 'Sport', true),
  ('Top 5 stades de football', 'Sport', true),
  ('Top 5 gardiens de but de tous les temps', 'Sport', true)
on conflict do nothing;

with data(title, sugg) as (values
  ('Top 5 clubs de foot préférés', array[
    'Paris Saint-Germain', 'Olympique de Marseille', 'Olympique Lyonnais', 'AS Monaco', 'LOSC Lille', 'OGC Nice',
    'Stade Rennais', 'RC Lens', 'FC Nantes', 'AS Saint-Étienne', 'Girondins de Bordeaux', 'Stade de Reims',
    'Real Madrid', 'FC Barcelone', 'Atlético de Madrid', 'FC Séville', 'Valence CF', 'Villarreal CF', 'Athletic Bilbao',
    'Manchester City', 'Manchester United', 'Liverpool', 'Arsenal', 'Chelsea', 'Tottenham Hotspur', 'Newcastle United',
    'Bayern Munich', 'Borussia Dortmund', 'Bayer Leverkusen', 'RB Leipzig',
    'Juventus', 'AC Milan', 'Inter Milan', 'AS Rome', 'SSC Naples', 'Lazio Rome', 'Atalanta Bergame',
    'Ajax Amsterdam', 'PSV Eindhoven', 'FC Porto', 'Benfica', 'Sporting Portugal', 'Celtic Glasgow', 'Galatasaray',
    'Boca Juniors', 'River Plate', 'Flamengo', 'Inter Miami']),
  ('Top 5 footballeurs de tous les temps', array[
    'Lionel Messi', 'Pelé', 'Diego Maradona', 'Cristiano Ronaldo', 'Zinédine Zidane', 'Johan Cruyff', 'Ronaldo (R9)',
    'Ronaldinho', 'Franz Beckenbauer', 'Kylian Mbappé', 'Michel Platini', 'Thierry Henry', 'Karim Benzema',
    'Ferenc Puskás', 'Alfredo Di Stéfano', 'George Best', 'Michael Laudrup', 'Marco van Basten', 'Ruud Gullit',
    'Paolo Maldini', 'Roberto Baggio', 'Andrea Pirlo', 'Xavi Hernández', 'Andrés Iniesta', 'Luka Modrić',
    'Zlatan Ibrahimović', 'Eric Cantona', 'Roberto Carlos', 'Kaká', 'Neymar', 'Erling Haaland', 'Kevin De Bruyne',
    'Robert Lewandowski', 'Gerd Müller', 'Garrincha', 'Eusébio', 'Bobby Charlton', 'Lev Yachine', 'Didier Drogba',
    'George Weah', 'Raymond Kopa', 'Just Fontaine', 'Jean-Pierre Papin', 'Antoine Griezmann', 'N''Golo Kanté',
    'Lothar Matthäus', 'Gianluigi Buffon', 'Iker Casillas', 'Sergio Ramos', 'Jude Bellingham']),
  ('Top 5 équipes nationales de football', array[
    'France', 'Brésil', 'Argentine', 'Allemagne', 'Italie', 'Espagne', 'Angleterre', 'Portugal', 'Pays-Bas',
    'Belgique', 'Croatie', 'Uruguay', 'Maroc', 'Sénégal', 'Japon', 'États-Unis', 'Mexique', 'Suisse', 'Danemark',
    'Cameroun', 'Nigeria', 'Côte d''Ivoire', 'Algérie', 'Colombie', 'Pologne', 'Suède', 'Hongrie', 'Tchécoslovaquie']),
  ('Top 5 stades de football', array[
    'Camp Nou', 'Santiago-Bernabéu', 'Old Trafford', 'Anfield', 'Wembley', 'San Siro', 'Allianz Arena',
    'Signal Iduna Park', 'Parc des Princes', 'Stade Vélodrome', 'Groupama Stadium', 'Stade de France',
    'Stade Bollaert-Delelis', 'Stade Geoffroy-Guichard', 'La Bombonera', 'Maracanã', 'Stade Azteca',
    'Emirates Stadium', 'Etihad Stadium', 'Stamford Bridge', 'Stadio Olimpico', 'Johan Cruyff Arena',
    'Estádio da Luz', 'Stade Louis-II', 'Metropolitano']),
  ('Top 5 gardiens de but de tous les temps', array[
    'Lev Yachine', 'Gianluigi Buffon', 'Manuel Neuer', 'Iker Casillas', 'Gordon Banks', 'Peter Schmeichel',
    'Oliver Kahn', 'Dino Zoff', 'Fabien Barthez', 'Hugo Lloris', 'Thibaut Courtois', 'Alisson Becker',
    'Emiliano Martínez', 'Petr Čech', 'Edwin van der Sar', 'Sepp Maier', 'Jean-Marie Pfaff', 'Gianluigi Donnarumma',
    'Yassine Bounou', 'Ederson'])
)
insert into public.topic_suggestions (topic_id, content, weight)
select t.id, s.content, greatest(1, 3 - (s.ord::int - 1) / 10)
from data d
join public.topics t on lower(t.title) = lower(d.title)
cross join lateral unnest(d.sugg) with ordinality as s(content, ord)
on conflict do nothing;
