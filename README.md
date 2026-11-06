# claude-orch

**Claude Code orchestrates a team of cheap opencode worker agents.** Claude plans, delegates, reviews and merges. Workers run detached in their own git worktrees, so they keep going if Claude's session ends or hits a usage limit. You get push notifications on your phone (and can reply), and a live dashboard shows every agent.

```
            you (phone: ntfy)  ◀──── milestones / blockers / heartbeat
                 │  replies                    ▲
                 ▼                             │
   ┌──────────────────────────┐   spawn.sh     │      ┌─────────────────────┐
   │ Claude Code: orchestrator│ ─────────────▶ worker │ opencode run (detached)
   │ plans · reviews · merges │ ◀── wait.sh ── exits  │ one git worktree each│
   └──────────────────────────┘                       └─────────────────────┘
                 │ runtests.sh (model-free)                    │
                 ▼                                             ▼
           test summaries            ~/.local/state/claude-orch/threads/  ──▶ dashboard :4729
```

## What's here

| Path | What it is |
|---|---|
| [`WORKFLOW.md`](WORKFLOW.md) | **Start here.** Setup and the day-to-day loop. |
| [`agents/ORCHESTRATOR.md`](agents/ORCHESTRATOR.md) | Instructions for Claude as orchestrator; goes in your project's `CLAUDE.md`. |
| [`agents/WORKER_PROMPT.md`](agents/WORKER_PROMPT.md) | Template for every task prompt sent to a worker. |
| `skills/opencode-threads/` | Claude Code skill + scripts: worktrees, spawn, status, wait, test runner. |
| `skills/ntfy-updates/` | Claude Code skill + scripts: notify, heartbeat, read your replies. |
| `server.js`, `public/` | The dashboard (zero dependencies, Node ≥ 18). |
| `install.sh` | Symlinks the skills into `~/.claude/skills` and sets up ntfy. |

## Quick start

```bash
git clone https://github.com/paddymccallan/claude-orch.git ~/claude-orch && \
  cd ~/claude-orch && ./install.sh && \
  npm start          # dashboard → http://localhost:4729
```

Then follow [`WORKFLOW.md`](WORKFLOW.md).

## Dashboard

- Live status for every thread (running / done / failed / killed), with stall detection (no log activity for 5 minutes)
- Model, worktree, branch (+ dirty count), elapsed time, session ID
- Tokens, cost, tool-call and step counts, per-tool totals
- Latest agent message (with copy button), recent tool calls, stderr tail, prompt
- Heartbeat alive/dead and the orchestrator's status line
- Refreshes every 8 s without flicker (morphdom), mobile-friendly, finished threads collapsed

Env vars: `PORT` (default `4729`), `HOST` (default `127.0.0.1`; use `HOST=0.0.0.0` to view from your phone on the LAN, but note it exposes prompts and logs to that network), `CLAUDE_ORCH_STATE` (default `~/.local/state/claude-orch`).

## License

MIT
