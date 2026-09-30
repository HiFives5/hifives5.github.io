-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 007 : listes de référence pour 10 sports
-- (football, tennis, basket, rugby, cyclisme, golf, Formule 1, handball, natation, athlétisme)
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien ; relançable sans doublon. Complète la migration 006.
-- ════════════════════════════════════════════════════════════════

insert into public.topics (title, category, is_official)
values
  ('Top 5 joueurs de rugby de tous les temps', 'Sport', true),
  ('Top 5 joueuses de tennis', 'Sport', true),
  ('Top 5 pilotes de Formule 1', 'Sport', true),
  ('Top 5 équipes de NBA', 'Sport', true),
  ('Top 5 handballeurs de tous les temps', 'Sport', true),
  ('Top 5 nageurs de tous les temps', 'Sport', true),
  ('Top 5 athlètes de tous les temps', 'Sport', true)
on conflict do nothing;

with data(title, sugg) as (values
  ('Top 5 joueurs de tennis', array[
    'Roger Federer', 'Rafael Nadal', 'Novak Djokovic', 'Pete Sampras', 'Björn Borg', 'Andre Agassi', 'John McEnroe',
    'Jimmy Connors', 'Ivan Lendl', 'Andy Murray', 'Carlos Alcaraz', 'Jannik Sinner', 'Yannick Noah', 'Gustavo Kuerten',
    'Stefan Edberg', 'Boris Becker', 'Rod Laver', 'Stanislas Wawrinka', 'Gaël Monfils', 'Jo-Wilfried Tsonga']),
  ('Top 5 joueuses de tennis', array[
    'Serena Williams', 'Steffi Graf', 'Martina Navrátilová', 'Chris Evert', 'Venus Williams', 'Justine Henin',
    'Monica Seles', 'Margaret Court', 'Iga Świątek', 'Naomi Osaka', 'Amélie Mauresmo', 'Marion Bartoli',
    'Kim Clijsters', 'Maria Sharapova', 'Martina Hingis', 'Simona Halep', 'Ashleigh Barty', 'Aryna Sabalenka',
    'Coco Gauff', 'Mary Pierce']),
  ('Top 5 basketteurs NBA', array[
    'Michael Jordan', 'LeBron James', 'Kobe Bryant', 'Magic Johnson', 'Larry Bird', 'Kareem Abdul-Jabbar',
    'Shaquille O''Neal', 'Stephen Curry', 'Tim Duncan', 'Kevin Durant', 'Wilt Chamberlain', 'Bill Russell',
    'Hakeem Olajuwon', 'Dirk Nowitzki', 'Tony Parker', 'Victor Wembanyama', 'Nikola Jokić', 'Giannis Antetokounmpo',
    'Allen Iverson', 'Dwyane Wade']),
  ('Top 5 équipes de NBA', array[
    'Los Angeles Lakers', 'Boston Celtics', 'Chicago Bulls', 'Golden State Warriors', 'San Antonio Spurs',
    'Miami Heat', 'New York Knicks', 'Dallas Mavericks', 'Houston Rockets', 'Philadelphia 76ers',
    'Detroit Pistons', 'Milwaukee Bucks', 'Denver Nuggets', 'Phoenix Suns', 'Brooklyn Nets',
    'Toronto Raptors', 'Oklahoma City Thunder', 'Cleveland Cavaliers', 'Utah Jazz', 'Portland Trail Blazers']),
  ('Top 5 clubs de rugby', array[
    'Stade Toulousain', 'Stade Rochelais', 'RC Toulon', 'ASM Clermont Auvergne', 'Racing 92', 'Stade Français',
    'Union Bordeaux-Bègles', 'Castres Olympique', 'LOU Rugby', 'Montpellier Hérault Rugby', 'Section Paloise',
    'USA Perpignan', 'Aviron Bayonnais', 'CA Brive', 'Leinster', 'Munster', 'Leicester Tigers', 'Saracens',
    'Crusaders', 'Blues']),
  ('Top 5 joueurs de rugby de tous les temps', array[
    'Jonah Lomu', 'Dan Carter', 'Antoine Dupont', 'Richie McCaw', 'Jonny Wilkinson', 'Serge Blanco',
    'Philippe Sella', 'Fabien Galthié', 'Thierry Dusautoir', 'Brian O''Driscoll', 'Gareth Edwards', 'Jean-Pierre Rives',
    'Sébastien Chabal', 'Fabien Pelous', 'Romain Ntamack', 'Gavin Hastings', 'Martin Johnson', 'Michael Jones',
    'Shane Williams', 'Frédéric Michalak']),
  ('Top 5 cyclistes de tous les temps', array[
    'Eddy Merckx', 'Bernard Hinault', 'Tadej Pogačar', 'Jacques Anquetil', 'Miguel Indurain', 'Fausto Coppi',
    'Jonas Vingegaard', 'Chris Froome', 'Laurent Fignon', 'Julian Alaphilippe', 'Lance Armstrong', 'Greg LeMond',
    'Raymond Poulidor', 'Marco Pantani', 'Peter Sagan', 'Mark Cavendish', 'Thibaut Pinot', 'Romain Bardet',
    'Remco Evenepoel', 'Wout van Aert']),
  ('Top 5 golfeurs de tous les temps', array[
    'Tiger Woods', 'Jack Nicklaus', 'Arnold Palmer', 'Seve Ballesteros', 'Ben Hogan', 'Rory McIlroy', 'Gary Player',
    'Phil Mickelson', 'Scottie Scheffler', 'Ernie Els', 'Jon Rahm', 'Nick Faldo', 'Greg Norman', 'Bobby Jones',
    'Sam Snead', 'Tom Watson', 'Bernhard Langer', 'Jordan Spieth', 'Brooks Koepka', 'Victor Dubuisson']),
  ('Top 5 pilotes de Formule 1', array[
    'Michael Schumacher', 'Lewis Hamilton', 'Ayrton Senna', 'Alain Prost', 'Juan Manuel Fangio', 'Sebastian Vettel',
    'Max Verstappen', 'Niki Lauda', 'Jim Clark', 'Jackie Stewart', 'Fernando Alonso', 'Nigel Mansell',
    'Nelson Piquet', 'Jack Brabham', 'Kimi Räikkönen', 'Mika Häkkinen', 'Nico Rosberg', 'Charles Leclerc',
    'Jenson Button', 'Lando Norris']),
  ('Top 5 handballeurs de tous les temps', array[
    'Nikola Karabatić', 'Mikkel Hansen', 'Luc Abalo', 'Thierry Omeyer', 'Daniel Narcisse', 'Jackson Richardson',
    'Bertrand Gille', 'Cédric Burdet', 'Didier Dinart', 'Guillaume Gille', 'Ólafur Stefánsson', 'Talant Dujshebaev',
    'Stefan Kretzschmar', 'Nedim Remili', 'Dika Mem', 'Sander Sagosen', 'Andy Schmid', 'Iker Romero',
    'Yoon Kyung-shin', 'Henning Fritz']),
  ('Top 5 nageurs de tous les temps', array[
    'Michael Phelps', 'Mark Spitz', 'Ian Thorpe', 'Katie Ledecky', 'Léon Marchand', 'Florent Manaudou',
    'Laure Manaudou', 'Alain Bernard', 'Ryan Lochte', 'Caeleb Dressel', 'Alexandre Popov', 'Grant Hackett',
    'Missy Franklin', 'Sarah Sjöström', 'Summer McIntosh', 'Kristóf Milák', 'Yannick Agnel', 'Camille Muffat',
    'Pieter van den Hoogenband', 'Tom Dean']),
  ('Top 5 athlètes de tous les temps', array[
    'Usain Bolt', 'Carl Lewis', 'Jesse Owens', 'Michael Johnson', 'Sergueï Bubka', 'Marie-José Pérec',
    'Renaud Lavillenie', 'Kevin Mayer', 'Teddy Tamgho', 'Mondo Duplantis', 'Eliud Kipchoge', 'Haile Gebrselassie',
    'Paavo Nurmi', 'Emil Zátopek', 'Florence Griffith-Joyner', 'Jackie Joyner-Kersee', 'Allyson Felix',
    'Sydney McLaughlin-Levrone', 'Sifan Hassan', 'Christophe Lemaitre'])
)
insert into public.topic_suggestions (topic_id, content, weight)
select t.id, s.content, greatest(1, 3 - (s.ord::int - 1) / 10)
from data d
join public.topics t on lower(t.title) = lower(d.title)
cross join lateral unnest(d.sugg) with ordinality as s(content, ord)
on conflict do nothing;
