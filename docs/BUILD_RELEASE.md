# Build, CI et release

## Pull Request

Validation rapide : structure, import Godot headless, tests, build Web smoke si pertinent.

## `main`

Générer régulièrement Web, Android debug APK, Windows pour playtest.

## Tag release

Produire Web, Android, Windows, Linux, macOS, puis iOS quand signature configurée.

## GitHub Pages

Le build Web doit pouvoir être publié comme preview/main build.

## Android

Étape 1 : APK debug installable. Étape 2 : AAB release signé. Clés uniquement via secrets.

## iOS

Pipeline macOS séparé : export Godot vers Xcode, bundle, signature, archive, artifact/TestFlight selon stratégie. Aucun certificat dans Git.

## Versioning

Pré-alpha : `0.0.x`. Alpha : `0.1.0+`. SemVer pour releases.

## Reproductibilité

Épingler Godot, actions CI et outils. Éviter `latest` pour releases stables.

## Artifacts

Les PR produisent aussi `nairolflipper-playfield-captures` : PNG de la scène
réellement rendue en GL Compatibility et mesures de draw calls / mémoire texture.
Le runner Ubuntu utilise son Xvfb préinstallé et Mesa logiciel ; ce n'est pas un
benchmark Android. Reproduction avec un serveur graphique disponible :

```text
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1200x2100x24" godot \
  --display-driver x11 --rendering-method gl_compatibility --rendering-driver opengl3 \
  --audio-driver Dummy --path . --fixed-fps 60 --script res://tests/godot/capture_playfield.gd
```

Les images et `render_metrics.json` vont dans `build/visuals/`. Un rendu vide,
une taille incorrecte ou une erreur Godot fait échouer la validation.

PR 34 ajoute les formats tablette 768 × 1024, Pause et Rapport. La CI marque
`data/build_info.json` avant l'import : SHA du checkout testé (merge de test sur
une PR), SHA de la branche source, run et URL du workflow. Le menu et le rapport
affichent le SHA source ; le JSON conserve aussi le merge testé. Un build local
non estampillé annonce honnêtement `local`. Les trois presets incluent ce JSON.

Après les contrôles et les exports, `package_qualification.py` relit l'identité
dans l'APK et archive les SHA-256 des distributions / captures. Les artifacts
`nairolflipper-web`, `nairolflipper-windows` et
`nairolflipper-alpha-qualification` complètent l'APK et les captures existants.
Ces trois nouveaux artifacts sont conservés quatorze jours.
Le dossier de qualification contient manifeste, protocole et logs ; il conserve
`device_playtest: pending` / `alpha_qualified: false`. Ne pas promouvoir un tag
sur la seule base d'une CI verte.

`nairolflipper-web-<version>`, `nairolflipper-android-debug-<sha>.apk`, `nairolflipper-windows-<version>.zip`, etc.
