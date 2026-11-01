# Hooks Runbook

## Purpose

Hooks enforce deterministic guardrails and create an audit trail for agent tool usage.

## Runtime Contract

`.github/hooks/*.json` is the harness hook location, so `agent-policy.json` is read by the runtime, not just by this repository's scripts. Three properties of that contract decide whether the policy actually runs:

- **Input arrives on stdin as JSON.** A command hook receives `toolName` and `toolArgs` on standard input. Command-line arguments are not populated by the harness. The scripts here also accept argv so they can be exercised by hand, but fixtures must use stdin or they validate a path production never takes.
- **`preToolUse` is fail-closed.** Exit `2`, a crash, or any non-zero exit denies the tool call. A deny decision is returned as `{"permissionDecision":"deny","permissionDecisionReason":"..."}` on stdout **and** exit `2`, so the reason reaches the agent and the call is still denied if stdout is ignored.
- **Timeouts are fail-open.** A hook that exceeds `timeoutSec` is killed and the tool call proceeds through the normal permission flow. A slow hook is therefore the same as no hook, which is why every entry keeps a 10 second budget and the validator rejects anything above 30.
- **Only command text is scanned.** The payload for an edit tool carries the file content being written, so matching rules against the whole payload blocks any file that merely mentions a blocked pattern — which is most of this repository's documentation. The policy extracts `toolArgs.command` and matches rules against that alone; a payload with no command matches nothing and is allowed.
- **The Windows handler uses `powershell`, not `pwsh`.** `pwsh` is PowerShell 7 and a separate install; a machine without it cannot spawn the hook, and because `preToolUse` is fail-closed that denies every tool call. `powershell` ships with Windows. `-ExecutionPolicy Bypass` is scoped to the hook process so a restrictive default policy cannot fail the whole session.

A malformed hook item is dropped and logged; a bad top-level `version` rejects the whole file. Both failures disable the policy silently, so `check-hook-policy` asserts the shape rather than trusting it.

## Files

- Policy: `.github/hooks/agent-policy.json` (hook wiring only, `{ "version": 1, "hooks": { ... } }`)
- Rules: `.github/hooks/policy-rules.tsv`
- Session start: `.github/hooks/scripts/session-banner.{ps1,sh}`
- Pre-tool policy: `.github/hooks/scripts/pre-tool-policy.{ps1,sh}`
- Post-tool audit: `.github/hooks/scripts/audit-log.{ps1,sh}`

Each entry declares a `bash` and a `powershell` handler. The `.sh` scripts are the POSIX handler, not a WSL extra, and the two variants must stay behaviourally identical.

## Lifecycle

1. `sessionStart`: logs session metadata and prints the banner to stderr, using `sessionId` from the payload. When a run is active it also emits `{"additionalContext": "..."}` on stdout with the stage, objective, next action, write set, and required result.
2. `preToolUse`: extracts command text and blocks dangerous command patterns, then asks the engine whether the call is admissible.
3. `postToolUse`: appends timestamped audit records.
4. `agentStop`: asks the engine whether the active run may stop.

`agent-policy.json` defines the lifecycle wiring. `policy-rules.tsv` defines the blocklist data consumed by the pre-tool policy scripts.

## The Loop

`preToolUse` and `agentStop` together turn the engine into a control plane, not just a record. Nothing new has to run, and no credential is involved.

`sessionStart` completes the set: when a run is active it injects the stage, objective, next action, write set, and required result, so the agent starts knowing where it is instead of discovering it on the first refused turn end. That output is `{"additionalContext": "..."}` — top-level, because only that field is consumed for `sessionStart` and a wrapped one is ignored.

```
agent works -> preToolUse denies writes outside task.writeSet
             -> agentStop asks "is the stage satisfied?"
                  no  -> { decision: "block", reason: <required result schema> }
                  yes -> the turn ends
```

`agentStop` is what makes this a loop rather than a guardrail. When the engine reports an unfinished stage the hook refuses the turn end and returns the engine's own `requiredResult` schema as the reason, so the agent is told exactly what to produce next. The output is:

```json
{ "decision": "block", "reason": "Run <id> is at stage 'implement' ..." }
```

`decision` and `reason` are **top-level** fields for the Copilot harness. The `hookSpecificOutput` wrapper belongs to the legacy Local harness, and the Copilot harness ignores unsupported fields — so emitting the Local shape would silently allow a stop the hook meant to block.

Three properties keep it safe:

- **Inert without a run.** No `.agentic/state`, no subprocess, no behaviour change.
- **It blocks once, not forever.** `stop_hook_active` is true on the turn after a block, and the hook then allows the stop. Repeating the refusal would only burn credits.
- **A failure allows the stop.** A missing interpreter, a non-zero exit, or unparseable output all fall through to "allow", because a broken hook must not trap the agent in a loop.

Every invocation writes one line to `.github/hooks/logs/agent-stop.log`:

```json
{"at":"...","event":"agentStop","armed":true,"stopHookActive":false,"decision":"block"}
```

This is recorded even when no run is armed (`armed: false`, `decision: skipped`). Without it, "the hook never fired" and "the hook fired and its decision was ignored" are indistinguishable from the outside, which is exactly the state this hook sat in while it looked correct.

Observed on 2026-10-31 in a session that had the event configured at startup:

```
18:47:16  armed:true   stopHookActive:false  decision:block
18:49:10  armed:false  stopHookActive:true   decision:skipped
```

The first line is the block; the turn was refused and the reason reached the agent. The second is the next turn end, carrying `stop_hook_active: true` because the previous turn was blocked — which is what makes the hook yield instead of looping. The run was disarmed between the two lines, so the second decision reads `skipped` rather than `allow`.

Note that an empty stdin also produces a block, since a missing `stop_hook_active` reads as false. The first line therefore proves the event fired but not that the field is delivered; the second line is what proves delivery.

A blocked turn consumes AI credits, so the engine's repair budget and identical-failure escalation are the real bound. Once a run reaches `blocked`, `agentStop` stops objecting.

The engine owns both decisions. `check-tool` answers `preToolUse`; `check-stop` answers `agentStop`. Neither reimplements the other.

## Policy Metadata

The former `rolePolicyGuidance` and `logging` keys were removed from `agent-policy.json` when the file was brought into the harness schema. They are documentation, not configuration, and nothing consumed them programmatically.

- Role source of truth: `.github/roles/tool-access.json`.
- Execute-capable roles: `analysis`, `planning`, `implementation`. Command-pattern blocking matters most for these.
- `review` and `workflow-maintenance` are still subject to hooks but normally do not invoke execute tools, so use them as false-positive probes.
- The orchestration role is not execute-capable and is the only role holding `delegate-agent`; it never runs commands or edits files directly.
- Audit records are written to `.github/hooks/logs/agent-audit.log` as JSON lines.

## Blocked Patterns (Examples)

- `rm -rf`
- `del /s /q`
- `Remove-Item -Recurse -Force`
- `git reset --hard`
- `git checkout -- <path>`
- `git push --force` or `git push --force-with-lease`
- `curl | bash` (or `curl|sh`/`curl|pwsh`)
- `wget | sh`
- Remote content piped to `Invoke-Expression`
- `chmod -R 777`
- `git clean -f` (also `-fd`, `-fdx`, or `--force`)
- `git checkout .` or `git restore .` (discard-all working tree)
- `git stash drop` or `git stash clear`
- `git branch -D`
- `rmdir /s /q` or `rd /s /q`
- `docker compose down -v` (teardown with volume deletion)
- `docker volume prune` or `docker system prune`
- `git add .env` or staging common credential files (`.pem`, `.key`, `.npmrc`, `id_rsa`)
- Writing likely real secrets/tokens into `.env`, including common credential names such as `secret=`, `api_key=`, and cloud credential variables
- `pip install --trusted-host` or `pip install --index-url http://` (TLS bypass for package sources)
- `npm install --registry http://` (plain HTTP npm registry)
- Unapproved edits to core policy files when the command explicitly says the edit is unapproved

## What Hooks Can Enforce

- Block tool calls whose command string matches a deterministic unsafe pattern.
- Require safer alternatives for common destructive or supply-chain-risky commands.
- Bound which files an agent may change, by consulting the engine's write set.
- Refuse to end a turn while the engine reports an unfinished stage.
- Create audit records for tool usage when the runtime invokes the hooks.
- Deny by exit code, so the refusal holds even if the agent ignores the message.

## What Hooks Cannot Enforce

- They cannot understand every intent behind a command.
- They cannot protect tools or runtimes that do not invoke the hook lifecycle.
- They cannot block work when they are slow: timeouts fail open.
- They cannot judge intent. The engine gate below bounds *which files* may change, but a hook never sees a plan or a reason, only calls.
- They cannot replace human review for high-risk policy, MCP, credential, or deployment changes.
- They cannot guarantee secrets are absent from every external system or terminal output.
- They cannot be assumed to apply to a session started by a different client. The hook contract is per-harness, and that has not been verified for sessions created over the Agent Host Protocol.

## Engine Gate

`pre-tool-policy.{sh,ps1}` consults `agentic_engine.py` after the rule loop, and `agent-stop.{sh,ps1}` consults it on every turn end. Both are dormant unless a run exists:

```
.agentic/state missing        -> allow, no engine call at all
.agentic/state present        -> preToolUse: python agentic_engine.py check-tool
                                 agentStop : python agentic_engine.py check-stop
  tool not classified         -> allow, with a note; the write set is the real bound
  stage forbids the tool kind -> deny
  write outside the write set -> deny
  shell write outside set     -> deny, when the target can be named
  stage unfinished            -> block the turn end, with the required result
  no working interpreter      -> allow, with a warning on stderr
  engine fails for any reason -> allow, with a warning on stderr
```

Only the host payload on stdin reaches the engine. A hand invocation — `bash .github/hooks/scripts/pre-tool-policy.sh "git status --short"` — is checked by the rule layer alone, because it is a command being inspected by a person rather than a tool call from the harness. The shell twin once piped argv to the engine as well, so every hand invocation failed JSON parsing and was denied whenever a run existed, which made `check-hook-policy` unable to pass in the state a user is actually in: mid-run.

An unclassified tool allows because denying an unknown name is not a policy. That behaviour once denied every tool call in a live session, since the harness's real tool names shared nothing with the registry's examples. The write set is enforced from the tool arguments and again from git at `record` time, so an out-of-scope change is caught whatever the tool was called.

The asymmetry in the last two lines is deliberate. A `preToolUse` failure allows, because a governance control that cannot run must not brick the editor; the rule layer above has already run and still applies. An `agentStop` failure also allows, because a hook that cannot decide must not trap the agent. Neither direction should ever produce an unhandled exit code — anything other than `0` or `2` is reported by the harness as `hook errored` and treated as a denial for `preToolUse`.

Three properties make this safe to leave enabled:

- **Inert without a run.** No `.agentic/state`, no subprocess, no behaviour change, no latency cost.
- **Finished runs release the session.** Stages `done` and `blocked` are not active, so a completed run never locks anyone out or refuses a turn end.
- **A gate that cannot run allows the call.** The engine gate needs a working Python interpreter. If none is usable the gate switches itself off with a warning on stderr and the rule layer above still applies. Denying every tool call because an interpreter is missing does not make anything safer; it makes the whole policy get disabled, which is how this guardrail was lost the first time.

### When Every Tool Call Is Denied

That state is possible and it has one cause: the engine gate is returning a denial for every call. The fix takes seconds and needs no editor tools:

```powershell
Rename-Item .agentic agentic-disabled
```

Renaming the state directory makes the gate inert immediately; the next tool call succeeds. Rename it back to resume the run. Do not delete it — the run history is the evidence trail.

The same escape exists for the write-set gate specifically: a finished or `blocked` run stops restricting anything, so recording a blocking result also releases the session.

### Cost

The hook runs on every tool call, so its latency matters:

Measured on this repository's development machine, ten calls per row:

| layer | measured cost |
|---|---|
| bash handler, no state directory | ~45ms per call |
| bash handler, state present, no active run | ~60ms per call |
| bash handler, run active | ~300ms per call |
| PowerShell handler, no state directory | ~580-690ms per call |
| PowerShell handler, state present, no active run | ~640ms per call |
| PowerShell handler, run active | ~990ms per call |

The rule probe is the part that can be tuned and has been: 27 rules matched individually cost ~150ms because each is a separate `grep` process, while one combined alternation costs ~16ms. The shell walks the rules in file order only after the combined probe matches, so the first matching rule still wins and its reason is still the one reported.

The engine gate is skipped unless a run is in an active stage. Deciding that costs a few milliseconds because it reads the state files directly, and asking the engine costs two process spawns — the interpreter probe and the engine itself. Before that change a repository holding a single finished run paid ~310ms extra on every tool call, which is most tool calls in a session that has already shipped something. An unreadable state file is not treated as "no run": it falls back to the engine, which denies.

Two other things measured rather than assumed. `Get-Content` costs ~65ms more than `[IO.File]::ReadAllLines` over a noop baseline, so the rules are read directly. And `pwsh` 7 is *slower* here than Windows PowerShell 5.1 — 487ms against 377ms for the same script — so the handler is not the performance knob it looks like, and 5.1 stays for its guaranteed presence on Windows.

What remains is process startup: ~290ms for Windows PowerShell alone, plus roughly 190ms of .NET first-use inside the script that does not come back. Avoid adding work to these scripts; if a hook needs to do more, it should hand off rather than grow.

### Vocabulary Contract

The gate decides by tool name and by file path, so it is only as correct as its vocabulary. Both come from **observed payloads**, never from documentation.

Tool names the harness sends, recorded by the `postToolUse` hook:

| tool | kind |
| --- | --- |
| `powershell` | `execute` |
| `read_powershell` | `read` |
| `view` | `read` |
| `grep` | `search` |
| `glob` | `search` |
| `edit` | `edit` (write) |
| `create` | `edit` (write) |
| `skill` | `read` |
| `sql` | `read` |

`.github/roles/tool-access.json` `toolDefinitions.examples` documents capability roles for a different surface and shares no names with live traffic. It is still read, but it is a supplement, not the source.

Paths arrive **absolute** (`D:\repo\app\src\rng.js`, or `file:///d:/...`) while a write set is **repo-relative** (`app/src/rng.js`). Both are the same file, so the gate normalises the reported path against the repository root before comparing. A path outside the repository stays outside and is refused.

Two rules follow:

- **An unclassified tool is allowed**, with a reason. Denying it is how a vocabulary mismatch becomes a total lockout: if the gate recognises nothing, deny-on-unknown denies everything. The authoritative, name-independent check is the git-derived write set at `record` time.
- **A name or shape the gate has not seen is a gate bug, not a policy decision.** Add it to `HOST_TOOL_KINDS` and add a fixture, rather than relying on the allow fallback.

`check-hook-policy` asserts that every name in the table above classifies, and that a brand-new name is allowed. If the harness adds a tool, that assertion is what will catch it.

### Interpreter Discovery
`python3` on `PATH` is not proof of a working Python. Windows ships a `python3.exe` App Execution Alias that is a stub which fails at runtime, and `Get-Command python` returns every match as an array. Both hook twins probe each candidate with `--version` and require a `Python X.Y` response before trusting it, so a stub falls through to a real `python` further down `PATH`.

`check-hook-policy` asserts this: it places a dead `python3` in front of `PATH` with a working `python` behind it and requires the gate to still deny an out-of-set write. It also asserts that with no usable interpreter at all the gate allows, so the degrade path cannot silently become a denial.

The design, its risks, and its unverified status are recorded in `docs/adr/0009-hook-governed-loop.md`.## If a Command Is Blocked

1. Read the block reason and safer alternative printed by the hook.
2. Replace destructive/unsafe command with explicit, reviewable steps.
3. Re-run with minimal privileges and narrower scope.

## Extending Policy

1. Add or adjust a line in `.github/hooks/policy-rules.tsv`.
2. Keep the regex narrow enough to avoid noisy false positives.
3. Provide a specific safer alternative, not just a generic warning.
4. Change both the `.sh` and `.ps1` variants only when the hook mechanism changes, not when only the rule data changes.
5. Add a denied fixture and at least one safe allowed fixture to `.github/scripts/check-hook-policy.*`. Fixtures are delivered as stdin JSON because that is how the harness calls the hook.
6. Run `.github/scripts/check-hook-policy.sh` and `.github/scripts/check-hook-policy.ps1` before merging.
7. Matching is case-insensitive by default; use a scoped `(?-i:...)` group when a rule must distinguish case (for example, blocking `git branch -D` while allowing `git branch -d`).

Rules match against the payload with JSON punctuation flattened to spaces, so an anchor such as `(^|\s)` still matches a command that arrives inside a JSON string. Write patterns against the command text, not against JSON syntax.

## Policy Test Fixtures

Denied fixtures cover destructive deletion (including `git clean -f`, discard-all restores, `rmdir /s /q`, and Docker prunes), remote shell execution, hard reset, force push, stash and branch destruction, secret-file staging, secret writes to `.env`, HTTP package registries, and unapproved policy edits.

Allowed fixtures cover common safe commands such as `git status --short`, `git diff --stat`, local test commands, and starter validation scripts.

## Debug False Positives

1. Copy the exact blocked command.
2. Identify the matching regex in `.github/hooks/policy-rules.tsv`.
3. Decide whether the command is actually safe or whether the safer alternative should be used.
4. If the rule is too broad, narrow the regex and add a regression fixture.
5. If the command is high-risk but necessary, require documented approval instead of weakening the rule globally.

## Emergency Bypass

Bypass should be rare and explicit:

- Record who approved the bypass, why it was needed, and what command or action was allowed.
- Prefer a one-time local bypass over changing shared policy.
- Open follow-up workflow debt to add a safer supported path.
- Never bypass secret-handling, credential, or production-data safeguards just to save time.

### Role-Aware Tuning Guidance

- Treat `preToolUse` rules as global safety rails, then tune rule wording with the highest-risk execution roles in mind.
- Use `.github/roles/tool-access.json` as the source of truth for which roles can run execute tools.
- If a rule primarily targets command execution risk, verify its impact for `analysis`, `planning`, and `implementation` roles first.
- Keep `review` and `workflow-maintenance` roles in mind for false-positive checks, since they usually do not run execute tools.
- If a policy change alters expected behavior for a role, update both this runbook and the related role notes in `.github/hooks/agent-policy.json`.

The approval-gated orchestration overlay should reuse the existing `postToolUse` audit seam for transition records. It should not add new core hook lifecycle phases.

## Audit Log Usage

- Logs are written to `.github/hooks/logs/agent-audit.log` as JSON lines.
- Each record carries `tool`, `sessionId`, `action`, and `result`.
- `action` is truncated to 160 characters and secret-shaped values are replaced with `[REDACTED]` before anything is written; the record is escaped so every line stays parseable JSON.
- Redaction is best-effort pattern matching, not a guarantee. Treat the log as sensitive, never paste it into an issue or PR, and never add raw request bodies, headers, or credentials to it.
- Use logs for debugging, policy tuning, and review traceability.

## Troubleshooting

- **Every tool call is denied.** `preToolUse` fails closed, so anything that stops the hook from running denies everything. In order of likelihood: the interpreter named in `agent-policy.json` is missing (`powershell` ships with Windows; `pwsh` is a separate install), a referenced script path does not resolve, or the execution policy blocks the script. The validator asserts referenced scripts exist for the first two; the audit channel shows the third.
- **Nothing is blocked.** The policy is not loading. Confirm `version` is the number `1` and every item has `type: "command"` and a string handler. A bad version rejects the whole file and a malformed item is dropped, both without stopping the session.
- **Blocking is intermittent.** A slow hook times out, and a timeout is fail-open. Keep the script's own work small and leave `timeoutSec` at 10.
- **A rule never fires.** The rule may be anchored against content the extraction step removed. Test the exact payload through `check-hook-policy` rather than the command string alone.
- **Nothing is blocked on macOS or Linux without GNU grep.** Both the rule loop and the command extraction use `grep -P`. BSD grep does not support `-P`, so every rule silently fails to match and the policy allows everything. Run the hook under Git Bash, WSL, or a GNU grep, or treat the rules as documentation on that platform.
- **Every tool call is denied and `.agentic/state` exists.** The engine gate is failing closed. Check that `python3` or `python` is on `PATH`, that `.github/roles/tool-access.json` is present, and that the tool name in the payload is listed in its `toolDefinitions`. A finished or blocked run is ignored, so a stale `done` state file is never the cause.

