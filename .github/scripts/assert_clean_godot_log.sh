#!/usr/bin/env bash
set -euo pipefail

log_file="${1:?usage: assert_clean_godot_log.sh <log-file>}"
critical_pattern='SCRIPT ERROR|Parse Error|Failed to load script|Failed loading (resource|scene)|Attempted to assign|Cannot assign contents'

if grep -En "$critical_pattern" "$log_file"; then
  echo "Critical Godot load or parse error detected in $log_file" >&2
  exit 1
fi
