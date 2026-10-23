# ADR-0006 — Parcours physiques sur plans séparés

Status: Accepted

## Context

Warm/Cold et Universe Orbit étaient des zones de score sans trajet imposé par
la géométrie. Un contact suffisait à avancer la Cue Stack. Le moteur reste 2D,
mais les guides doivent pouvoir passer au-dessus du plateau sans emprisonner
une bille circulant dessous.

## Decision

Ajouter `PhysicalRoute` et une Resource `PhysicalRouteDefinition`. La courbe
centrale fournit le dessin du deck, les bords de collision continus, les portes
d'entrée/sortie et la progression. Les rails statiques utilisent des segments
concaves plutôt que des capsules dont les extrémités dispersaient les tirs rapides.

Les entrées s'évasent puis se resserrent progressivement avant les courbes.
Largeurs, longueur de transition, absorption des rails et indices des entrées
restent configurables. Une frappe peut être refusée et revenir par l'entrée :
les essais de visée recherchent un passage valide dans une plage de commandes,
sans exiger que toute incidence produise des points.

Une bille entre uniquement en franchissant la porte dans le bon sens, avec son
centre dans la largeur praticable. Elle conserve position, vitesse, intégrateur
de roulement et CCD. Les collisions avec les rails déterminent son trajet ;
aucun suivi de chemin, déplacement imposé, gel ou impulsion de sortie n'est utilisé.

Les plans de collision sont : plateau `1`, Warm `4`, Cold `8`, Orbit `16`.
L'admission change uniquement le plan et l'ordre de dessin de la bille. Les
capteurs du plateau ne comptent donc pas les passages au-dessus. Les billes
présentes sur le même parcours peuvent toujours se heurter.

Le score exige trois jalons ordonnés puis le franchissement de la sortie.
Un retour par l'entrée rétablit le plateau sans points. L'orbite propose deux
entrées orientées et deux prolongements de sortie vers les inlanes ; les rampes
Warm/Cold rendent la bille au flipper du même côté. L'état est propre à chaque
bille, sans cooldown global. Reset, drain et retour au menu restaurent les
collisions et la profondeur de dessin avant de réutiliser la bille.

Un compteur de réinitialisation invalide aussi l'ancienne position enregistrée
par les portes : replacer une bille n'est pas interprété comme un tir d'entrée.

## Consequences

Les parcours sont validés avec les vrais corps Godot : entrée, contacts de rails,
sortie, reprise aux flippers, tirs faibles, touches latérales, sens incorrect,
plusieurs billes, reset et menu. Des billes physiquement retenues puis frappées
valident Warm/Cold et les deux sens de l'orbite sur des plages de commande
précoces et tardives. Ces quatre visées ne remplacent pas le playtest tactile.

Les billes doivent appartenir au groupe `balls`, absent jusque-là de leur scène.
Sa correction réactive également les capteurs Rig/Console/slingshots qui le
vérifient. Les tests physiques couvrent maintenant ce contrat réellement.

Ce choix représente des passages dessus/dessous par plans logiques distincts,
pas une simulation 3D de hauteur. La hauteur de rampe n'ajoute pas d'énergie
potentielle indépendante de la pente projetée ; il n'y a ni saut ni chute entre
plans. Les billes de parcours différents ne se heurtent pas à leurs croisements.
Le rendu reste fonctionnel et vectoriel ; la refonte scénique appartient à la PR 33.
