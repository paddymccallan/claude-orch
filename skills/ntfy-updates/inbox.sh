#!/usr/bin/env bash
# Read messages the USER posted to the ntfy topic (anything not tagged "claude").
# Prints new messages since the last call (time<TAB>title<TAB>message) and advances the cursor.
# Usage: inbox.sh [--peek]     (--peek doesn't advance the cursor)
set -euo pipefail
source "$(dirname "$0")/../common.sh"
cfg=${NTFY_CONFIG:-$HOME/.config/ntfy-claude/config}
[[ -f $cfg ]] || exit 0
source "$cfg"
state=$ORCH_STATE/ntfy-inbox.cursor
since=$(cat "$state" 2>/dev/null || echo 10m)
out=$(curl -fsS --max-time 20 ${NTFY_TOKEN:+-H "Authorization: Bearer $NTFY_TOKEN"} \
  "$NTFY_SERVER/$NTFY_TOPIC/json?poll=1&since=$since") || exit 0
NTFY_OUT=$out STATE=$state PEEK=${1:-} python3 - <<'PY'
import json, os, datetime
last = None
for l in os.environ["NTFY_OUT"].splitlines():
    if not l.strip(): continue
    m = json.loads(l)
    if m.get("event") != "message": continue
    last = m["id"]
    if "claude" in (m.get("tags") or []): continue
    t = datetime.datetime.fromtimestamp(m["time"]).strftime("%H:%M")
    print(f'{t}\t{m.get("title","")}\t{m.get("message","")}')
if last and os.environ["PEEK"] != "--peek":
    open(os.environ["STATE"], "w").write(last)
PY
