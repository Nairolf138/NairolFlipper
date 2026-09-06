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

`nairolflipper-web-<version>`, `nairolflipper-android-debug-<sha>.apk`, `nairolflipper-windows-<version>.zip`, etc.
