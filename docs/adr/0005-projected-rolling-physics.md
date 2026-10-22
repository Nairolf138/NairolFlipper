# ADR-0005 — Roulement projeté et moteur de flipper 2D

Status: Accepted

## Context

Les playtests signalent une bille semblant voler et un contrôle insuffisant.
Le profil précédent multipliait la gravité verticale de Godot et utilisait son
amortissement linéaire. La masse modifiait les impacts sans modéliser le plateau.
Les flippers tournaient à vitesse constante dans les deux sens.

## Decision

Conserver Godot 4.7.2, GDScript, la physique de collision 2D et GL Compatibility.
Remplacer l'intégration des forces de la bille dans `_integrate_forces` :

- accélération descendante d'une sphère pleine sans glissement :
  `a = (5/7) * 9.81 * pixels_per_meter * sin(pente)` ;
- résistance au roulement configurable opposée au mouvement, sans inversion
  artificielle lors de l'arrêt et sans amortissement linéaire global ;
- vitesse bornée dans le même callback physique et CCD par forme ;
- amortissement séparé de la rotation 2D lors des contacts.

Le profil initial utilise une pente de 6,5°, 1600 px/m et une résistance de
0,002. La masse reste normalisée pour les impulsions et les contacts. Elle ne
sert pas à accélérer artificiellement la descente.

Les flippers restent des `AnimatableBody2D` : montée de commande progressive,
accélération et vitesse bornées, maintien en butée et retour plus lent. Le
contour convexe suit la palette et est réfléchi pour le côté droit. Aucune
correction cachée de trajectoire n'est appliquée à une bille frappée.

Les rails intérieurs dégagent la palette levée et le retour droit est symétrisé.
Une bille en contact avec un flipper maintenu n'est pas considérée comme coincée.
La récupération reste active pour une bille bloquée ailleurs.

## Consequences

Les valeurs du lanceur sont recalibrées et les trajectoires de la PR 30 restent
couvertes, avec un contrôleur de test pouvant attraper puis rejouer une bille.
Les tests mesurent accélération, freinage, indépendance de la masse, cohérence
60/120 Hz, maintien et deux tirs distincts par flipper. La sensation finale
nécessite un playtest tablette.

Ce modèle est une approximation de roulement dans le plan. Il ne simule ni
hauteur, saut, rotation 3D complète, glissement transitoire après chaque impact,
ni déflexion du flipper sous la charge de la bille. Les principes de VPE servent
de référence de contrôle ; aucun code, profil nFozzy ou asset tiers n'est copié.

## Références

- [OpenStax — Rolling motion](https://openstax.org/books/university-physics-volume-1/pages/11-1-rolling-motion)
- [Godot — RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html)
- [VPE — Flipper](https://docs.visualpinball.org/creators-guide/manual/mechanisms/flippers.html)
