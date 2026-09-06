# Matrice plateformes

| Capacité | Web | Android | iOS | Windows | macOS | Linux |
|---|---:|---:|---:|---:|---:|---:|
| Gameplay complet | Oui | Oui | Oui | Oui | Oui | Oui |
| Clavier | Oui | partiel | partiel | Oui | Oui | Oui |
| Tactile | selon appareil | Oui | Oui | selon écran | selon écran | selon écran |
| Manette | navigateur/API | Oui | Oui | Oui | Oui | Oui |
| Haptics | fallback | option | option | non requis | non requis | non requis |
| Sauvegarde locale | Oui | Oui | Oui | Oui | Oui | Oui |
| Stems musicaux | Oui | Oui | Oui | Oui | Oui | Oui |

## Web

WebAssembly/WebGL 2, pas de C#, pas d'audio procédural obligatoire, pas de threads requis au MVP, téléchargement raisonnable, tactile compatible. Canal de test rapide.

## Android

APK debug d'abord, AAB release plus tard, tactile prioritaire, pause/resume, ratios variés.

## iOS

Export/signature via macOS/Xcode. Aucun code gameplay dépendant d'API Apple.

## Desktop

Windows P0. macOS/Linux P1 sans incompatibilité volontaire.

## Orientation

Portrait. Desktop : table centrée et zones latérales.

## Qualité

Profils `Low`, `Medium`, `High`.
