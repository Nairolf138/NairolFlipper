"""Validate distributable identity and write a source-backed candidate manifest.

Run only after every automated gate succeeds. Never certify a physical device.
"""
import hashlib
import json
from pathlib import Path
import zipfile

CAPTURE_STATES = (
    "menu", "ready", "pause", "report", "lit_stage", "final_show", "effects_off",
    "rider_warm_ramp", "rider_cold_ramp", "rider_universe_orbit",
)
CAPTURE_SIZES = ((540, 960), (1080, 1920), (768, 1024))


def package(root: Path) -> dict:
    build = root / "build"
    identity = json.loads((root / "data/build_info.json").read_text(encoding="utf-8"))
    apk = build / "android/nairolflipper-debug.apk"
    with zipfile.ZipFile(apk) as archive:
        candidates = [name for name in archive.namelist() if name.endswith("/data/build_info.json")]
        if len(candidates) != 1 or json.loads(archive.read(candidates[0])) != identity:
            raise ValueError("APK is missing the exact tested build identity")
    required = [
        apk, build / "web/index.html", build / "web/index.pck", build / "web/index.wasm",
        build / "windows/NairolFlipper.exe", build / "windows/NairolFlipper.pck",
        build / "visuals/render_metrics.json",
    ]
    captures = [
        build / "visuals" / f"{state}_{width}x{height}.png"
        for state in CAPTURE_STATES for width, height in CAPTURE_SIZES
    ]
    artifacts = []
    for path in required + captures:
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f"Missing or empty artifact: {path.relative_to(root)}")
        artifacts.append({
            "path": str(path.relative_to(build)),
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    payload = {
        "schema_version": 1,
        "version": (root / "VERSION").read_text(encoding="utf-8").strip(),
        "build": identity,
        "automated_checks": "passed",
        "device_playtest": "pending",
        "alpha_qualified": False,
        "artifacts": artifacts,
    }
    destination = build / "qualification"
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "manifest.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    (destination / "ALPHA_QUALIFICATION.md").write_bytes((root / "docs/ALPHA_QUALIFICATION.md").read_bytes())
    return payload


if __name__ == "__main__":
    package(Path(__file__).resolve().parents[2])
