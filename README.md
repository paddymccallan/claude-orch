# Agent Orchestration Dashboard

A small Node.js web UI for visualising the running agents in the Claude Code / opencode orchestration setup.

It reads thread state from `~/.local/state/claude-orch/threads/*` (created by the `opencode-threads` skill), parses each thread's `log.jsonl`, checks PIDs and the heartbeat, and shows a live dashboard.

## Run

```bash
cd ~/agent-dashboard
npm start
# or
./run.sh
```

Then open http://localhost:4729 (override port with `PORT=...`).

## Features

- Live status of every thread: running / done / failed / killed, plus stalled detection
- Model, worktree, git branch, elapsed time, session id
- Token usage, cost, tool-call and step counts
- Latest agent message with copy button
- Recent tool calls and per-tool totals
- stderr tail and prompt preview
- Auto-refreshes every 8s without jarring re-renders (morphdom)
- Mobile-friendly responsive layout

## Data sources

- `~/.local/state/claude-orch/threads/<name>/{pid,started,ended,exit,model,worktree,session,log.jsonl,stderr.log,prompt.md}`
- `~/.local/state/claude-orch/status`
- `~/.local/state/claude-orch/heartbeat.pid`