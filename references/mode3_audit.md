# Mode 3 — Audit (Maintaining & Evolving an Existing Harness)

**Goal**: Keep an existing harness aligned as the codebase or requirements evolve, without ever silently weakening or modifying enforcement configuration.

> [!IMPORTANT]
> **User-Invoked Only**:
> Mode 3 runs only upon explicit user request (e.g. *"audit our harness"*, *"update this command"*, *"this rule is annoying"*). It is never triggered automatically or speculatively.

---

## Step 0 — Determine Entry Point

Infer or ask which of the three entry points applies. If not obvious from the user's invocation prompt, invoke `ask_question`:
- **Question**: *"What type of harness audit or update would you like to perform?"*
- **Options**:
  - `"(Recommended) Full Audit (Sub-mode 3a): Re-evaluate harness against major changes or architectural drift"`
  - `"Quick Fix (Sub-mode 3b): Narrow factual correction (test command, path, tool name)"`
  - `"Behavior Feedback (Sub-mode 3c): Change how a rule behaves (too strict, too slow, or misrouted)"`

---

## Sub-Mode 3a — Full Audit

### Step 1 — Anchor in User Framing
Ask before inspecting:
> *"What specific change or milestone triggered this audit?"*

### Step 2 — Investigate & Diff Against Live Harness
Compare codebase reality against the existing harness configuration. Classify each discrepancy into one of three categories:
- **New**: An entity or pattern not covered by any existing track, role, or invariant.
- **Stale**: An existing track, rule, or verification command that no longer matches the code.
- **Silently Invalidated**: An invariant whose text still runs without error, but whose *underlying domain assumption* was broken by recent changes.

### Step 3 — Present Reasoned Diff with Inherited Invariants
For every item, state the boundary it will newly inherit:
> *"New entity [Entity] appears to fall under [Track], meaning it inherits [Invariant/Gate]. Confirm?"*
> *"Does anything about this change make an existing invariant invalid or counterproductive?"*

Full audits must pass through **Step 4 (Decision Procedure)**, **Step 4.1 (Self-Consistency Audit)**, and **Step 5 (Transparency Checkpoint)** in full.

### Step 4 — Reference Integrity Scan (Mandatory Whenever Anything Is Renamed, Merged, Split, or Removed)
Run the Reference Integrity Scan from `decision_procedure.md#versioning--migration-protocol`. Report which files were checked and which references were updated. A full audit that renames or removes a track/role cannot be marked complete with the scan unreported or skipped.

---

## Sub-Mode 3b — Quick Fix

### Step 1 — Verify It Is Genuinely Narrow & Factual
Confirm the change touches exactly one objective fact (a command, path, or binary name) without altering track scopes, invariants, role permissions, or gate strictness.

> [!CAUTION]
> **Behavior-Change Escalation**:
> If the user's "quick fix" actually alters behavior (e.g., *"just skip this check for speed"*), **halt 3b immediately**. Inform the user and divert directly into Sub-mode 3c:
> *"This isn't just a factual fix — it alters the gating behavior. I will evaluate it under Sub-mode 3c (Behavior Feedback) to assess the safety implications."*

### Step 2 — Verify and Apply Narrowly
- Confirm the new fact is objectively true (e.g., test that the new command executes and exists).
- Show the exact proposed diff and one-line rationale.
- Bump the version with a `factual-fix` changelog entry per the Versioning & Migration Protocol in `decision_procedure.md`. If the fix renames anything (e.g. a moved path used elsewhere in routing), run the Reference Integrity Scan before finalizing — a rename is still a rename even inside an otherwise narrow fix.

### Step 3 — Targeted Dry-Run
Re-verify only the specific track or command affected by the fix (see `dry_run_verification.md`).

---

## Sub-Mode 3c — Behavior Feedback (Highest Scrutiny)

Triggers: *"This is annoying"*, *"I don't want it to do X anymore"*, *"Can we make this track less strict?"*, *"This rule keeps getting in the way"*.

### Step 1 — Separate the Complaint from the Proposed Solution
A user's proposed fix is a hypothesis, not necessarily the optimal solution:
> *"What specific friction or delay are you experiencing, and during what kind of task?"*
*(e.g., "the dual-gate is too slow" might be better solved by narrowing what routes into that track rather than removing the gate).*

### Step 2 — Evaluate Against Hard Invariants & Proposed State
Actively verify:
1. **Contradictions with Irreversible Classifications**: Does this loosen a guardrail established for a catastrophic failure mode?
   > *"This track was set to dual-gated because [X] was classified as irreversible-if-wrong. Loosening it removes that safeguard. Are you sure?"*
2. **Circuit Breaker Ceiling Floor (Non-Negotiable, Check Before Proceeding)**: If the proposed change would raise a track's circuit breaker ceiling above its current value, check whether that track carries a Hard Invariant. If it does, **the ceiling change is rejected outright, not negotiated** — per the Circuit Breaker Protocol §4 floor (`decision_procedure.md`), a Hard-Invariant track's ceiling may never exceed 3 consecutive attempts, regardless of user rationale ("it's flaky," "it's annoying," "just this once"). State this plainly rather than presenting it as one tradeoff among several:
   > *"[Track] carries a Hard Invariant ([invariant text]), so its circuit breaker ceiling is fixed at [current ceiling] and cannot be raised — this floor exists specifically so an invariant-bearing gate can't be talked into more unsupervised retries. I can help narrow what routes into this track, or address the underlying flakiness, but the ceiling itself isn't adjustable here."*
   This check applies even if the user's request never mentions "circuit breaker" or "ceiling" by name — e.g. a request to "let it retry a few more times before bugging me" on an invariant-bearing track is this same request in different words.
3. **Coverage Gaps in Proposed State**: Run all checks from `decision_procedure.md#step-41-self-consistency-audit` against the **proposed state**, including item 8's ceiling-floor citation.
4. **Internal Dependencies**: Check if other tracks rely on the gate or verification command being modified.

### Step 3 — Transparent Consequence Reporting
- **If proposal would compromise safety**: State the exact breakdown mechanism and await explicit confirmation.
- **If proposal is valid with tradeoffs**: List every behavioral change clearly before asking for approval.
- **If proposal is clean**: Display the diff and request approval.

### Step 4 — Version & Validate
Apply narrowly, record the user's rationale as a `behavior-change` changelog entry (never `factual-fix`, regardless of how small the diff looks) per the Versioning & Migration Protocol, run the Reference Integrity Scan if anything was renamed or removed, and re-run dry-run verification for affected tracks.

- **Clear Stale Circuit Breaker Breach Records for Resolved Work Orders (Mandatory Where Applicable)**: A common trigger for Sub-mode 3c is a track that hit its circuit breaker ceiling in the first place ("this gate keeps failing, can we fix/loosen it") — check `.agents/checkpoint.json` (or the host's equivalent) for an open breach record on the track(s) this change touches before finishing. If one exists and this change resolves the underlying cause of that breach (e.g. the verification command was fixed, the gate logic was corrected, the flaky dependency was addressed):
  1. Confirm the fix actually addresses the breach's recorded failure output — cite the specific prior failure and how this change resolves it, not just "this should fix it."
  2. Clear the breach record and reset the attempt counter for that specific work order to 0, so the next attempt starts clean rather than immediately re-breaching on a counter that never reset.
  3. Note this explicitly in the same changelog entry (e.g. *"Cleared stale breach record for work order WO-142 on the Payments-Reconciliation track; root cause was the flaky `pytest tests/ledger` timeout, fixed by increasing the test's network timeout"*) — do not fold breach-clearing into the entry silently as if it were implied by the behavior-change description alone.
  - **Do not clear a breach record for a different reason than the one that caused it.** If the user's proposed change loosens the gate's *criteria* (what counts as pass/fail) rather than fixing the *cause* of the failures, the breach record documents real, still-relevant history — evaluate whether it should stay open pending the human's explicit confirmation that the underlying problem, not just the gate's strictness, has been addressed.
  - **A breach record with no corresponding fix in this change is left untouched.** This step exists to prevent a resolved issue from leaving a phantom block, not to give Sub-mode 3c a way to quietly wipe breach history — an unresolved breach stays open and escalated exactly as the Circuit Breaker Protocol requires, whether or not a 3c pass happens to touch that track for an unrelated reason.
