# ADR 0010: One Active Run Per Checkout

- Status: Accepted
- Date: 2026-11-01
- Owners: Team
- Related: `docs/adr/0009-hook-governed-loop.md`, `.github/scripts/agentic_engine.py`, `.github/roles/orchestration-policy.json`, `docs/runbooks/agentic-engine.md`

## Context

A run's write set bounds which files an agent may change. Two live runs in one checkout each hold a different write set, so the gate has to answer a question it cannot: whose tree is this?

The engine already permits a call when **any** active run permits it, and scopes the decision to a run whose `owner` matches the caller. That keeps a second run from freezing the session, but it does not make the runs safe. They still share one working tree, one git index, and one branch. Run A can commit files run B is mid-way through, and run B can stage a half-finished edit under a message that describes something else. Neither run is denied, and nothing in either history records that the other existed.

Three options were considered.

**Give each run a git worktree.** `git worktree add` is cheap, and it would separate the trees. It was probed rather than assumed: a worktree was created at `.agentic/worktrees/probe`, and a write to `app/README.md` **inside that worktree** was submitted to the gate. It was denied, naming `.agentic/worktrees/probe/app/readme.md` as outside the run's write set, because the path resolver strips only the main repository root. The deeper problem is upstream of the resolver: an agent session's working directory is chosen by the host, not by the engine, so the engine cannot move a running session into a worktree. A worktree per run would need the host to start the session there, which is outside this repository's control. The primitive is available; the benefit is unreachable.

**Let the git index lock arbitrate.** It does not. `git commit` takes the lock for milliseconds; the collision happens across minutes of editing, and the index will happily accept one run's `git add` of another run's file.

**Refuse the second run.** This is a constraint on how work is scheduled rather than a mechanism, and it costs nothing when it holds: one run per checkout is how the loop is meant to be used.

## Decision

A run may not open while another run is active in the same state directory, unless the caller passes `--force-parallel`.

The check lives in `_init_with_task`, so `init` and `start` share it. Same-run-id re-initialisation is exempt, because that path is already guarded by the rule that a live run cannot be replaced. Unreadable state files are skipped individually: a half-written file must not stop all work starting, and it must not hide a live run beside it.

`--force-parallel` is not a safety mechanism. It exists for a checkout that has genuinely been isolated, and it says in the run's own terms that the caller accepts the shared-tree risk.

## Consequences

- A second `start` in a live checkout fails with a message naming the blocking run and the escape hatch. The engine suite asserts the refusal, the escape, the terminal-stage case, and both corrupt-file cases.
- Tests and validators that deliberately run two live runs pass `--force-parallel`, which turns an implicit assumption into a written one. The hook validators build their two fixtures in separate state directories and need no change.
- Parallel delivery needs separate clones or worktrees driven by separate sessions. This repository cannot offer that from inside a session, and says so instead of pretending otherwise.
- The write gate still uses the union of active runs, so a forced second run degrades to the pre-existing behaviour rather than a new one.

## Amendment (2026-11-01): Worktree Probe Evidence

The probe that decided against worktrees used the real gate rather than a reading of it.

```
git worktree add .agentic/worktrees/probe --detach
check-tool  toolName=edit  filePath=app/README.md   (submitted from inside the worktree)
-> deny: write outside the declared write set for run wt: .agentic/worktrees/probe/app/readme.md
```

The path was resolved to a repository-relative form rooted at the main checkout, so the worktree path became part of the relative name and matched nothing. Fixing the resolver would make the paths agree, and would still leave the session in the main checkout, because the working directory belongs to the host. That is why the decision is a scheduling constraint rather than a path-handling fix.
