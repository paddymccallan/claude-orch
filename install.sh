#!/usr/bin/env bash
# Install the orchestration skills into ~/.claude/skills and (optionally) set up ntfy.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
dest=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}
mkdir -p "$dest"
for s in opencode-threads ntfy-updates; do
  if [[ -e $dest/$s && ! -L $dest/$s ]]; then echo "! $dest/$s exists and is not a symlink; skipping"; continue; fi
  ln -sfn "$here/skills/$s" "$dest/$s"; echo "linked $dest/$s"
done
ln -sfn "$here/skills/common.sh" "$dest/common.sh"
mkdir -p "${CLAUDE_ORCH_STATE:-$HOME/.local/state/claude-orch}/threads"

for c in opencode git curl python3 node; do command -v $c >/dev/null || echo "! missing dependency: $c"; done

cfg=$HOME/.config/ntfy-claude/config
if [[ ! -f $cfg ]]; then
  read -rp "Set up ntfy push notifications? [Y/n] " a
  if [[ ${a:-y} =~ ^[Yy] ]]; then
    read -rp "ntfy server [https://ntfy.sh]: " srv
    topic=claude-$(head -c 18 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 20)
    mkdir -p "$(dirname "$cfg")"; umask 077
    printf 'NTFY_SERVER=%s\nNTFY_TOPIC=%s\n# NTFY_TOKEN=tk_...   (only for servers with access control)\n' "${srv:-https://ntfy.sh}" "$topic" > "$cfg"
    echo "wrote $cfg. Subscribe to topic '$topic' in the ntfy app (keep it private)."
    "$dest/ntfy-updates/notify.sh" -g tada -t "claude-orch" "ntfy is working" && echo "test notification sent"
  fi
fi
echo "Done. Next: add agents/ORCHESTRATOR.md to your project's CLAUDE.md (see WORKFLOW.md)."
