-- ════════════════════════════════════════════════════════════════
-- HiFives — migration 017 : exemples de bandeaux publicitaires par thème
-- À exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run (après la 016).
-- N'efface rien ; relançable (n'ajoute que les bandeaux absents).
--
-- 57 exemples de marques (2 à 3 par thème, 2 généraux), tous marqués « Exemple » tant qu'aucun accord
-- n'est signé. Pas d'alcool, de tabac ni de jeux d'argent. À modifier / désactiver dans la page admin.
-- ════════════════════════════════════════════════════════════════

insert into public.ads (title, body, emoji, color, cta_label, cta_url, category, is_example)
select v.*, true from (values
  ('Pathé : les films à l''affiche', 'Réserve ta séance et ton siège en quelques secondes.', '🍿', '#FFB400', 'Voir les séances', 'https://www.pathe.fr', 'Cinéma'),
  ('UGC : le cinéma en illimité', 'Une carte, tous les films, autant de fois que tu veux.', '🎟️', '#E4002B', 'Découvrir', 'https://www.ugc.fr', 'Cinéma'),
  ('CANAL+ : cinéma et séries', 'Les films récents et les grandes séries, chez toi.', '📺', '#111111', 'Découvrir', 'https://www.canalplus.com', 'Cinéma'),
  ('Spotify : ta musique partout', 'Des millions de titres et de podcasts, et tes playlists à toi.', '🎧', '#1DB954', 'Écouter', 'https://open.spotify.com', 'Musique'),
  ('Deezer : le flow qui te ressemble', 'Ta musique, tes recommandations, sans pub en Premium.', '🎵', '#A238FF', 'Écouter', 'https://www.deezer.com', 'Musique'),
  ('Fnac Spectacles : les concerts', 'Tes artistes préférés en live près de chez toi.', '🎤', '#E1A925', 'Voir les concerts', 'https://www.fnacspectacles.com', 'Musique'),
  ('SNCF Connect : partez en train', 'Billets, horaires et cartes de réduction au même endroit.', '🚄', '#A1006B', 'Réserver', 'https://www.sncf-connect.com', 'Voyages'),
  ('Air France : prochaine destination ?', 'Long-courriers, week-ends et escapades au soleil.', '✈️', '#002157', 'Voir les vols', 'https://www.airfrance.fr', 'Voyages'),
  ('Booking.com : où dormir ?', 'Hôtels, appartements et maisons partout dans le monde.', '🏨', '#003580', 'Rechercher', 'https://www.booking.com', 'Voyages'),
  ('Decathlon : à fond le sport', 'Running, vélo, randonnée : l''équipement pour bouger ce week-end.', '🏃', '#0082C3', 'Découvrir', 'https://www.decathlon.fr', 'Sport'),
  ('Nike : Just Do It', 'Chaussures et tenues pour courir, jouer, t''entraîner.', '👟', '#111111', 'Découvrir', 'https://www.nike.com/fr', 'Sport'),
  ('Intersport : le sport pour tous', 'Foot, tennis, ski : tout pour ton sport préféré.', '⚽', '#E30613', 'Découvrir', 'https://www.intersport.fr', 'Sport'),
  ('Netflix : la série de ce soir', 'Des séries à dévorer, et une nouveauté chaque semaine.', '🍿', '#B20710', 'Découvrir', 'https://www.netflix.com', 'Séries'),
  ('Disney+ : Marvel, Star Wars, Pixar…', 'Les grandes sagas et les séries originales.', '🏰', '#113CCF', 'Découvrir', 'https://www.disneyplus.com/fr-fr', 'Séries'),
  ('Prime Video : séries et films', 'Les séries originales Amazon et des films à la demande.', '📦', '#00A8E1', 'Découvrir', 'https://www.primevideo.com', 'Séries'),
  ('Picard : le bon, surgelé', 'Plats, desserts et apéros prêts quand tu l''es.', '🍨', '#00A0DF', 'Voir les produits', 'https://www.picard.fr', 'Gastronomie'),
  ('Uber Eats : ce soir, on commande', 'Pizza, sushi, burger : tes restos préférés livrés.', '🛵', '#06C167', 'Commander', 'https://www.ubereats.com/fr', 'Gastronomie'),
  ('Marmiton : quoi manger ce soir ?', 'Des milliers de recettes testées et notées.', '👩‍🍳', '#E85D2A', 'Trouver une recette', 'https://www.marmiton.org', 'Gastronomie'),
  ('Fnac : ta prochaine lecture', 'Romans, BD, mangas : les nouveautés et les classiques.', '📚', '#E1A925', 'Découvrir', 'https://www.fnac.com', 'Livres'),
  ('Cultura : lire, créer, jouer', 'Livres, loisirs créatifs et jeux pour tous.', '📖', '#5B2C83', 'Découvrir', 'https://www.cultura.com', 'Livres'),
  ('Audible : les livres à écouter', 'Des milliers de livres audio et de podcasts.', '🎧', '#F7991C', 'Écouter', 'https://www.audible.fr', 'Livres'),
  ('Nintendo : à toi de jouer', 'Mario, Zelda, Pokémon : les jeux Switch.', '🍄', '#E60012', 'Découvrir', 'https://www.nintendo.fr', 'Jeux'),
  ('PlayStation : jouez sans limite', 'Les exclusivités PS5 et le PlayStation Plus.', '🎮', '#003791', 'Découvrir', 'https://www.playstation.com/fr-fr', 'Jeux'),
  ('Hasbro : soirée jeux de société', 'Monopoly, Cluedo, Puissance 4 : les classiques.', '🎲', '#0D4FA8', 'Découvrir', 'https://shop.hasbro.com', 'Jeux'),
  ('Nespresso : votre pause café', 'Des cafés d''exception, chez vous ou au bureau.', '☕', '#3A2A1E', 'Découvrir', 'https://www.nespresso.com/fr', 'Boissons'),
  ('Oasis : be fruit', 'Des boissons aux fruits pour se désaltérer.', '🍊', '#F39200', 'Découvrir', 'https://www.oasis.fr', 'Boissons'),
  ('innocent : smoothies et jus', 'Des fruits mixés, rien d''autre.', '🥤', '#7FBA00', 'Découvrir', 'https://www.innocentdrinks.fr', 'Boissons'),
  ('Gala : l''actu des stars', 'Les people, les tapis rouges et les coulisses.', '🌟', '#C8102E', 'Lire', 'https://www.gala.fr', 'Personnalités'),
  ('Konbini : les interviews cultes', 'Les stars comme tu ne les as jamais vues.', '🎬', '#111111', 'Regarder', 'https://www.konbini.com', 'Personnalités'),
  ('Zalando : ton style, livré', 'Mode, chaussures et accessoires de milliers de marques.', '👗', '#FF6900', 'Découvrir', 'https://www.zalando.fr', 'Marques & mode'),
  ('Lacoste : l''élégance sportive', 'Polos, sneakers et collections de saison.', '🎾', '#00563F', 'Découvrir', 'https://www.lacoste.com', 'Marques & mode'),
  ('Vinted : la mode de seconde main', 'Vends ce que tu ne portes plus, trouve des pépites.', '♻️', '#09B1BA', 'Découvrir', 'https://www.vinted.fr', 'Marques & mode'),
  ('Renault : la nouvelle R5', 'Découvre les modèles électriques et hybrides.', '🚗', '#EFDF00', 'Découvrir', 'https://www.renault.fr', 'Auto & moto'),
  ('Peugeot : l''allure électrique', 'Citadines, SUV et utilitaires, en électrique aussi.', '🦁', '#152032', 'Découvrir', 'https://www.peugeot.fr', 'Auto & moto'),
  ('BlaBlaCar : partage la route', 'Covoiturage et bus partout en France et en Europe.', '🚙', '#054752', 'Trouver un trajet', 'https://www.blablacar.fr', 'Auto & moto'),
  ('Samsung : Galaxy', 'Smartphones, tablettes et montres connectées.', '📱', '#1428A0', 'Découvrir', 'https://www.samsung.com/fr', 'Tech & web'),
  ('Apple : iPhone, Mac, iPad', 'Les derniers produits Apple.', '💻', '#111111', 'Découvrir', 'https://www.apple.com/fr', 'Tech & web'),
  ('Boulanger : high-tech et électroménager', 'Conseils, livraison et installation.', '🔌', '#F28C00', 'Découvrir', 'https://www.boulanger.com', 'Tech & web'),
  ('Haribo : c''est beau la vie', 'Fraises Tagada, Dragibus, Crocodiles… les bonbons cultes.', '🍬', '#C8102E', 'Découvrir', 'https://www.haribo.com', 'Nostalgie'),
  ('LEGO : construis tes rêves', 'Des sets pour tous les âges et toutes les passions.', '🧱', '#D01012', 'Découvrir', 'https://www.lego.com/fr-fr', 'Nostalgie'),
  ('Kinder : le goûter culte', 'Kinder Bueno, Surprise, Country : les classiques du goûter.', '🥚', '#E2001A', 'Découvrir', 'https://www.kinder.com/fr', 'Nostalgie'),
  ('Musée du Louvre', 'Réserve ta visite et découvre les collections.', '🖼️', '#9C7A3C', 'Réserver', 'https://www.louvre.fr', 'Histoire & culture'),
  ('ARTE : documentaires et culture', 'Histoire, sciences, cinéma : à voir en ligne.', '📺', '#FD4600', 'Regarder', 'https://www.arte.tv/fr', 'Histoire & culture'),
  ('Puy du Fou : voyage dans le temps', 'Grands spectacles et villages d''époque.', '🏰', '#7A1F2B', 'Découvrir', 'https://www.puydufou.com', 'Histoire & culture'),
  ('ZooParc de Beauval', 'Pandas, éléphants, koalas : une journée inoubliable.', '🐼', '#2E7D32', 'Découvrir', 'https://www.zoobeauval.com', 'Nature & animaux'),
  ('Truffaut : jardin et animalerie', 'Plantes, jardinage et tout pour tes animaux.', '🌱', '#00843D', 'Découvrir', 'https://www.truffaut.com', 'Nature & animaux'),
  ('WWF : protéger la nature', 'Agis pour les espèces et les espaces naturels.', '🐾', '#111111', 'Découvrir', 'https://www.wwf.fr', 'Nature & animaux'),
  ('Ticketmaster : tes sorties', 'Concerts, théâtre, humour et sport.', '🎭', '#026CDF', 'Voir les événements', 'https://www.ticketmaster.fr', 'Spectacles & sorties'),
  ('Disneyland Paris', 'Parcs, spectacles et parades pour toute la famille.', '🏰', '#113CCF', 'Découvrir', 'https://www.disneylandparis.com/fr-fr', 'Spectacles & sorties'),
  ('Fnac Spectacles : humour et théâtre', 'Les spectacles près de chez toi.', '🎟️', '#E1A925', 'Réserver', 'https://www.fnacspectacles.com', 'Spectacles & sorties'),
  ('IKEA : idées déco', 'Meubles et rangements pour chaque pièce.', '🪑', '#0058A3', 'Découvrir', 'https://www.ikea.com/fr/fr', 'Lifestyle'),
  ('Maisons du Monde : déco et meubles', 'Des styles pour tous les intérieurs.', '🛋️', '#1E1E1E', 'Découvrir', 'https://www.maisonsdumonde.com/FR/fr', 'Lifestyle'),
  ('Airbnb : séjourner autrement', 'Logements uniques et expériences locales.', '🏡', '#FF385C', 'Découvrir', 'https://www.airbnb.fr', 'Lifestyle'),
  ('Brut : l''actu en vidéo', 'Les sujets qui font débat, en quelques minutes.', '📰', '#111111', 'Regarder', 'https://www.brut.media/fr', 'Débats & insolite'),
  ('Konbini : le média qui détonne', 'Culture, société et sujets insolites.', '😮', '#111111', 'Découvrir', 'https://www.konbini.com', 'Débats & insolite'),
  ('Duolingo : une langue en 5 minutes par jour', 'Apprends l''anglais, l''espagnol ou le japonais en jouant.', '🦉', '#58CC02', 'Commencer', 'https://www.duolingo.com', null),
  ('Guide MICHELIN : les bonnes tables', 'Restaurants et hôtels sélectionnés près de chez toi.', '⭐', '#27509B', 'Explorer', 'https://guide.michelin.com/fr', null)
) v(title, body, emoji, color, cta_label, cta_url, category)
where not exists (select 1 from public.ads a where a.title = v.title);
