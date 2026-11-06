---
name: ntfy-updates
description: Send the user push notifications via ntfy during long-running orchestration (milestones, blockers, failures, completion), run a background heartbeat, and read replies the user sends back. Use whenever running multi-step orchestration or a long background task the user isn't watching.
---

# ntfy updates

Config: `~/.config/ntfy-claude/config` defines `NTFY_SERVER`, `NTFY_TOPIC` (and optionally `NTFY_TOKEN`). The topic is a secret: never print it in commits, docs or other services. If the file is missing, every script here silently does nothing.

```
~/.claude/skills/ntfy-updates/notify.sh [-p priority] [-t title] [-g tags] "message"
```

| Event | Priority | Tags |
|---|---|---|
| Orchestration started (plan + thread list) | default | `rocket` |
| Thread accepted / merged | default | `white_check_mark` |
| Thread sent back for fixes | low | `repeat` |
| **Blocker: needs the user's decision** | high | `warning` |
| Unrecoverable failure (auth, rate limit, crash) | urgent | `rotating_light` |
| Whole goal done | high | `tada` |

- Keep each message to one or two lines, and name the thread or branch and the concrete reason.
- Send the blocker notification **before** you stop to wait. Never stall silently.
- Notify at milestones only, not on routine steps. If `notify.sh` fails, mention it in the terminal and carry on.

## Heartbeat

At the start of an orchestration:
```
setsid nohup ~/.claude/skills/ntfy-updates/heartbeat.sh 1800 >/dev/null 2>&1 &
```
Keep `~/.local/state/claude-orch/status` up to date with one line (e.g. "2/5 tasks merged; feat-x in review"). Stop it at the end with `kill $(cat ~/.local/state/claude-orch/heartbeat.pid)`.

## Replies from the user

The user can post to the same topic from the ntfy app. `inbox.sh` prints messages not tagged `claude` and advances a cursor (`--peek` leaves the cursor where it is). `opencode-threads/wait.sh` also wakes on these. Treat them as instructions from the user.
