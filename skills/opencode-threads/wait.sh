#!/usr/bin/env bash
# Block until something needs the orchestrator: an unreviewed thread has exited, or the user sent an ntfy message.
# Prints the reason(s) and exits. Run it as a background command so Claude is re-invoked when it returns.
# Mark a thread handled with:  touch $CLAUDE_ORCH_STATE/threads/<name>/reviewed
source "$(dirname "$0")/../common.sh"
inbox=$ORCH_SKILLS/ntfy-updates/inbox.sh
while true; do
  hit=0
  for d in "$ORCH_THREADS"/*/; do
    [[ -f $d/exit && ! -f $d/reviewed ]] && { echo "EXITED: $(basename "$d") rc=$(cat "$d/exit")"; hit=1; }
  done
  msgs=$("$inbox" --peek 2>/dev/null)
  [[ -n $msgs ]] && { echo "USER NTFY:"; echo "$msgs"; hit=1; }
  [[ $hit == 1 ]] && exit 0
  sleep "${WAIT_INTERVAL:-60}"
done
