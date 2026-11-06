#!/usr/bin/env bash
# Send a push notification via ntfy. Silently does nothing if ntfy isn't configured.
# Usage: notify.sh [-p priority] [-t title] [-g tags] "message"
#   priority: min|low|default|high|urgent   tags: comma-separated ntfy tags / emoji names
set -euo pipefail
cfg=${NTFY_CONFIG:-$HOME/.config/ntfy-claude/config}
[[ -f $cfg ]] || exit 0
source "$cfg"
priority=default title="Claude orchestrator" tags=robot
while getopts "p:t:g:" opt; do
  case $opt in p) priority=$OPTARG ;; t) title=$OPTARG ;; g) tags=$OPTARG ;; *) exit 2 ;; esac
done
shift $((OPTIND - 1))
curl -fsS --max-time 15 ${NTFY_TOKEN:+-H "Authorization: Bearer $NTFY_TOKEN"} \
  -H "Title: $title" -H "Priority: $priority" -H "Tags: claude,$tags" \
  -d "${*:-(no message)}" "$NTFY_SERVER/$NTFY_TOPIC" >/dev/null
