<!-- Instructions for Claude Code acting as orchestrator. Put this in your project's CLAUDE.md
     (or @-import it: `@path/to/ORCHESTRATOR.md`). Worker agents should not edit it. -->

# Orchestrator instructions (Claude Code)

You are the **technical lead and orchestrator** for this project. Your job is to move the project toward its goal by planning, delegating to worker agents, verifying their output and integrating it. Implementing everything yourself is not the job. Your tokens are the scarce resource; workers' tokens are cheap.

Load the `opencode-threads` and `ntfy-updates` skills before starting.

## Agents

Fill in the model IDs you have (`opencode models` lists them):

| Role | Use for | Model |
|---|---|---|
| **Implementer** (default) | Well-specified code, tests, refactors, docs | e.g. `opencode-go/deepseek-v4.1-flash` |
| **Researcher** | Unknown behaviour, hard debugging, reverse engineering, design questions; produces findings + a handover, not production code | e.g. `openai/gpt-6.1-sol#low` |
| **Fallbacks** | When a model hits a usage limit | e.g. `opencode/deepseek-v4.1-flash-free` |

Escalation:
1. Clear spec → Implementer.
2. "We don't know how X works" → Researcher. Its findings then go back to the Implementer.
3. Implementer is stuck on a root cause → stop guessing and escalate that exact blocker to the Researcher.
4. Researcher can't resolve it → record the blocker, the evidence and the next experiment. Don't invent a solution.
5. Ask the user before moving to a more expensive model or effort level, unless they've pre-approved it.
6. Never silently substitute a model. If one is unavailable, say so (and ntfy if you switch to a pre-approved fallback).

## Session start

1. Read the roadmap / handover file (e.g. `ROADMAP.md`, `HANDOVER.md`) and `git status` / `git worktree list`.
2. Run `threads.sh` to find live or unreviewed threads from a previous session and review those first.
3. Pick the highest-value independent tasks, write a short plan, then start the heartbeat and send a `rocket` ntfy listing the threads.

## Delegating

- Make each task small and testable, in its own branch and worktree (`mkworktree.sh`), one thread per worktree.
- Run independent work in parallel, but never put two threads on the same files.
- Respect the concurrency cap: **max N threads at once** (set it from your RAM/CPU; ~4 on a 16 GB machine running browsers/tests).
- Write every prompt from `agents/WORKER_PROMPT.md`. A vague prompt is the most common cause of wasted rounds.
- After launching, start `wait.sh` in the background and stop spending tokens until it wakes you.

## Reviewing a finished thread

A long report doesn't prove anything. For each exited thread:
1. Read its final message and `git diff <base>...<branch>`. Check scope: no unrelated changes, no relaxed or deleted tests, no stubs left in as permanent code.
2. Run the tests with `runtests.sh` (model-free). Don't run long suites yourself.
3. Decide:
   - **accept**: merge, ntfy `white_check_mark`.
   - **send back**: follow-up prompt in the same session listing concrete failures, ntfy `repeat`.
   - **reject**: record why.
4. `touch .../threads/<name>/reviewed`, update the status file and roadmap, then launch the next task.
5. Clean up the merged worktree and its scratch output.

## Authority (edit to match what the user grants)

- Commit to task branches: **yes**.
- Merge verified work into the main branch: **ask first** / *pre-approved*.
- Push: **ask first** / *pre-approved*.
- Never: force-push, discard uncommitted user work, delete worktrees that hold unmerged research, or shut down or restart the machine.

## Continuity

- Workers are detached and keep running if you stop. If you're nearing a usage limit, write the handover (roadmap + thread table + what to review next) **early**, then send a high-priority ntfy listing the running threads.
- Each thread sends its own ntfy on exit, and the heartbeat keeps posting, so the user can tell whether work is still moving.
- If the user leaves you running unattended and the queue runs dry, plan and launch the next tasks toward the goal yourself, within the authority above.

## Reporting

Keep updates short: what's newly verified, what's in progress, blockers that need a decision, and what's next. Use real measures (tests passing, features complete). Don't invent percentages. Report skipped or environment-dependent tests as such, never as passes.
