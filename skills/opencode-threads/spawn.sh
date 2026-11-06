#!/usr/bin/env bash
# Launch an opencode worker thread fully detached (survives the Claude session ending).
# Usage: spawn.sh <name> <worktree_dir> <model> <prompt_file> [session_id]
#   session_id: continue an existing opencode session (follow-up round); previous logs are rotated.
# Sends an ntfy when the thread exits. State: $CLAUDE_ORCH_STATE/threads/<name>/
set -euo pipefail
source "$(dirname "$0")/../common.sh"
[[ $# -ge 4 ]] || { sed -n '2,5p' "$0"; exit 2; }
name=$1 wt=$(realpath "$2") model=$3 prompt=$(realpath "$4") session=${5:-}
dir=$ORCH_THREADS/$name
[[ -f $dir/pid ]] && kill -0 "$(cat "$dir/pid")" 2>/dev/null && { echo "thread $name already running"; exit 1; }
mkdir -p "$dir"
if [[ -f $dir/exit ]]; then
  n=$(ls "$dir" | grep -c "^round" || true); mkdir -p "$dir/round$n"
  mv "$dir"/{log.jsonl,stderr.log,exit,ended,prompt.md} "$dir/round$n/" 2>/dev/null || true
  rm -f "$dir/reviewed"
fi
printf '%s\n' "$wt" > "$dir/worktree"; printf '%s\n' "$model" > "$dir/model"
cp "$prompt" "$dir/prompt.md"; date +%s > "$dir/started"
cd "$wt"
setsid nohup bash -c '
  opencode run --auto --title "$0" -m "$1" ${4:+-s "$4"} --format json "$(cat "$2/prompt.md")" > "$2/log.jsonl" 2> "$2/stderr.log"
  rc=$?; echo $rc > "$2/exit"; date +%s > "$2/ended"
  sid=$(grep -om1 "\"sessionID\":\"[^\"]*\"" "$2/log.jsonl" | cut -d\" -f4 || true)
  [[ -n $sid ]] && echo "$sid" > "$2/session"
  if [[ $rc -eq 0 ]]; then "$3" -g white_check_mark -t "Thread done: $0" "$0 ($1) finished, awaiting review" || true
  else "$3" -p high -g warning -t "Thread failed: $0" "$0 ($1) exited $rc, see stderr.log" || true; fi
' "$name" "$model" "$dir" "$ORCH_NOTIFY" "$session" </dev/null >/dev/null 2>&1 &
echo $! > "$dir/pid"
echo "spawned $name (pid $!) in $wt with $model"
