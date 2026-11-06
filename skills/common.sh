# Shared settings for the orchestration scripts. Sourced, not executed.
ORCH_STATE=${CLAUDE_ORCH_STATE:-$HOME/.local/state/claude-orch}
ORCH_THREADS=$ORCH_STATE/threads
ORCH_SCRATCH=${CLAUDE_ORCH_SCRATCH:-${TMPDIR:-/tmp}/claude-orch}
ORCH_SKILLS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ORCH_NOTIFY=$ORCH_SKILLS/ntfy-updates/notify.sh
mkdir -p "$ORCH_THREADS" "$ORCH_SCRATCH"
