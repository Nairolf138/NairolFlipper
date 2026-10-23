"""Embed the actually tested checkout and the PR source identity, not credentials."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def stamp(root: Path, source_commit: str, run_number: str, workflow_url: str) -> dict:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    source_commit = source_commit or commit
    if not all(re.fullmatch(r"[0-9a-f]{40}", sha) for sha in (commit, source_commit)):
        raise ValueError("Build identity must use full commit SHAs")
    payload = {
        "commit": commit,
        "source_commit": source_commit,
        "run_number": run_number,
        "workflow_url": workflow_url,
        "qualification": "device_playtest_pending",
    }
    (root / "data/build_info.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-commit", default="")
    parser.add_argument("--run-number", default="local")
    parser.add_argument("--workflow-url", default="")
    args = parser.parse_args()
    stamp(Path(__file__).resolve().parents[2], args.source_commit, args.run_number, args.workflow_url)
