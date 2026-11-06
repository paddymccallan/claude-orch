# Workflow: Claude as orchestrator, opencode as workers

## 1. Prerequisites

- [Claude Code](https://claude.com/claude-code)
- [opencode](https://opencode.ai) with at least one provider logged in (`opencode auth login`), and `opencode models` showing the models you want
- `git`, `bash`, `curl`, `python3`, `node` ≥ 18, `setsid` (util-linux; on macOS install it via `brew install util-linux` or replace `setsid nohup` with `nohup`)
- Optional: the [ntfy](https://ntfy.sh) app on your phone

## 2. Install

```bash
git clone https://github.com/paddymccallan/claude-orch.git ~/claude-orch
cd ~/claude-orch && ./install.sh
```

This symlinks `opencode-threads` and `ntfy-updates` into `~/.claude/skills/`. If you say yes to ntfy, it writes `~/.config/ntfy-claude/config` with a random private topic and sends a test message. Subscribe to that topic in the ntfy app. Anyone who knows the topic can read it and post to it, so keep it secret (or use a self-hosted server with `NTFY_TOKEN`).

Optional: start the opencode background service so you can watch workers live in the opencode TUI. Threads also show up in the dashboard either way.

## 3. Configure your project

1. Copy `agents/ORCHESTRATOR.md` into your project (or reference it) from the project's `CLAUDE.md`:
   ```markdown
   @/home/you/claude-orch/agents/ORCHESTRATOR.md

   ## Project goal
   <what "done" looks like>

   ## Tests
   - unit: `npm test`
   - e2e: `npx playwright test`
   ```
2. Edit the **Agents** table (your model IDs), the **concurrency cap** and the **Authority** section (whether Claude may merge or push without asking).
3. If worktrees need gitignored files (`node_modules`, `.env`, local data), list them one per line in `<repo>/.orch-links`.
4. Keep a `ROADMAP.md` (or similar) in the repo. Claude updates it, and it's how a new session picks up where the last one left off.

## 4. Run it

In the project, start Claude Code and say something like:

> Orchestrate: work through ROADMAP.md using opencode workers. Send me ntfy updates. You may merge verified work but don't push.

Claude will then:

1. Read the roadmap and repo state and check for leftover threads (`threads.sh`).
2. Plan small independent tasks. For each: `mkworktree.sh <repo> task/<name>`, write a prompt from `WORKER_PROMPT.md`, then `spawn.sh <name> <worktree> <model> <prompt>`.
3. Start the heartbeat and send a "started" ntfy.
4. Run `wait.sh` in the background. It doesn't spend tokens while the workers run.
5. When a worker exits: read its handover and diff, run tests via `runtests.sh`, then accept and merge, send it back with a follow-up in the same session, or reject.
6. Update the roadmap and status line, launch the next task, and repeat.

### While it runs

| You want to… | Do |
|---|---|
| See everything | `npm start` in `~/claude-orch` → http://localhost:4729 |
| Quick table | `~/.claude/skills/opencode-threads/threads.sh` |
| Tell Claude something from your phone | Post to the ntfy topic. `wait.sh` wakes Claude and it treats the message as an instruction. |
| Know it's still alive | Heartbeat every 30 min. If heartbeats stop, the machine or session died. |
| Resume after Claude stops | Start Claude again and say "resume orchestration". Workers kept running; Claude reviews whatever exited. |

## 5. Tips from real use

- **Cap concurrency.** Each worker may run dev servers, browsers and test suites. On 16 GB of RAM, more than ~4 workers (including test runs) ran the machine out of memory and killed the orchestrator's background watchers. Allow at most 2 browser-test runs at once.
- **Don't let Claude run test suites itself.** Use `runtests.sh` (no model, detached) and have Claude read only the summary. LLM "verifier" agents often end their turn before the tests finish and never write a report.
- **Pre-approve fallbacks.** Tell Claude which free or cheaper models it may switch to on a usage limit without asking, and have it ntfy you when it switches.
- **Clean scratch space.** Workers' temp output piles up. Delete a task's scratch directory after merging it.
- **One tool, one agent.** Anything stateful and shared (an emulator, a GUI app, a debugger) should be driven by one worker at a time.
- **Specific prompts pay off.** Most wasted rounds come from missing acceptance criteria or scope. Fill in the whole template.

## File layout at runtime

```
~/.config/ntfy-claude/config              NTFY_SERVER, NTFY_TOPIC (private)
~/.local/state/claude-orch/
  status                                  one-line orchestrator status (shown in heartbeat + dashboard)
  heartbeat.pid
  threads/<name>/                         prompt.md log.jsonl stderr.log pid started ended exit
                                          model worktree session reviewed round0/ round1/ …
${TMPDIR:-/tmp}/claude-orch/verify/       runtests.sh output: <name>.log .txt .exit
```
