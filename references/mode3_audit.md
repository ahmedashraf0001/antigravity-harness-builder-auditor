# Mode 3 — Audit (Maintaining & Evolving an Existing Harness)

**Goal**: Keep an existing harness aligned as the codebase or requirements evolve, without ever silently weakening or modifying enforcement configuration.

> [!IMPORTANT]
> **User-Invoked Only**:
> Mode 3 runs only upon explicit user request (e.g. *"audit our harness"*, *"update this command"*, *"this rule is annoying"*). It is never triggered automatically or speculatively.

---

## Step 0 — Determine Entry Point

Infer or ask which of the three entry points applies:

1. **Full Audit (Sub-mode 3a)**: Significant project changes (major refactor, new feature area, stack migration) where the harness needs re-evaluation against reality.
2. **Quick Fix (Sub-mode 3b)**: A narrow, objectively verifiable factual change (a test runner changed, a path moved, a tool was renamed).
3. **Behavior Feedback (Sub-mode 3c)**: The user is dissatisfied with how the harness behaves (too slow, too strict, blocking legitimate work, miscategorizing tasks).

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
- Bump the version with a short changelog entry.

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
2. **Coverage Gaps in Proposed State**: Run all 5 checks from `decision_procedure.md#step-41-self-consistency-audit` against the **proposed state**.
3. **Internal Dependencies**: Check if other tracks rely on the gate or verification command being modified.

### Step 3 — Transparent Consequence Reporting
- **If proposal would compromise safety**: State the exact breakdown mechanism and await explicit confirmation.
- **If proposal is valid with tradeoffs**: List every behavioral change clearly before asking for approval.
- **If proposal is clean**: Display the diff and request approval.

### Step 4 — Version & Validate
Apply narrowly, record the user's rationale in the changelog, and re-run dry-run verification for affected tracks.
