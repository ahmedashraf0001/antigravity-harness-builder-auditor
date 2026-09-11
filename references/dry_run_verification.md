# Step 6 — Dry-Run Verification Before Declaring Build Complete

A harness written to disk without execution testing is unverified. Step 6 walks through synthetic checks to prove that routing, verification commands, and safety gates fire as intended.

Throughout this file, "the top-level directive file" means whichever file the detected host actually reads automatically every session (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/000-orchestrator.mdc`, `AGENT.md`, or the equivalent identified in Step 3.6/the host's primitives file) — do not assume it is literally named `AGENTS.md` for hosts where it isn't.

---

## 0. Execution Capability Check (Run Before Checks 2, 5, and 7)

Checks 2, 5, and 7 below require actually running commands and scripts. Before attempting them, confirm the current environment can execute at all: try one trivial, harmless command (e.g. `echo`, or the first verification command with a `--version`/`--help` flag) and observe whether it runs.

- **If execution works**: proceed with Checks 2, 5, and 7 exactly as written — execute for real, per their existing instructions. This is the default path and the only one that fully satisfies the Mechanical Enforcement Protocol's "Verified by Execution, Not by Description" requirement.
- **If execution is unavailable in this environment** (no shell access, a fully read-only sandbox, permissions that block running scripts) — this is a property of *where the harness builder is currently running*, not a defect in the harness itself. Do not treat it as a failed check, and do not silently skip the check and report PASS as if execution had happened; either would misrepresent what was actually verified. Instead:
  1. **Downgrade, don't fake**: For each affected check, perform the strongest verification actually available — e.g., statically re-read the verification command against the project's manifest to confirm it's a real, spelled-correctly command for this stack (Check 2); trace the circuit breaker's written logic by hand against the synthetic failure sequence without executing anything (Check 5). For Check 7, separate two different things, because only one of them downgrades: whether a script is a **stub** — an unconditional allow with no real conditional logic — is a structural fact readable directly off the source, not an unconfirmed result; like the Artifact Existence Check, it never downgrades to `UNVERIFIED` regardless of whether execution is available, and a stub found this way is a confirmed `FAIL`, routed through Check 8 immediately. What *does* downgrade is the narrower question of whether a script's real conditional logic, given this specific synthetic pass/fail input, actually resolves to the intended allow/deny — that can only be traced by hand without execution, and is reported `UNVERIFIED (static review only)`.
  2. **Label the result honestly**: Report each downgraded check as `UNVERIFIED (static review only — execution unavailable in this environment)`, never as `PASS`. A statically-plausible script is not proven to work; this label is what keeps that distinction visible to the human reviewer instead of being smoothed over by an optimistic-looking report.
  3. **Disclose in the completion report and ask for a real run**: The Dry-Run Completion Report Format below must show `UNVERIFIED` (not `PASS` or blank) for any check downgraded this way, and the report must end with an explicit ask: *"I could not execute [commands/scripts] in this environment, so [Check N/M] are verified by static review only, not by actual execution. Please run [specific command(s)] in an environment with shell access before treating this harness as fully verified, or grant execution access here and I'll complete the live checks."*
  4. **This is a disclosure requirement, not a way around the checks**: A harness that ships with every mechanical-enforcement check downgraded to `UNVERIFIED` has *not* satisfied the Mechanical Enforcement Protocol's execution requirement — Step 5's transparency checkpoint and `HARNESS_RATIONALE.md` must carry this caveat forward, not just this report, so a later reader of the harness (including a Mode 3 audit) knows the artifacts were never actually run.
- **Never conflate the two failure modes**: "the environment can't execute anything" (this section — a property of where the harness builder is currently running) and "the artifact itself is defective — crashed, failed a synthetic case, or turns out to be a stub with an unconditional allow" (a property of the artifact, discoverable either by execution or, for stubs, by reading the source) require different responses — the first needs disclosure and a request for a real run; the second needs the artifact fixed and re-tested per Check 8, regardless of whether the defect was caught by execution or by static read. Mislabeling one as the other either hides a real defect behind an environment excuse, or blocks a build over a limitation that has nothing to do with the harness's correctness.

---

## The 8 Dry-Run Verification Checks

### 1. Synthetic Task Routing Check
For each track:
- Construct one trivial, hypothetical task description (e.g., *"change banner button color"* for cosmetic, *"add fee calculation field"* for financial).
- Re-read the written routing rules and trace the resolution path. Confirm it routes to the exact intended track and role.

### 2. Live Verification Command Execution (Read-Only)
For each track:
- Actually execute the track's specified verification command once in isolation:
  ```bash
  npm test
  pytest tests/unit
  cargo check
  ```
- Confirm the command exists, runs without crashing, and returns a clean exit code.
- **Safety Rule**: Only execute read-only verification commands (typecheck, lint, test). Never execute commands that deploy, migrate production data, or modify state during dry-runs.
- **If execution is unavailable**: follow the Execution Capability Check (§0) — report `UNVERIFIED (static review only)` per track rather than a bare PASS.

### 3. Deliberate Ambiguity & Halt-on-Ambiguity Test (Critical Safety Check)
For each track carrying a **Hard Invariant** or **Dual-Gate**:
- Formulate a synthetic task that is **deliberately ambiguous** on the exact dimension the invariant protects:
  - *Example (Financial Track)*: *"Charge the user $10 if the job times out, but there is no policy on refunding unconsumed processing tokens."*
  - *Example (Data Retention)*: *"Purge inactive records after 30 days, but active sessions may reference soft-deleted IDs."*
- Trace the ambiguous task through the written triage rules.
- **Passing Criterion**: The logic **must halt and escalate** (log to open questions and prompt the user), rather than making a "reasonable guess" or silently proceeding.
- If an invariant-bearing track allows an ambiguous prompt through, fix the gate logic immediately and re-test.

### 4. Interruption & Resume Protocol Wiring Check
Re-open the top-level directive file:
- Confirm the resume check directive is physically present.
- Confirm it points to the valid, persisted checkpoint file path.
- Ensure the instruction orders the agent to inspect the checkpoint before performing any action.
- Confirm the Interrupted-Attempt Handling rule (`decision_procedure.md`'s Resume Protocol item 5) is present too, not just the general "inspect before acting" instruction — specifically, that resuming an in-flight gate attempt re-verifies existing partial work before either counting a failure or dispatching a fresh attempt, rather than defaulting to one or the other.

### 5. Circuit Breaker Wiring & Synthetic Breach Test (Critical Safety Check)
For each track carrying a **Hard Invariant** or **Dual-Gate**:
- **Wiring Check**: Re-open the top-level directive file and confirm the Circuit Breaker Protocol instruction is physically present, names the correct checkpoint field for the attempt counter, and states the track's ceiling explicitly (do not accept an unstated or implied default).
- **Synthetic Breach Test**: Simulate 3 (or the track's stated ceiling) consecutive failed verification results for one hypothetical work order on the track — without actually executing destructive commands, walk the written logic through the failure sequence as you did for routing in Check 1. This check is a traced-logic exercise, not a live execution, so the Execution Capability Check in §0 does not downgrade it — it always runs as written, regardless of environment.
- **Passing Criterion**: On the attempt matching the ceiling, the logic **must halt and escalate** (write a breach record, invoke the host's interactive questioning mechanism or log to open questions) rather than dispatching a further attempt. Confirm the pre-gate and post-gate counters on dual-gated tracks are independent — breaching one must not silently consume or reset the other's budget.
- If a track allows a retry past its stated ceiling, or shares a counter across independent gates, fix the wiring immediately and re-test.

### 6. Orchestrator Zero-Direct-Writes & Subagent Delegation Wiring Check
Re-open the top-level directive file:
- Confirm that **Section 0: Zero Direct Application Writes** is physically present at the top.
- Confirm it explicitly states:
  * The orchestrator is **strictly forbidden** from writing or editing application code directly.
  * For any task, bug fix, or error remediation, the orchestrator **must dispatch a subagent** via the concrete mechanism named in the detected host's primitives file (e.g. `invoke_subagent`, the `Task` tool, a `.cursor/agents/` invocation).
- **If the detected host has no subagent isolation primitive** (per the host's primitives file — e.g. Cascade, or an unlisted host that turned up nothing in the `generic_tool_primitives.md` investigation): confirm Section 0 is explicitly labeled advisory-only in both the directive file and `HARNESS_RATIONALE.md`, rather than worded as if real delegation were occurring. This check still passes in that case — but only if the limitation is disclosed, not glossed over.
- If Section 0 is missing, weak, or silently overstates what the host can actually enforce, add/correct it before declaring the build complete.

### 7. Mechanical Enforcement Execution Test (Critical Safety Check)
For every Hard Invariant and every dual-gated track, per the Mechanical Enforcement Protocol in `decision_procedure.md`:
- **Artifact Existence Check**: Confirm at least one real enforcement artifact was actually written to disk for this invariant/track (a host-native hook script, a git pre-commit hook, or a CI workflow file) and that `HARNESS_RATIONALE.md` names it by file path in the ownership mapping. An invariant with a described-but-unwritten artifact fails this check — this sub-check is a file-existence and static-read check, not execution, so it always runs regardless of the Execution Capability Check in §0.
- **Stub Structure Check**: Read the artifact's source and confirm it contains real conditional logic tied to a real command or pattern — not an unconditional allow (e.g. a bare `exit 0` with no branching, or a `permission: allow` with no condition attached). Whether a script is structured this way is a fact readable directly off the file, so — like the Artifact Existence Check above — it always runs regardless of §0 and produces a real `PASS` or `FAIL`, never `UNVERIFIED`. A stub found this way is a confirmed defect, not a disclosure item: correct it immediately and re-test per Check 8.
- **Synthetic Pass Case**: Construct an input that should be *allowed* under the gate (e.g., an edit to a file outside the protected path, or a commit that passes the verification command) and actually execute the artifact against it — run the hook script or git-hook binary directly with that synthetic input, or run the CI workflow's underlying command locally if the CI runner itself can't be invoked in this environment.
  - **Passing Criterion**: The artifact allows the action (exit code 0 / `permission: allow`, as appropriate to the host's hook contract).
  - **If execution is unavailable**: follow §0 — read the script's source and confirm the pass-case input would trace through to an allow given the real logic (not "it looks like it should work"); report `UNVERIFIED (static review only)`, not PASS.
- **Synthetic Fail Case**: Construct an input that should be *blocked* under the gate (e.g., an edit to the protected path with no open work order, or a commit with a failing verification command) and execute the artifact against it the same way.
  - **Passing Criterion**: The artifact blocks the action (exit code 2 / `permission: deny`, or the CI job reports a failing check) — and, where relevant, it did so via the artifact's real logic (the actual verification command ran and actually failed), not because the script unconditionally denies.
  - **If execution is unavailable**: same downgrade as the pass case — trace the fail-case input through the script's real logic by hand, and report `UNVERIFIED (static review only)`.
- **Portability & Zero-Absolute-Paths Check**: Read all generated scripts and hooks. Confirm that repository root and application paths are derived dynamically (e.g. `REPO_ROOT="$(git rev-parse --show-toplevel ...)"` or `dirname "${BASH_SOURCE[0]}"`). Search for any machine-specific paths (`/home/`, `/Users/`, drive letters `[A-Za-z]:\\\\`). Any hardcoded machine path is an immediate `FAIL` requiring correction under Check 8.
- **Repository Placement Check**: Confirm that all harness files (`AGENTS.md`, `.agents/`, `PROJECT_SPEC.md`, `HARNESS_RATIONALE.md`, `ONBOARDING.md`) are located strictly inside the git repository root (`git rev-parse --show-toplevel`), co-located with `.git/`. If any harness file was written to a parent workspace directory outside the repository, this check immediately produces `FAIL`.
- **Path-Aware Enforcement Check**: If `verify_gates.sh` is invoked by git pre-commit, confirm it either executes path-aware filtering (e.g. checking `git diff --cached` to only run heavy domain invariant suites when domain files are modified) OR `HARNESS_RATIONALE.md` explicitly documents why the pre-commit hook acts as a global safety net while the track's inner loop runs a subset. Unexplained discrepancies produce `FAIL`.
- **Fail-Closed Check** (where the host's hook contract supports a fail-open/fail-closed setting, e.g. Cursor's `failClosed`): confirm every artifact backing a Hard Invariant has fail-closed behavior explicitly configured, and that a crashed/timed-out run of the script would block rather than silently pass.
- If any artifact fails to write, fails the pass case, fails the fail case, contains hardcoded absolute paths, is misplaced outside the repo, allows past a crash, or turns out to be a stub (unconditional allow regardless of input), correct it immediately and re-test both cases. A described-but-unexecuted artifact has not passed this check, no matter how correct the description reads — and neither has one only ever reviewed statically; that artifact is `UNVERIFIED`, not `PASS`, until someone actually runs it.

### 8. Failure Remediation
If any track misroutes, points to an invalid binary/command, fails the halt-on-ambiguity check, fails the circuit breaker wiring or synthetic breach test, lacks the Section 0 delegation rule (or silently overstates it), or fails the mechanical enforcement execution test:
- Correct the rule, configuration file, or enforcement script.
- Re-run the dry-run check until all tracks pass cleanly. Never ship known breakage.
- **Fix-Attempt Ceiling (Mirrors the Circuit Breaker Protocol)**: This remediation loop is not exempt from the same bounded-retry discipline every generated harness is required to enforce on its own gates. If the *same check, on the same track*, still fails after 3 consecutive fix attempts, stop iterating and surface it to the human directly rather than continuing to patch silently:
  > *"[Check N] on [Track] has failed [count] consecutive fix attempts. Here's what was tried each time and the resulting failure output: [...]. This may point to a deeper issue — e.g. the wrong verification command for this stack, or a track whose classification doesn't match reality — rather than a simple typo. How would you like to proceed?"*
  Do not present the harness as build-complete while this is open, and do not silently retry past the third attempt hoping a fourth will work.
- **Distinct from an `UNVERIFIED` result**: a check that failed because execution was unavailable (§0) is not "known breakage" to fix here — it's a disclosure obligation. Do not attempt to "fix" an environment limitation by rewriting the harness; report it as `UNVERIFIED` and ask for a real run, per §0.4.

---

## Dry-Run Completion Report Format

Deliver the dry-run results as a structured report matching your completion contract. Every cell must be `PASS`, `FAIL`, or `UNVERIFIED (static review only)` — never left blank or asserted without one of these three labels:

```markdown
### Harness Dry-Run Verification Report

| Track Name | Synthetic Task Description | Routing Result | Verification Command Status | Halt-on-Ambiguity Test | Circuit Breaker Test | Mechanical Enforcement Test |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **<Track 1>** | *"<task>"* | PASS (-> Role X) | PASS (`npm run typecheck`) | N/A (single-gated) | N/A (single-gated) | N/A (no invariant) |
| **<Track 2>** | *"<ambiguous task>"* | PASS (-> Role Y) | PASS (`pytest tests/audit`) | PASS (Halted & Escalated) | PASS (Halted at ceiling 3, breach record written) | PASS (`.git/hooks/pre-commit` allowed synthetic-pass input, blocked synthetic-fail input; `failClosed` N/A for this host) |

- **Resume Protocol Status**: Verified wired to `<top-level directive file>` pointing to `<checkpoint file path>`.
- **Circuit Breaker Status**: Verified wired to `<top-level directive file>`; counters stored at `<checkpoint file path>`; per-track ceilings stated; synthetic breach test halted and escalated as expected.
- **Orchestrator Delegation Status**: Verified wired to `<top-level directive file>` (Section 0: Zero Direct Writes, mandatory delegation via `<host-specific mechanism>`) — or "advisory-only, disclosed" if the host has no subagent primitive.
- **Mechanical Enforcement Status**: Every Hard Invariant / dual-gated track has at least one real enforcement artifact (list file paths); each was executed against a synthetic pass and fail case with the stated results; fail-closed configured where applicable.
- **Execution Capability**: `Full execution available` or `Execution unavailable in this environment — see UNVERIFIED items above; live re-run requested from the human before this harness is treated as fully verified.`
- **Harness Status**: Active and verified at Version `1.0` — or `Active, pending live verification` if any check above is `UNVERIFIED`.
```

