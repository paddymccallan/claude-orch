---
name: opencode-threads
description: Launch, track, wait on and review detached opencode worker threads running in git worktrees. Use when orchestrating and delegating tasks to opencode agents.
---

# opencode worker threads

Scripts live next to this file (`~/.claude/skills/opencode-threads/`). State lives in `${CLAUDE_ORCH_STATE:-~/.local/state/claude-orch}/threads/<name>/`: `prompt.md`, `log.jsonl`, `stderr.log`, `pid`, `exit`, `session`, `model`, `worktree`.

| Step | Command |
|---|---|
| Make a worktree | `mkworktree.sh <repo> <branch> [base=main] [suffix]` → prints the new dir (`<repo>-<suffix>`). Gitignored inputs listed in `<repo>/.orch-links` are symlinked in. |
| Launch a thread | `spawn.sh <name> <worktree> <model> <prompt_file>`. It runs detached with setsid/nohup, so it survives your session ending, and sends an ntfy on exit. |
| Status | `threads.sh` (`*` after the state = reviewed) |
| Wait | Run `wait.sh` **as a background command**. It returns when an unreviewed thread exits or the user sends an ntfy message. Don't poll. |
| Run tests | `runtests.sh <name> '<cmd>'`. It's model-free and detached; read `$CLAUDE_ORCH_SCRATCH/verify/<name>.txt` once `<name>.exit` exists. |
| Follow-up | `spawn.sh <name> <worktree> <model> <new_prompt> "$(cat .../threads/<name>/session)"` continues the same opencode session; the old logs move to `roundN/`. |
| Mark handled | `touch .../threads/<name>/reviewed` |

Rules:
- One thread per worktree. Never point two threads at the same worktree or the same files.
- Write every prompt with the template in `agents/WORKER_PROMPT.md` of the claude-orch repo (objective, scope, acceptance criteria, deliverables, handover).
- Read the last text message in `log.jsonl` and the git diff, not the whole log, to save tokens.
- Threads use the shared opencode service, so the user can watch them in the opencode TUI / `opencode session list` or in the claude-orch dashboard.
