#!/usr/bin/env bash
# Periodic "still alive" notification listing running threads plus the orchestrator's status line.
# Runs independently of Claude, so if heartbeats stop, the machine or session died.
# Usage: heartbeat.sh [interval_seconds=1800] [status_file=$CLAUDE_ORCH_STATE/status]
set -uo pipefail
source "$(dirname "$0")/../common.sh"
interval=${1:-1800} status_file=${2:-$ORCH_STATE/status}
echo $$ > "$ORCH_STATE/heartbeat.pid"
while true; do
  sleep "$interval"
  threads=$("$ORCH_SKILLS/opencode-threads/threads.sh" | awk '$2=="running"{print $1}' | paste -sd, -)
  count=$(printf '%s' "$threads" | tr ',' '\n' | grep -c . || true)
  summary=""; [[ -f $status_file ]] && summary=$(head -c 1500 "$status_file")
  "$ORCH_NOTIFY" -p low -g hourglass -t "Heartbeat" "running threads: ${count:-0}${threads:+ ($threads)}${summary:+
$summary}" || true
done
