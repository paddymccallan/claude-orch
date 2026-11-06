#!/usr/bin/env bash
# Table of every orchestrated thread. Live view: watch -n 20 <path>/threads.sh
source "$(dirname "$0")/../common.sh"
now=$(date +%s)
printf '%-24s %-9s %-8s %-34s %s\n' THREAD STATE ELAPSED MODEL WORKTREE
for d in "$ORCH_THREADS"/*/; do
  [[ -f $d/pid ]] || continue
  n=$(basename "$d"); start=$(cat "$d/started")
  if kill -0 "$(cat "$d/pid")" 2>/dev/null; then state=running; end=$now
  elif [[ -f $d/exit ]]; then rc=$(cat "$d/exit"); state=$([[ $rc == 0 ]] && echo done || echo "failed:$rc"); end=$(cat "$d/ended")
  else state=killed; end=$now; fi
  [[ -f $d/reviewed ]] && state="$state*"
  printf '%-24s %-9s %-8s %-34s %s\n' "$n" "$state" "$(( (end-start)/60 ))m" "$(cat "$d/model")" "$(cat "$d/worktree")"
done
