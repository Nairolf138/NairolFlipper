"""Candidate packaging checks; these do not stand in for a device playtest."""
import importlib.util
import json
from pathlib import Path
import tempfile
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / ".github/scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_build_identity_is_explicit_and_never_certifies_a_device():
    module = load_script("stamp_build")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        (root / "data").mkdir()
        with patch.object(module.subprocess, "check_output", return_value="a" * 40):
            payload = module.stamp(root, "b" * 40, "34", "https://github.com/example/project/actions/runs/34")
            assert payload["commit"] == "a" * 40
            assert payload["source_commit"] == "b" * 40
            assert payload["qualification"] == "device_playtest_pending"
            assert json.loads((root / "data/build_info.json").read_text()) == payload
            try:
                module.stamp(root, "not-a-commit", "34", "")
            except ValueError:
                pass
            else:
                raise AssertionError("Invalid source identity was accepted")


def test_candidate_pack_requires_the_exported_apk_identity_and_complete_files():
    module = load_script("package_qualification")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        identity = {"source_commit": "a" * 40, "qualification": "device_playtest_pending"}
        for relative in ("data", "docs", "build/android", "build/web", "build/windows", "build/visuals"):
            (root / relative).mkdir(parents=True, exist_ok=True)
        (root / "data/build_info.json").write_text(json.dumps(identity))
        (root / "VERSION").write_text("0.1.0-alpha.1")
        (root / "docs/ALPHA_QUALIFICATION.md").write_text("Device checks pending")
        apk = root / "build/android/nairolflipper-debug.apk"
        with zipfile.ZipFile(apk, "w") as archive:
            archive.writestr("assets/data/build_info.json", json.dumps(identity))
        for relative in ("web/index.html", "web/index.pck", "web/index.wasm", "windows/NairolFlipper.exe", "windows/NairolFlipper.pck", "visuals/render_metrics.json"):
            (root / "build" / relative).write_bytes(b"nonempty packaging fixture")
        for state in module.CAPTURE_STATES:
            for width, height in module.CAPTURE_SIZES:
                (root / "build/visuals" / f"{state}_{width}x{height}.png").write_bytes(b"packaging fixture, not an image assertion")
        result = module.package(root)
        assert result["device_playtest"] == "pending" and result["alpha_qualified"] is False
        assert all(len(entry["sha256"]) == 64 and entry["bytes"] > 0 for entry in result["artifacts"])
        missing = root / "build/visuals/pause_768x1024.png"
        missing.unlink()
        try:
            module.package(root)
        except ValueError:
            pass
        else:
            raise AssertionError("Incomplete tablet capture set was accepted")
        missing.write_bytes(b"packaging fixture")
        with zipfile.ZipFile(apk, "w") as archive:
            archive.writestr("assets/data/build_info.json", json.dumps({"source_commit": "wrong"}))
        try:
            module.package(root)
        except ValueError:
            pass
        else:
            raise AssertionError("APK identity drift was accepted")
