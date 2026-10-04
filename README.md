# HiFives ✋

Fais et partage tes top 5 (films, albums, clubs, destinations…), et compare tes goûts avec ceux de la communauté.

Appli web installable sur téléphone (PWA), avec Supabase comme base de données.

👉 **https://hifives5.github.io/**

```
app/                 ← l'appli (publiée sur GitHub Pages)
  index.html         ← tout le code de l'appli
  manifest.webmanifest, sw.js, icon-*.png  ← installation sur téléphone
supabase/
  schema.sql         ← structure de la base + règles de sécurité
  seed.sql           ← 40 sujets, suggestions, 16 profils de démo
  migrations/        ← évolutions de la base, à exécuter une fois chacune
  purge_demo.sql     ← supprime les profils de démo
```

## Mise en route (une seule fois)

### 1. Base de données Supabase
1. Ouvre ton projet sur [supabase.com](https://supabase.com/dashboard) → **SQL Editor** → **New query**.
2. Colle tout le contenu de `supabase/schema.sql` → **Run**.
   ⚠️ Cela efface les anciens tops de test. Tes comptes sont conservés.
3. Nouvelle requête : colle `supabase/seed.sql` → **Run**.
4. *(Conseillé pour tester)* **Authentication → Sign In / Providers → Email** : désactive **Confirm email**, pour pouvoir s'inscrire sans valider d'email.

### ⚠️ Évolutions de la base : migrations
Une fois qu'il y a de vraies données, **ne plus jamais relancer `schema.sql`** (il efface tout).
Les évolutions se font par des fichiers `supabase/migrations/NNN_*.sql`, à exécuter **une seule fois chacun**, dans l'ordre :
- `002_plus_de_sujets.sql` : 11 nouvelles catégories et ~80 nouveaux sujets.
- `003_retours_utilisateurs.sql` : retours utilisateurs (bouton 💬) + rôle administrateur.
  Puis, pour devenir admin : `update public.profiles set is_admin = true where handle = '@ton_pseudo';`
- `004_films_series_tmdb.sql` : sujets films / séries reliés à TMDB (identifiant unique par film, titre FR, année, affiche).
- `005_plus_de_tops.sql` : 24 nouveaux sujets officiels (capitales, rugby, cyclisme, whiskys, années 90…).
- `009_musique_musicbrainz.sql` : sujets musique reliés à MusicBrainz (artistes, albums, chansons ; identifiant unique, pochettes).
- `010_defis_sponsorises.sql` : défis sponsorisés (bonus de points, carte aux couleurs de la marque) + exemple « saveurs Danette ».
- `011_defis_sponsorises_quotidiens.sql` : un défi sponsorisé différent chaque jour (30 thèmes d'exemple, programmés sur 365 jours ; relancer pour prolonger).

### Défis sponsorisés
Table Editor → `sponsored_challenges` (modifiable par les admins uniquement) :
- `topic_id` (le sujet mis en avant), `brand`, `tagline`, `emoji` ou `logo_url`, `color` (#RRGGBB),
  `bonus_points` (ajoutés aux 50 pts), `cta_label` / `cta_url` (lien partenaire, affiché une fois le défi relevé),
  `starts_at` / `ends_at` (période), `is_example` (affiche « Exemple de partenariat » tant qu'aucun accord n'est signé).
- La mention « Sponsorisé » est toujours affichée (publicité identifiable). Le bonus n'est accordé que pendant la période.

### Films et séries (TMDB)
1. Crée un compte gratuit sur [themoviedb.org](https://www.themoviedb.org/signup), puis **Paramètres → API** → demande une clé (usage personnel / non commercial).
2. Copie la **clé API (v3)** ou le **jeton d'accès en lecture (v4)** dans `app/index.html`, ligne `const TMDB_KEY = '';`.
3. Sans clé, les sujets films / séries restent en saisie libre (l'appli fonctionne normalement).
4. Le type d'un sujet (`movie`, `tv` ou vide) se règle dans Table Editor → `topics` → `entity_type`.

### 2. Mise en ligne (GitHub Pages)
1. Sur GitHub : **Settings → Pages → Build and deployment → Source : GitHub Actions**.
2. L'appli se publie automatiquement à chaque modification de `app/` sur la branche par défaut (onglet **Actions** pour suivre).
   Adresse : **https://hifives5.github.io/**
3. Dans Supabase → **Authentication → URL Configuration** : mets cette adresse dans **Site URL** (pour les liens des emails).

> GitHub Pages gratuit nécessite un dépôt **public**. La clé Supabase présente dans le code est la clé « anon », publique par conception : ce sont les règles RLS de `schema.sql` qui protègent les données.

### 3. Sur le téléphone
- **iPhone** : ouvre l'adresse dans Safari → bouton Partager → **Sur l'écran d'accueil**.
- **Android** : ouvre dans Chrome → menu ⋮ → **Installer l'application**.

## Tester en local
```bash
cd app && python3 -m http.server 8000
# puis http://localhost:8000
```

## Profils de démo
16 faux profils (`is_demo = true`) remplissent ~60 % des sujets pour que l'appli ne soit pas vide.
- Masquables dans l'appli : **Profil → Inclure les profils de démo**.
- Suppression définitive : exécuter `supabase/purge_demo.sql`.

## Fonctionnement
- **Sujets** (`topics`) : « Top 5 films de Tarantino »… 40 officiels + ceux créés par les utilisateurs.
- **Réponses** (`tops` + `top_items`) : le top 5 d'une personne pour un sujet (une seule réponse par sujet, modifiable).
- **Suggestions** à la saisie : liste de départ + réponses déjà données, pour que « Pulp Fiction » s'écrive toujours pareil.
- **Points** (calculés par la base) : +50 par top rempli, +20 par sujet créé. Niveaux à 100 / 300 / 600 / 1000 pts.
- **Filtres** pays / âge / genre : s'appliquent aux compteurs, classements et à l'activité.

## Prochaines étapes (V2)
- Débloquer des fonctions avec les points (recommandations « ceux qui ont mis X ont aussi mis… », croisements entre sujets).
- Élection hebdomadaire du « top 5 des sujets proposés ».
- Amis / abonnements.
- Publicités + abonnement sans pub.
- Applis natives iOS / Android (ex. via Capacitor), si la version web ne suffit plus.
