#!/usr/bin/env bash
# Model-free, detached test runner: saves the orchestrator's tokens. Writes a summary and sends an ntfy.
# Usage: runtests.sh <name> <cmd...>     e.g. runtests.sh feat-x 'cd ~/code/app-feat-x && npm test'
# Output: $CLAUDE_ORCH_SCRATCH/verify/<name>.{log,txt,exit}   (read only the .txt; wait on .exit)
set -uo pipefail
source "$(dirname "$0")/../common.sh"
[[ $# -ge 2 ]] || { sed -n '2,4p' "$0"; exit 2; }
name=$1; shift; cmd="$*"
mkdir -p "$ORCH_SCRATCH/verify"; out=$ORCH_SCRATCH/verify/$name; rm -f "$out.exit"
setsid nohup bash -c '
  start=$(date +%s); bash -c "$1" > "$2.log" 2>&1; rc=$?
  { echo "cmd: $1"; echo "rc=$rc  duration=$(( $(date +%s)-start ))s"
    grep -E "✘|passed|failed|flaky|skipped|^ℹ (tests|pass|fail)|^Ran |^OK|^FAILED|Tests:|error" "$2.log" | tail -40; } > "$2.txt"
  echo "$rc" > "$2.exit"
  "$4" -p low -g test_tube -t "Tests $3 rc=$rc" "$(head -c 600 "$2.txt")" || true
' _ "$cmd" "$out" "$name" "$ORCH_NOTIFY" </dev/null >/dev/null 2>&1 &
echo "started $name (pid $!) -> $out.txt"
