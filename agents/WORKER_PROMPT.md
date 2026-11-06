# Worker prompt template

Copy this for every task given to an opencode worker. Fill in every section; delete none.

```markdown
You are a worker agent in an orchestrated team. Work only inside this git worktree: <path>, branch <branch>.

## Objective
<One concrete outcome, in a sentence or two.>

## Context
- Relevant files: <paths>
- Prior findings / docs: <paths or summary>
- Known pitfalls: <...>

## Scope
- You may change: <files / directories / subsystem>
- Do NOT change: <files>, test expectations (unless the task says so), CI config, lockfiles, anything outside this worktree.

## Required investigation (before coding)
<What must be confirmed first, or "none".>

## Deliverables
- Code: <...>
- Tests: <new or updated tests that prove the behaviour>
- Docs: <file to update>

## Acceptance criteria
- [ ] <observable check, e.g. `npm test` passes with the new test X>
- [ ] <...>

## Rules
- Commit your work to this branch with clear messages. Do not merge, rebase onto other branches, or push.
- Don't weaken, skip or delete tests to make them pass. Don't leave placeholder or stub logic without flagging it.
- If you hit a blocker you can't resolve with evidence, stop and report it. Don't guess.
- Don't stop while long commands are still running in the background; wait for them.

## Handover (your final message)
1. What you did (files changed, commits).
2. Exact test commands run and their summary lines, copied verbatim.
3. What is NOT done / limitations / anything faked or approximated.
4. What the next agent needs to know.
```

**Researcher variant:** replace *Deliverables* with "a findings document at `docs/research/<topic>.md` with evidence (file/line refs, commands, outputs), the recommended implementation, and verification fixtures. No production code."
