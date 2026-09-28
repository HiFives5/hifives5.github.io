-- HiFives — supprime tous les profils de démo et leurs tops / likes.
-- Les sujets et suggestions sont conservés.
delete from public.profiles where is_demo;
