# Sécurité

NairolFlipper est local-first. Le MVP ne contient ni compte utilisateur, ni backend, ni paiement.

- Aucun secret dans Git.
- Certificats Android/iOS hors dépôt.
- Tokens CI/store via secrets de plateforme.
- Dépendances tierces justifiées et épinglées.
- Pas de téléchargement/exécution dynamique de code.
- Les sauvegardes locales ne doivent jamais exécuter de contenu utilisateur.
