# Stagecraft — original artwork

Original SVG source authored for NairolFlipper in PR 33 (2026-10-23), under the
repository's MIT license. No third-party assets, extracted game media, reference
brand designs, fonts, remote resources or generative bitmap service are used.
Generic fixture categories are not manufacturer models.

| File | Purpose | Imported pixels |
|---|---|---|
| `fixture_atlas.svg` | Six unique fixture silhouettes: Fresnel / LED wash / moving head / pixel batten / twin blinder / protected practical | 960 × 112 |
| `bumper.svg` | Reflector bowl, glass, rubber skirt, bezel, fasteners | 144 × 144 |
| `ball.svg` | Chrome sphere, fixed table-light reflection | 48 × 48 |
| `flipper.svg` | Cream rubber, steel spine, pivot | 210 × 52 |
| `console.svg` | Original generic console, screens, faders, encoders | 320 × 180 |
| `slingshot.svg` | Steel plate, rubber band and posts | 210 × 120 |
| `guide_rail.svg` | Extruded steel guide with fasteners | 232 × 28 |
| `stage_deck.svg` | Matte modular floor, seams, fasteners and cable runs | 1024 × 1536 |

All gradients are baked by Godot's SVG importer; no runtime SVG parsing,
fullscreen shaders, filter effects or texture animation. The small fixture atlas
is shared by targets and truss fixtures. Native RGBA footprint is below 7 MiB
before importer overhead; do not scale up without measuring on Android.

Ramp materials are code-native in `scripts/show/route_visual.gd`, generated once
from the physical rail edges. They intentionally remain open / translucent at
crossings to avoid covering lower fixtures with broad opaque ribbons.
