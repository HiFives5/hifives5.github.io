-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 002 : 11 nouvelles catégories, ~80 nouveaux sujets
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- N'efface rien : ajoute seulement des sujets (relançable sans doublon).
-- Les profils de démo (s'ils existent encore) remplissent les nouveaux sujets.
-- ════════════════════════════════════════════════════════════════

with data(category, title, sugg) as (values
  -- ── NOUVEAU : BOISSONS ──
  ('Boissons', 'Top 5 eaux gazeuses', array[
    'San Pellegrino', 'Perrier', 'Badoit', 'Salvetat', 'Quézac',
    'Saint-Yorre', 'Vichy Célestins', 'Châteldon', 'Rozana', 'Wattwiller']),
  ('Boissons', 'Top 5 bières', array[
    'Leffe', 'La Chouffe', 'Guinness', 'Chimay', 'Duvel',
    'Grimbergen', 'Kronenbourg 1664', 'Heineken', 'Pelforth', 'Corona']),
  ('Boissons', 'Top 5 cocktails', array[
    'Mojito', 'Spritz', 'Gin tonic', 'Piña colada', 'Margarita',
    'Negroni', 'Moscow mule', 'Caïpirinha', 'Cosmopolitan', 'Espresso martini']),
  ('Boissons', 'Top 5 vins français', array[
    'Bourgogne', 'Bordeaux Saint-Émilion', 'Champagne', 'Côtes du Rhône', 'Châteauneuf-du-Pape',
    'Beaujolais', 'Sancerre', 'Chablis', 'Côte-Rôtie', 'Crozes-Hermitage']),
  ('Boissons', 'Top 5 sodas', array[
    'Coca-Cola', 'Orangina', 'Ice Tea', 'Oasis', 'Schweppes Agrumes',
    'Fanta', 'Sprite', 'Pepsi', 'Dr Pepper', 'Canada Dry']),

  -- ── NOUVEAU : PERSONNALITÉS ──
  ('Personnalités', 'Top 5 acteurs français', array[
    'Jean-Paul Belmondo', 'Louis de Funès', 'Jean Dujardin', 'Omar Sy', 'Jean Gabin',
    'Alain Delon', 'Vincent Cassel', 'Lino Ventura', 'Jean Reno', 'Romain Duris']),
  ('Personnalités', 'Top 5 actrices', array[
    'Meryl Streep', 'Marion Cotillard', 'Audrey Hepburn', 'Natalie Portman', 'Catherine Deneuve',
    'Cate Blanchett', 'Scarlett Johansson', 'Julia Roberts', 'Emma Stone', 'Isabelle Huppert']),
  ('Personnalités', 'Top 5 chanteurs et chanteuses français', array[
    'Jean-Jacques Goldman', 'Édith Piaf', 'Johnny Hallyday', 'Jacques Brel', 'Stromae',
    'Charles Aznavour', 'Serge Gainsbourg', 'Mylène Farmer', 'Angèle', 'Céline Dion']),
  ('Personnalités', 'Top 5 réalisateurs', array[
    'Christopher Nolan', 'Steven Spielberg', 'Quentin Tarantino', 'Stanley Kubrick', 'Martin Scorsese',
    'Alfred Hitchcock', 'Denis Villeneuve', 'Hayao Miyazaki', 'Francis Ford Coppola', 'Ridley Scott']),
  ('Personnalités', 'Top 5 personnalités inspirantes', array[
    'Nelson Mandela', 'Simone Veil', 'Martin Luther King', 'Gandhi', 'Marie Curie',
    'Albert Einstein', 'Steve Jobs', 'Barack Obama', 'Malala Yousafzai', 'L''abbé Pierre']),
  ('Personnalités', 'Top 5 personnes avec qui dîner (vivantes ou non)', array[
    'Léonard de Vinci', 'Barack Obama', 'Napoléon', 'Albert Einstein', 'Freddie Mercury',
    'Coluche', 'Cléopâtre', 'Zinédine Zidane', 'Marilyn Monroe', 'Jésus']),

  -- ── NOUVEAU : MARQUES & MODE ──
  ('Marques & mode', 'Top 5 marques de sneakers', array[
    'Nike', 'Adidas', 'New Balance', 'Veja', 'Converse',
    'Vans', 'Asics', 'Salomon', 'Puma', 'Reebok']),
  ('Marques & mode', 'Top 5 marques de luxe', array[
    'Hermès', 'Chanel', 'Louis Vuitton', 'Dior', 'Rolex',
    'Cartier', 'Gucci', 'Saint Laurent', 'Prada', 'Balenciaga']),
  ('Marques & mode', 'Top 5 enseignes préférées pour faire du shopping', array[
    'Decathlon', 'Ikea', 'Fnac', 'Zara', 'Uniqlo',
    'Sephora', 'Leroy Merlin', 'Picard', 'Action', 'Vinted']),
  ('Marques & mode', 'Top 5 marques de montres', array[
    'Rolex', 'Omega', 'Swatch', 'Tag Heuer', 'Casio',
    'Cartier', 'Seiko', 'Tissot', 'Audemars Piguet', 'Patek Philippe']),
  ('Marques & mode', 'Top 5 marques françaises', array[
    'Hermès', 'Michelin', 'Chanel', 'Lacoste', 'Opinel',
    'Peugeot', 'L''Oréal', 'Bic', 'Petit Bateau', 'Le Slip Français']),

  -- ── NOUVEAU : AUTO & MOTO ──
  ('Auto & moto', 'Top 5 voitures de rêve', array[
    'Porsche 911', 'Ferrari F40', 'Aston Martin DB5', 'Lamborghini Countach', 'Ford Mustang',
    'Mercedes 300 SL', 'Jaguar Type E', 'McLaren F1', 'Bugatti Chiron', 'Tesla Model S']),
  ('Auto & moto', 'Top 5 voitures françaises de légende', array[
    'Citroën DS', 'Peugeot 205 GTI', 'Alpine A110', 'Renault 5 Turbo', 'Citroën 2CV',
    'Renault 4L', 'Citroën Traction Avant', 'Peugeot 504', 'Renault Twingo', 'Bugatti Type 57']),
  ('Auto & moto', 'Top 5 voitures de films et séries', array[
    'DeLorean — Retour vers le futur', 'Aston Martin DB5 — James Bond', 'Batmobile', 'K2000', 'Ecto-1 — SOS Fantômes',
    'Ford Mustang — Bullitt', 'Mini Cooper — L''or se barre', 'Dodge Charger — Fast & Furious', 'Choupette — La Coccinelle', 'Peugeot 406 — Taxi']),
  ('Auto & moto', 'Top 5 marques de voiture', array[
    'Porsche', 'BMW', 'Mercedes', 'Peugeot', 'Toyota',
    'Audi', 'Tesla', 'Renault', 'Volkswagen', 'Ferrari']),
  ('Auto & moto', 'Top 5 pilotes de Formule 1', array[
    'Ayrton Senna', 'Michael Schumacher', 'Lewis Hamilton', 'Alain Prost', 'Max Verstappen',
    'Niki Lauda', 'Juan Manuel Fangio', 'Fernando Alonso', 'Sebastian Vettel', 'Jim Clark']),

  -- ── NOUVEAU : TECH & WEB ──
  ('Tech & web', 'Top 5 applis indispensables', array[
    'WhatsApp', 'Google Maps', 'Spotify', 'Waze', 'YouTube',
    'Instagram', 'Netflix', 'Doctolib', 'Leboncoin', 'Vinted']),
  ('Tech & web', 'Top 5 créateurs YouTube français', array[
    'Squeezie', 'Cyprien', 'Norman', 'McFly et Carlito', 'HugoDécrypte',
    'Amixem', 'Inoxtag', 'Léna Situations', 'Mister V', 'Tibo InShape']),
  ('Tech & web', 'Top 5 inventions tech qui ont changé ta vie', array[
    'Le smartphone', 'Internet', 'Le GPS', 'Le Wi-Fi', 'Le streaming',
    'L''intelligence artificielle', 'Le paiement sans contact', 'L''ordinateur portable', 'Les réseaux sociaux', 'Les écouteurs sans fil']),
  ('Tech & web', 'Top 5 réseaux sociaux', array[
    'Instagram', 'WhatsApp', 'YouTube', 'TikTok', 'LinkedIn',
    'Reddit', 'Snapchat', 'X (Twitter)', 'Facebook', 'Pinterest']),
  ('Tech & web', 'Top 5 podcasts', array[
    'Affaires sensibles', 'Transfert', 'Les Pieds sur terre', 'Génération Do It Yourself', 'Floodcast',
    'Choses à Savoir', 'La Poudre', 'Le Code a changé', 'Les Couilles sur la table', 'Grand Bien Vous Fasse']),

  -- ── NOUVEAU : NOSTALGIE ──
  ('Nostalgie', 'Top 5 dessins animés de ton enfance', array[
    'Dragon Ball Z', 'Les Chevaliers du Zodiaque', 'Olive et Tom', 'Il était une fois… la Vie', 'Les Razmoket',
    'Inspecteur Gadget', 'Les Tortues Ninja', 'Capitaine Flam', 'Tom-Tom et Nana', 'Pokémon']),
  ('Nostalgie', 'Top 5 émissions TV cultes', array[
    'Fort Boyard', 'Club Dorothée', 'Les Guignols de l''info', 'Qui veut gagner des millions ?', 'Nulle Part Ailleurs',
    'Intervilles', 'Loft Story', 'Question pour un champion', 'Des chiffres et des lettres', 'Les Minikeums']),
  ('Nostalgie', 'Top 5 bonbons', array[
    'Fraises Tagada', 'Carambar', 'Dragibus', 'Crocodiles Haribo', 'Chamallows',
    'Car en Sac', 'Malabar', 'Schtroumpfs Haribo', 'Kinder Surprise', 'Mistral gagnant']),
  ('Nostalgie', 'Top 5 goûters', array[
    'Pain au chocolat', 'Prince', 'Tartine de Nutella', 'Petit Écolier', 'BN',
    'Kinder Bueno', 'Pom''Potes', 'Pépito', 'Figolu', 'Savane']),
  ('Nostalgie', 'Top 5 jouets cultes', array[
    'Lego', 'Game Boy', 'Playmobil', 'Tamagotchi', 'Polly Pocket',
    'Rubik''s Cube', 'Barbie', 'Furby', 'Pogs', 'Toupie Beyblade']),

  -- ── NOUVEAU : HISTOIRE & CULTURE ──
  ('Histoire & culture', 'Top 5 monuments du monde', array[
    'Machu Picchu', 'Colisée', 'Taj Mahal', 'Tour Eiffel', 'Pyramides de Gizeh',
    'Grande Muraille de Chine', 'Angkor Vat', 'Mont-Saint-Michel', 'Sagrada Família', 'Petra']),
  ('Histoire & culture', 'Top 5 peintres', array[
    'Van Gogh', 'Monet', 'Léonard de Vinci', 'Picasso', 'Rembrandt',
    'Frida Kahlo', 'Caravage', 'Klimt', 'Dalí', 'Magritte']),
  ('Histoire & culture', 'Top 5 inventions de l''humanité', array[
    'L''imprimerie', 'La roue', 'L''électricité', 'Internet', 'Les vaccins',
    'L''écriture', 'Les antibiotiques', 'La machine à vapeur', 'Le téléphone', 'L''avion']),
  ('Histoire & culture', 'Top 5 musées', array[
    'Le Louvre', 'Musée d''Orsay', 'Le Prado', 'British Museum', 'MoMA',
    'Galerie des Offices', 'Musées du Vatican', 'Rijksmuseum', 'Musée des Confluences', 'Guggenheim Bilbao']),
  ('Histoire & culture', 'Top 5 personnages historiques', array[
    'Napoléon', 'Jeanne d''Arc', 'Charles de Gaulle', 'Jules César', 'Léonard de Vinci',
    'Cléopâtre', 'Louis XIV', 'Alexandre le Grand', 'Winston Churchill', 'Gandhi']),

  -- ── NOUVEAU : NATURE & ANIMAUX ──
  ('Nature & animaux', 'Top 5 animaux préférés', array[
    'Chien', 'Chat', 'Dauphin', 'Loup', 'Panda',
    'Éléphant', 'Lion', 'Cheval', 'Loutre', 'Tigre']),
  ('Nature & animaux', 'Top 5 races de chiens', array[
    'Golden Retriever', 'Labrador', 'Berger australien', 'Bouledogue français', 'Border Collie',
    'Jack Russell', 'Husky', 'Cavalier King Charles', 'Berger allemand', 'Teckel']),
  ('Nature & animaux', 'Top 5 paysages naturels', array[
    'Aurores boréales en Islande', 'Fjords de Norvège', 'Grand Canyon', 'Dolomites', 'Gorges du Verdon',
    'Baie d''Halong', 'Patagonie', 'Chutes d''Iguazú', 'Désert du Sahara', 'Grande Barrière de corail']),
  ('Nature & animaux', 'Top 5 randonnées en France', array[
    'Tour du Mont-Blanc', 'GR20 en Corse', 'Calanques de Marseille', 'Sentier Blanc-Martel (Verdon)', 'Lac Blanc (Chamonix)',
    'Cirque de Gavarnie', 'Sentier des douaniers (Bretagne)', 'Chemin de Stevenson', 'Hauts Plateaux du Vercors', 'Puy de Dôme']),
  ('Nature & animaux', 'Top 5 fleurs', array[
    'Pivoine', 'Rose', 'Tournesol', 'Lavande', 'Tulipe',
    'Cerisier en fleurs', 'Orchidée', 'Coquelicot', 'Lys', 'Muguet']),

  -- ── NOUVEAU : SPECTACLES & SORTIES ──
  ('Spectacles & sorties', 'Top 5 humoristes français', array[
    'Coluche', 'Florence Foresti', 'Gad Elmaleh', 'Jamel Debbouze', 'Les Inconnus',
    'Pierre Desproges', 'Blanche Gardin', 'Alexandre Astier', 'Fary', 'Kev Adams']),
  ('Spectacles & sorties', 'Top 5 personnages de fiction les plus drôles', array[
    'Jacquouille la Fripouille', 'OSS 117', 'Homer Simpson', 'Perceval (Kaamelott)', 'Michael Scott',
    'François Pignon', 'Joey Tribbiani', 'Mr. Bean', 'Barney Stinson', 'Ace Ventura']),
  ('Spectacles & sorties', 'Top 5 festivals et événements', array[
    'Fête des Lumières (Lyon)', 'Nuits de Fourvière', 'Festival de Cannes', 'Les Vieilles Charrues', 'Hellfest',
    'Tomorrowland', 'Coachella', 'Rock en Seine', 'Les Francofolies', 'Solidays']),
  ('Spectacles & sorties', 'Top 5 comédies musicales', array[
    'Le Roi Lion', 'Notre-Dame de Paris', 'Les Misérables', 'Starmania', 'Mamma Mia!',
    'Grease', 'Le Fantôme de l''Opéra', 'West Side Story', 'Cats', 'Les Dix Commandements']),
  ('Spectacles & sorties', 'Top 5 sorties pour une soirée parfaite', array[
    'Dîner au restaurant', 'Concert', 'Cinéma', 'Apéro en terrasse', 'Soirée jeux entre amis',
    'Théâtre', 'Match au stade', 'Bar à cocktails', 'Stand-up', 'Karaoké']),

  -- ── NOUVEAU : LIFESTYLE ──
  ('Lifestyle', 'Top 5 activités du week-end', array[
    'Brunch', 'Apéro entre amis', 'Randonnée', 'Grasse matinée', 'Sport',
    'Cinéma', 'Balade en ville', 'Séries sous la couette', 'Brocante', 'Musée']),
  ('Lifestyle', 'Top 5 sports à pratiquer', array[
    'Running', 'Vélo', 'Natation', 'Golf', 'Tennis',
    'Ski', 'Padel', 'Randonnée', 'Yoga', 'Football']),
  ('Lifestyle', 'Top 5 métiers de rêve', array[
    'Astronaute', 'Pilote de ligne', 'Chef cuisinier', 'Architecte', 'Vétérinaire',
    'Photographe', 'Footballeur', 'Médecin', 'Explorateur', 'Créateur de jeux vidéo']),
  ('Lifestyle', 'Top 5 prénoms préférés', array[
    'Louise', 'Gabriel', 'Jade', 'Léo', 'Alice',
    'Raphaël', 'Emma', 'Louis', 'Rose', 'Arthur']),
  ('Lifestyle', 'Top 5 petits bonheurs du quotidien', array[
    'Un repas en famille', 'Un fou rire', 'Le premier café du matin', 'Les vacances', 'Un câlin',
    'Le soleil en terrasse', 'Un bon livre', 'Les draps propres', 'Une douche chaude', 'La musique']),

  -- ── NOUVEAU : DÉBATS & INSOLITE ──
  ('Débats & insolite', 'Top 5 pires garnitures de pizza', array[
    'Ananas', 'Anchois', 'Maïs', 'Thon', 'Olives',
    'Câpres', 'Œuf', 'Poivrons', 'Crème fraîche', 'Champignons']),
  ('Débats & insolite', 'Top 5 plats les plus surcotés', array[
    'Avocado toast', 'Caviar', 'Poke bowl', 'Truffe', 'Homard',
    'Burger gourmet', 'Huîtres', 'Foie gras', 'Sushis', 'Cronut']),
  ('Débats & insolite', 'Top 5 super-pouvoirs', array[
    'Téléportation', 'Voler', 'Remonter le temps', 'Arrêter le temps', 'Invisibilité',
    'Lire dans les pensées', 'Parler toutes les langues', 'Guérir', 'Super-force', 'Immortalité']),
  ('Débats & insolite', 'Top 5 petits agacements du quotidien', array[
    'La batterie à 1 %', 'Les gens qui parlent au cinéma', 'Les bouchons', 'Les pubs avant les vidéos', 'Le réveil du lundi',
    'Le Wi-Fi qui coupe', 'Les files d''attente', 'Le câble de chargeur trop court', 'Les notifications', 'Les chaussettes dépareillées']),
  ('Débats & insolite', 'Top 5 films surcotés', array[
    'Titanic', 'Avatar', 'Intouchables', 'Forrest Gump', 'La La Land',
    'Le Seigneur des anneaux', 'Star Wars : épisode I', 'Inception', 'Joker', 'Bohemian Rhapsody']),

  -- ── CATÉGORIES EXISTANTES : SUJETS EN PLUS ──
  ('Cinéma', 'Top 5 films d''horreur', array[
    'Shining', 'Alien', 'L''Exorciste', 'Scream', 'Get Out',
    'Halloween', 'Psychose', 'Hérédité', 'Conjuring', 'Ça']),
  ('Cinéma', 'Top 5 sagas de films', array[
    'Star Wars', 'Le Seigneur des anneaux', 'Harry Potter', 'Retour vers le futur', 'Le Parrain',
    'Indiana Jones', 'Mission Impossible', 'Marvel', 'Jurassic Park', 'Rocky']),
  ('Cinéma', 'Top 5 films Pixar', array[
    'Toy Story', 'Là-haut', 'Ratatouille', 'Wall-E', 'Le Monde de Nemo',
    'Les Indestructibles', 'Coco', 'Monstres & Cie', 'Vice-versa', 'Soul']),
  ('Musique', 'Top 5 tubes des années 90', array[
    'Smells Like Teen Spirit — Nirvana', 'Wonderwall — Oasis', 'Wannabe — Spice Girls', 'Gangsta''s Paradise — Coolio', 'Around the World — Daft Punk',
    'Blue (Da Ba Dee) — Eiffel 65', '...Baby One More Time — Britney Spears', 'I Will Always Love You — Whitney Houston', 'Tomber la chemise — Zebda', 'Macarena — Los del Río']),
  ('Musique', 'Top 5 artistes à voir en concert', array[
    'Coldplay', 'Beyoncé', 'Muse', 'Rammstein', 'Indochine',
    'Bruce Springsteen', 'Taylor Swift', 'Stromae', 'Metallica', 'Ed Sheeran']),
  ('Musique', 'Top 5 albums de jazz', array[
    'Kind of Blue — Miles Davis', 'A Love Supreme — John Coltrane', 'Time Out — Dave Brubeck', 'Getz/Gilberto', 'The Köln Concert — Keith Jarrett',
    'Blue Train — John Coltrane', 'Mingus Ah Um — Charles Mingus', 'Moanin'' — Art Blakey', 'Waltz for Debby — Bill Evans', 'Ella and Louis']),
  ('Séries', 'Top 5 méchants de séries', array[
    'Joffrey Baratheon', 'Homelander', 'Gus Fring', 'Ramsay Bolton', 'Cersei Lannister',
    'Negan', 'Villanelle', 'Tywin Lannister', 'Ben Linus', 'Walter White']),
  ('Séries', 'Top 5 séries policières', array[
    'True Detective', 'Mindhunter', 'Sherlock', 'Engrenages', 'Broadchurch',
    'Columbo', 'Line of Duty', 'Mare of Easttown', 'Dexter', 'The Wire']),
  ('Sport', 'Top 5 parcours de golf mythiques', array[
    'Augusta National', 'St Andrews — Old Course', 'Pebble Beach', 'Pine Valley', 'Cypress Point',
    'Le Golf National', 'Royal County Down', 'TPC Sawgrass', 'Muirfield', 'Carnoustie']),
  ('Sport', 'Top 5 joueurs de tennis', array[
    'Roger Federer', 'Rafael Nadal', 'Novak Djokovic', 'Pete Sampras', 'Björn Borg',
    'Serena Williams', 'Carlos Alcaraz', 'Andre Agassi', 'Steffi Graf', 'John McEnroe']),
  ('Sport', 'Top 5 basketteurs NBA', array[
    'Michael Jordan', 'LeBron James', 'Kobe Bryant', 'Magic Johnson', 'Stephen Curry',
    'Kareem Abdul-Jabbar', 'Shaquille O''Neal', 'Larry Bird', 'Tim Duncan', 'Victor Wembanyama']),
  ('Voyages', 'Top 5 villes du monde', array[
    'New York', 'Tokyo', 'Rome', 'Barcelone', 'Lisbonne',
    'Kyoto', 'Londres', 'Paris', 'Buenos Aires', 'Istanbul']),
  ('Voyages', 'Top 5 îles', array[
    'Corse', 'Santorin', 'La Réunion', 'Sicile', 'Bali',
    'Île Maurice', 'Majorque', 'Guadeloupe', 'Zanzibar', 'Bora Bora']),
  ('Voyages', 'Top 5 stations de ski', array[
    'Val d''Isère', 'Chamonix', 'Courchevel', 'Val Thorens', 'Tignes',
    'Les Arcs', 'Megève', 'Zermatt', 'Serre Chevalier', 'Les 2 Alpes']),
  ('Gastronomie', 'Top 5 desserts', array[
    'Tiramisu', 'Mousse au chocolat', 'Tarte Tatin', 'Fondant au chocolat', 'Crème brûlée',
    'Île flottante', 'Paris-Brest', 'Profiteroles', 'Mille-feuille', 'Cheesecake']),
  ('Gastronomie', 'Top 5 viennoiseries', array[
    'Croissant', 'Pain au chocolat', 'Croissant aux amandes', 'Pain aux raisins', 'Kouign-amann',
    'Chausson aux pommes', 'Brioche', 'Chouquettes', 'Suisse', 'Pain au lait']),
  ('Gastronomie', 'Top 5 street food', array[
    'Burger', 'Kebab', 'Tacos mexicains', 'Bánh mì', 'Pad thaï',
    'Falafel', 'Crêpe', 'Fish and chips', 'Hot-dog', 'Arancini']),
  ('Livres', 'Top 5 auteurs français', array[
    'Victor Hugo', 'Albert Camus', 'Alexandre Dumas', 'Émile Zola', 'Jules Verne',
    'Molière', 'Guy de Maupassant', 'Honoré de Balzac', 'Marcel Proust', 'Antoine de Saint-Exupéry']),
  ('Livres', 'Top 5 livres lus à l''école', array[
    'Le Petit Prince', 'L''Étranger', 'Candide', 'Germinal', 'Bel-Ami',
    'Antigone', 'Les Fourberies de Scapin', 'Le Horla', 'Madame Bovary', 'Le Rouge et le Noir']),
  ('Jeux', 'Top 5 jeux PlayStation', array[
    'The Last of Us', 'God of War', 'Uncharted 2', 'Metal Gear Solid', 'Final Fantasy X',
    'Crash Bandicoot', 'Gran Turismo', 'Ghost of Tsushima', 'Marvel''s Spider-Man', 'Bloodborne']),
  ('Jeux', 'Top 5 jeux sur mobile', array[
    'Clash Royale', 'Candy Crush', 'Pokémon GO', 'Among Us', 'Subway Surfers',
    'Angry Birds', 'Clash of Clans', 'Brawl Stars', 'Monument Valley', 'Wordle'])
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

-- ── Les profils de démo remplissent ~60 % des sujets officiels qu'ils n'ont pas encore touchés ──
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
