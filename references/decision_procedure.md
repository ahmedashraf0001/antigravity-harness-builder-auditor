# Deriving the Harness: Fixed Decision Procedure & Self-Consistency Audit

Regardless of mode (Genesis, Adoption, or Audit), apply this deterministic decision procedure in the exact order below. Inputs are entities, classifications, confirmed external skills, and detected environment constraints.

---

## Step 4 — Fixed Decision Procedure

### 1. Entity-to-Track Mapping
For every core entity from `PROJECT_SPEC.md`:
- **Mutable / Append-only**: Mapped to tracks governing state transitions and schema persistence.
- **Derived / Computed**: Mapped to tracks governing the computation logic itself (verifying output for known inputs, rather than storage).
- **Irreversible-if-wrong**: Mapped to tracks carrying hard invariants and dual-gating.

### 2. Cheapest Runnable Verification per Track
Every track must have an executable verification command (typecheck, unit test suite, linter, custom validator):
- A track without a runnable verification command is **incomplete**. Flag it explicitly.
- For derived/computed entities, verification must check computed outputs against expected values, not merely that the code runs without syntax errors.

### 3. Hard Invariants & Dual-Gating
Any operation touching financial, legal, security-critical, data-destruction, or irreversible external state becomes a **Hard Invariant**:
- Requires **Dual-Gating**: Checked once before execution (pre-work order verification) and once after completion (post-implementation audit).

### 4. Role Definition & Granularity

#### Tool Provisioning (4a–4e)
- **4a. Needs for Self-Verification**: Derive tools based on what the role needs to verify its own output (e.g., test runners, database inspectors, UI rendering engines).
- **4b. Availability Check**: Verify if existing project tooling already provides this before proposing new tools.
- **4c. Search for Standards**: If a tool is missing, look up current standard tools for this stack rather than guessing.
- **4d. Explicit Installation Gate**: Propose tool installations separately with a clear rationale. Never bundle dependency installs with rule approvals.
- **4e. Minimal Tool Scoping**: Keep role tools tightly restricted. Do not grant broad shell or DB access to cosmetic/UI roles.
- **4f. Written Scope Justification (Mandatory)**: For every tool granted to a role, record one line stating the specific verification need from 4a that requires it (e.g. `Role: Payments Engineer — tool: db read access — justification: verify ledger balance post-write per Track: Payments Dual-Gate`). A tool with no traceable 4a justification is not granted. This record is written into the role's definition itself (not held only in reasoning), so Step 4.1 and any future auditor can check scope against a citation rather than against the model's memory of its own reasoning.

#### Role Granularity (4g)
- **Default to Sharing Roles**: When tracks share the same kind of judgment, risk profile, and verification approach, share one role (e.g., UI layout and copy text).
- **Split Roles on Risk or Expertise**: Split tracks into separate roles when one is dual-gated/irreversible and the other is not, or when they require distinct engineering disciplines.
- **Re-evaluate Holistically**: Review the full role roster after all tracks are identified to avoid arbitrary fragmentation or over-consolidation.

#### Complexity Budget Pass (4h — Mandatory, Run After 4a–4g)
A harness nobody can hold in their head is worse than no harness. This pass makes track/role count an explicit tradeoff the human signs off on, not an emergent byproduct of following 4a–4g mechanically.
- **Count and Report**: State the total number of tracks and roles derived so far, plainly, before Step 5 (e.g. *"This harness currently has 9 tracks mapped to 6 roles."*).
- **Attempt Consolidation, Report the Attempt**: For any two tracks whose risk classification, verification approach, and required expertise are the same or adjacent, actively try merging them into one track/role and note why you did or didn't (e.g. *"Considered merging 'API Contracts' and 'Internal Services' — kept separate because API Contracts is dual-gated and Internal Services is not."*). A track/role list that was never tested for consolidation has not passed this check, regardless of how reasonable each individual entry looks.
- **Flag Sprawl Explicitly at the Threshold**: If total tracks exceed roughly 8 or total roles exceed roughly 5 for a single harness (not a monorepo split across Step 0), this is not an error, but it must be surfaced to the human directly, with the specific tracks/roles listed, so they can confirm the complexity is warranted rather than discovering it later by feel:
  > *"This harness has grown to [N] tracks / [M] roles. Here's the full list: [...]. Does this match the actual number of distinct risk profiles in your project, or should some of these be consolidated?"*
- **No Retroactive Shrinking Without Cause**: Do not merge tracks solely to get under the threshold — a genuinely complex project can legitimately need more. The threshold exists to force a stated decision, not to cap the count.

#### Mechanical Enforcement Pass (4i — Mandatory for Every Hard Invariant / Dual-Gated Track, Run After 4h)
Prose telling an agent "never do X" is a request, not a guarantee — the acting agent can only bind itself as strongly as its own adherence to the prompt. This pass makes sure every Hard Invariant and every dual-gated track has at least one enforcement artifact that runs **outside the acting agent's control**: a real script, hook, or CI check that would still fire even if the agent ignored, forgot, or was talked out of the rule text. See the **Mechanical Enforcement Protocol** below for the full specification. This is not optional scaffolding — a Hard Invariant with no mechanical backstop has not passed this check, regardless of how clearly Section 0 or the track's rule text states the rule.

### 5. Cost / Risk Strategy per Track
- **Batching Policy**:
  - *Low-risk / cosmetic tracks*: Default to **batching** (make related edits in a batch, verify once at the end).
  - *High-risk / irreversible tracks*: Default to **eager step-by-step verification** (verify each mutation before proceeding).
- **Reasoning Effort / Model Tier**:
  - Assign model tiers based on track stakes (e.g., Fast/Flash for mechanical linting/docs; Pro/High-effort for architecture and financial invariant enforcement).

---

## Mechanical Enforcement Protocol (Structural "Teeth" Defense)

A generated harness is only as strong as what happens when the acting agent — under time pressure, context loss, or a persuasive-sounding user request — decides not to follow it. Every other protocol in this document (Circuit Breaker, Resume, Versioning) assumes the acting agent is cooperating with the rules. This protocol is the layer for when it doesn't: it specifies what must exist **outside the model's own process** so that a Hard Invariant or a dual-gate cannot be silently bypassed by the same agent that's supposed to be enforcing it.

1. **Three Enforcement Artifact Types, Ranked by Strength**: For every Hard Invariant and every dual-gated track, at least one of the following must be generated as a real, executable artifact — not described in prose and left unimplemented:
   - **(a) Host-Native Blocking Hook** (strongest, when available): a `PreToolUse`/`preToolUse`/`pre_write_code`-style hook per the project's detected primitives file (see `claude_code_primitives.md` §3.D, `cursor_primitives.md` §3.D, `windsurf_primitives.md` §3.D, `antigravity_primitives.md` §3.D, or the investigation findings from `generic_tool_primitives.md`). Runs before the acting agent's tool call completes; can block it outright regardless of what the agent intended.
   - **(b) Git Pre-Commit Hook** (host-independent, near-universal): a `.git/hooks/pre-commit` script (or a managed equivalent such as `husky`/`pre-commit` framework, matching whatever the project already uses) that re-runs the track's verification command and blocks the commit on failure. Works identically regardless of which AI tool is in the editor, because it is a property of the repository, not the AI tool — this is the correct default whenever the detected host has no native blocking hook, per `generic_tool_primitives.md` §3.
   - **(c) CI Check** (weakest alone, but catches what a local hook missed or bypassed): a generated CI workflow (e.g. `.github/workflows/harness-verification.yml` or the project's existing CI system) that re-runs every track's verification command on every push/PR touching that track's paths, and fails the check on non-zero exit. This does not block a local commit, but it blocks a merge — treat it as a second, independent layer rather than a substitute for (a) or (b).
   - **Hard Invariants require at least (b) or (a); CI (c) alone is not sufficient for a Hard Invariant**, since a CI-only gate can be bypassed by merging without review or force-pushing past a check. Non-invariant dual-gated tracks may rely on (c) alone if the project has no local hook convention and the human explicitly accepts CI-only enforcement — surface this as an explicit tradeoff at Step 5, don't decide it silently.
2. **Real Logic, Not Stubs (Mandatory)**: An enforcement artifact whose script unconditionally exits 0 (or returns `{"permission": "allow"}` regardless of input) is not an enforcement artifact — it is decoration that will pass every dry-run check by construction while enforcing nothing. Every generated script must contain the actual gate logic derived from the track's stated verification command and invariant conditions: run the real verification command, real pattern-match against the real destructive-command list, and exit/return based on the real result.
3. **Exit Code Convention (Applies to Every Generated Script)**: Use exit code `2` to signal "blocked," across every artifact type (a)/(b)/(c) and every host, not just the ones whose hook contract specifically requires it (Claude Code's `PreToolUse`, Cursor's `preToolUse`). Git and CI only distinguish zero from non-zero and don't care which non-zero code is used, so standardizing on `2` costs nothing there — but it means a script written once (e.g. for a git pre-commit hook) can be reused verbatim as a host-native hook without silently losing its blocking behavior, and it gives Step 6's execution test one exit code to check for across every artifact instead of a per-host exception list. Reserve other non-zero codes for genuine script failure unrelated to the gate decision (missing binary, crash) — Step 6 distinguishes "the artifact ran and correctly blocked" from "the artifact itself is broken" by checking for exit `2` specifically on the fail case, not merely "non-zero."
4. **Ownership Mapping (Written, Not Implied)**: For every Hard Invariant and dual-gated track, write one line in `HARNESS_RATIONALE.md` naming which artifact(s) back it and where the artifact lives, e.g.: *"Invariant: 'Never modify production ledger balances outside the reconciliation job' — enforced by (b) `.git/hooks/pre-commit` (denies commits touching `ledger/` without a passing `pytest tests/ledger_invariants`) and (c) `.github/workflows/harness-verification.yml` (re-runs the same check on every PR)."* An invariant with no line in this mapping has not passed 4i, regardless of whether Section 0 or a track's rule text mentions it.
5. **Fail-Closed by Default**: Where the host's hook mechanism supports a fail-open/fail-closed choice (e.g. Cursor's `failClosed` flag, per `cursor_primitives.md` §3.D), every artifact backing a Hard Invariant must be configured fail-closed — a crashing or timing-out enforcement script must block the action, not silently let it through. Where the host only offers one behavior (e.g. Claude Code's exit-code contract, which blocks on exit 2 and has no separate fail-open mode to misconfigure), state plainly that this concern doesn't apply rather than leaving it unaddressed.
6. **Installation Is Itemized Like Any Other Tool**: Generating a git hook, CI workflow file, or host hook script is itself a change to the project (a new file, a new CI job that will run on the team's account/minutes). Present each enforcement artifact through the same **Itemized Tool Installation Gate** as any other proposed dependency (Step 5.4) — do not bundle "also, I'm adding a pre-commit hook" into a general harness approval.
7. **Verified by Execution, Not by Description**: Step 6's dry-run must actually invoke each generated enforcement artifact against a synthetic pass case and a synthetic fail case (see `dry_run_verification.md` Check 8) to prove the script's logic is real, rather than trusting that a described mechanism was implemented as described.

---

## Interruption & Resume Protocol (Structural Platform Defense)

This protocol is adopted across all harnesses to safeguard against mid-task disconnections, token exhaustion, or session restarts:

1. **Persistent Append-Only Checkpoint**: Track active steps and verified evidence in `.agents/checkpoint.json` (or tool equivalent). A step is marked done only upon verified evidence, never on an agent's unverified self-report.
2. **Inspect-Before-Acting on Resume**: On receiving a "continue" or "resume" prompt, inspect the checkpoint and on-disk git state before taking any action. Never restart from scratch.
3. **Reconnect or Spawn Successor**: Reconnect to in-flight tasks if supported; otherwise spawn a single successor scoped only to the incomplete work.
4. **Partial Work Sanity Check**: Ensure partial changes build and parse cleanly before building on top of them.
5. **Interrupted-Attempt Handling (Circuit Breaker Interaction)**: If the disconnect happened *after* a subagent was dispatched for a gate attempt but *before* a verification result was observed, that attempt is incomplete, not failed — per the Circuit Breaker Protocol's own rule that the counter increments only on an observed result, do not increment it for an attempt that never produced one, and do not immediately dispatch a brand-new attempt from scratch either. Resolve it in this order:
   - First, run the Partial Work Sanity Check above, then run the gate's verification command against whatever partial work exists.
   - If it **passes**: the gate is satisfied. No attempt is consumed, and no counter change is made.
   - If it **fails**: that failure is now the attempt's observed result — increment the counter for it exactly as any other observed failure would, per the Circuit Breaker Protocol.
   - Only dispatch a genuinely new implementation attempt (rather than re-verifying existing partial work) if inspection shows no salvageable partial work exists to verify.
6. **Always-On Injection**: This protocol must be wired into the top-level always-on directive file that the orchestrator reads every session.

---

## Circuit Breaker Protocol (Structural Failure-Loop Defense)

A circuit breaker is a fixed retry ceiling on a single gate/verification loop, not a vague "don't retry forever" sentiment. Every dual-gated or hard-invariant track must wire this concretely — the same way the Resume Protocol above is wired, not left as a bullet point.

1. **Scope of One Counter**: A circuit breaker counts **consecutive failed attempts at the same gate, for the same work order**, not failures across a whole track's lifetime. A new work order (a new task routed into the track) starts with a fresh counter. This must be stated explicitly per track so "gate" and "work order" boundaries aren't ambiguous later.
2. **What Counts As an Attempt**: One attempt = one full cycle of (implementation or fix attempt by the assigned subagent) → (verification command run) → (result). A verification command that fails to run at all (missing binary, crash) still counts as a failed attempt — it is not a free pass that resets the counter.
3. **Persistent Counter State**: The attempt count for the active work order is written to `.agents/checkpoint.json` alongside the existing task state, incremented **only** after a verification result is observed — never on the subagent's self-reported "I fixed it." This makes the counter survive disconnects: a resumed session reads the existing count rather than starting over at zero, closing the loop where restarting a session could otherwise reset the breaker indefinitely. For an attempt that was dispatched but never reached an observed result before a disconnect, see the Resume Protocol's Interrupted-Attempt Handling above — it is not counted until a result is actually observed on resume, and is not silently discarded either.
4. **Fixed Ceiling, With a Hard Floor on Invariant-Bearing Tracks**: Default ceiling is 3 consecutive failed attempts per work order, unless the track's `HARNESS_RATIONALE.md` entry states a different number with a reason (e.g. a flaky external dependency may justify 2; a purely mechanical lint fix may justify a higher ceiling).
   - **For any track carrying a Hard Invariant, the ceiling may never be raised above 3, at Genesis/Adoption, at Audit, or via Sub-mode 3c, regardless of user request or stated rationale.** A higher ceiling on an invariant-bearing gate means more consecutive unverified attempts to touch financial, legal, security-critical, destructive, or irreversible state before a human is forced to look — this is a safety floor, not a tuning parameter, and it does not get renegotiated by "this keeps failing and it's annoying." (It may be *lowered* freely, e.g. to 2, if the track's rationale supports tighter escalation.)
   - This floor is binding on every mode and sub-mode that can touch a ceiling — see Sub-mode 3c Step 2 (`mode3_audit.md`) and Step 4.1 item 8 below, both of which must check this floor explicitly rather than trusting that it was respected when the ceiling was first set.
5. **On Breach — Mandatory Halt, Not Retry-with-Different-Approach**: When the ceiling is reached:
   - The orchestrator halts all further attempts on that work order.
   - It writes a breach record to `.agents/checkpoint.json`: work order, track, gate, all failed attempts' verification output, and a timestamp.
   - It escalates to the human via the same channel as Halt-on-Ambiguity (open questions / `ask_question` if available) — it does not silently try again, switch strategy on its own, or mark the task as done.
   - The work order stays open and blocked until the human responds; it is never auto-closed or auto-abandoned.
6. **Dual-Gated Tracks Get Two Independent Counters**: A dual-gated track's pre-work-order check and its post-implementation audit are separate gates with separate counters — a breach on the pre-gate does not consume attempts from the post-gate's budget, and vice versa.
7. **Always-On Injection**: Like the Resume Protocol, this counter-read/escalate logic must be wired into the top-level always-on directive file (named per the detected host, e.g. `AGENTS.md`, `CLAUDE.md`, or the host's rule-file equivalent), so every session — not just the one that hit the failure — enforces it consistently.
8. **Breach Records Are Not Permanent, But Only Mode 3 Clears Them**: A breach record stays open and blocking until either the human responds to the escalation, or a Sub-mode 3b or 3c change explicitly resolves the underlying cause and clears it per `mode3_audit.md` Sub-mode 3b Step 4 (a narrow, objectively-verified fix) or Sub-mode 3c Step 4 (any case requiring judgment about whether the cause was really addressed) — never cleared by the orchestrator itself outside of an approved Mode 3 change, and never cleared just because the ceiling or gate criteria changed without the actual cause being fixed.

---

## Required Harness Structural Elements

Every generated harness must output:
- **Tracks**: Work categories with routing criteria and assigned roles.
- **Roles**: Specialists with defined responsibilities, minimal tool privileges, and a written scope justification per tool (see 4f).
- **Hard Invariants**: Non-negotiable safety rules with associated rationale **and a provenance tag**: `[user-confirmed]` (stated or explicitly agreed in discussion/`ask_question`), `[code-evidence + confirmed]` (Mode 2 pattern the user confirmed was intentional), or `[near-miss-derived]` (raised from a confirmed production near-miss). An invariant with no provenance tag was silently promoted from a hypothesis and must be sent back through `ask_question` before it can ship — this is what makes "never silently promote a pattern into a hard invariant" checkable against the written artifact instead of trusted to have been followed.
- **Gates**: Single or dual gates with explicit verification commands.
- **Circuit Breakers**: Per-gate, per-work-order retry ceilings (default 3 consecutive failures) with persistent counter state and mandatory human escalation on breach — see the Circuit Breaker Protocol above. Not a general policy statement; every dual-gated or invariant-bearing track must have its counter wired into `.agents/checkpoint.json` and its ceiling stated explicitly.
- **Mechanical Enforcement Artifacts**: At least one real, executable enforcement artifact (host-native hook, git pre-commit hook, and/or CI check) per Hard Invariant and dual-gated track — see the Mechanical Enforcement Protocol above. Not satisfied by rule text alone, regardless of how emphatically the rule is worded.
- **Halt-on-Ambiguity Rule**: Instruction to log open questions and escalate rather than guessing when invariants are at stake.
- **Completion Reporting Contract**: Structured evidence-based reporting (restated requests, evidence, test commands run, deferred items).
- **Orchestrator-Subagent Delegation Protocol**: The primary orchestrator agent **never writes application code directly**. Its responsibilities are strictly triage, dispatching work orders to specialized subagents, auditing verification evidence, and updating checkpoints. Feature implementation must always be executed by spawning subagents with their designated role prompt, track skill, and model tier, using whichever concrete delegation mechanism the detected host's primitives file specifies (e.g. Antigravity's `invoke_subagent`, Claude Code's `Task` tool + `.claude/agents/`, Cursor's `.cursor/agents/`, Devin Local's `agents/`) — never hardcode one host's mechanism name into a harness built for a different host. Where the detected host has no subagent isolation primitive at all (e.g. Cascade, or an unlisted host per `generic_tool_primitives.md`), this protocol degrades to the documented best-effort convention in that host's primitives file and must be disclosed as advisory-only, not silently presented as equivalent to real delegation.
- **Explicit Versioning & Reference Integrity**: Initial version `1.0`, incremented per the Versioning & Migration Protocol below on every approved audit — not a bare version bump, but a structured changelog entry plus a checked-and-repaired reference graph.

---

## Versioning & Migration Protocol (Structural Change-Tracking Defense)

A version number that only increments, with no record of *what* changed shape and *what else pointed at it*, is decoration. This protocol makes every structural change (a track renamed, split, merged, or removed; a role renamed or reassigned) traceable and makes stale references a build-blocking failure, not a silent landmine discovered mid-task by a future agent.

1. **Structured Changelog Entry (Mandatory, Every Version Bump)**: `.agents/harness_log.json` records, per version bump:
   - `version`: old → new (e.g. `1.0 → 1.1`).
   - `date` and `trigger`: the user's own framing of what prompted the change (per Mode 3 Step 1).
   - `change_type`: one of `add` / `rename` / `merge` / `split` / `remove` / `factual-fix` / `behavior-change`, per entity (track, role, invariant, gate).
   - `entities_affected`: explicit old-name → new-name (or old-name → `null` for removal) for every renamed, merged, split, or removed track/role/invariant.
   - `rationale`: one line, in the user's own words where possible (per Mode 3c Step 4).
   - A Quick Fix (3b) still writes an entry — narrower in scope, but never skipped; "the version file only tracks big changes" is exactly how versioning becomes decorative.

   Example entry:
   ```json
   {
     "version": "1.0 -> 1.1",
     "date": "2026-09-11",
     "trigger": "Payments now supports subscriptions; user asked to split billing logic out",
     "change_type": "split",
     "entities_affected": {
       "Payments": ["Payments-OneTime", "Payments-Subscriptions"]
     },
     "rationale": "Subscription billing has distinct failure modes (dunning, proration) the user wants tracked separately from one-time charges.",
     "reference_integrity_scan": {
       "old_name": "Payments",
       "files_checked": ["AGENTS.md", ".agents/skills/payments/SKILL.md", ".agents/hooks.json"],
       "references_updated": 4
     }
   }
   ```

2. **Reference Integrity Scan (Mandatory Before Any Version Bump Is Finalized)**: Whenever a track or role is renamed, merged, split, or removed, grep the entire generated harness — `AGENTS.md`, every `.agents/skills/<track>/SKILL.md`, `.agents/hooks.json`, subagent role declarations, and `PROJECT_SPEC.md` — for the old name:
   - Every found reference must be updated to the new name, or explicitly removed if the entity was deleted outright.
   - A track/role deletion cannot complete while any file still routes work to, or invokes, the deleted name. Fix forward (update the reference) before the audit is allowed to finish.
   - Report the scan result explicitly: *"Renamed 'Payments' → 'Billing'. Found and updated 3 references: `AGENTS.md` triage matrix, `.agents/skills/billing/SKILL.md`, subagent declaration in the same file."* A version bump with no reported scan result has not passed this check.

3. **Circuit Breaker & Checkpoint Continuity Across Versions**: A version bump must not orphan in-flight state. If a track referenced by an open work order in `.agents/checkpoint.json` is renamed or merged, update the checkpoint's track reference in the same change — an in-flight work order pointing at a name that no longer exists is a stale reference like any other, and the Reference Integrity Scan covers it too.

4. **No Silent Downgrades**: A behavior-altering change (Sub-mode 3c) or removal of an invariant, gate, or dual-gating requirement is never folded into a `factual-fix` changelog entry — it must be logged as `behavior-change` with its own rationale, so a later audit or a new contributor reading `harness_log.json` can see safety-relevant history at a glance without cross-referencing every entry's prose.

5. **Version File Is Append-Only**: Prior entries in `harness_log.json` are never edited or deleted to "clean up" history — corrections to a past entry are themselves a new entry that references the one being corrected.

---

## Step 4.1 — Self-Consistency Audit Checklist

Before presenting the harness to the user, run this audit against your derived specification. **Evidence Rule**: every item below is answered by citing the specific line, file, or artifact that satisfies it — not by asserting PASS/FAIL from memory of having followed the rule. If you cannot point to the line, the item fails, regardless of whether you believe you followed the procedure correctly.

1. **Invariant Coverage**: Does every hard invariant have at least one track that actively enforces it? Cite the track for each invariant.
2. **Classification Coverage**: Does every irreversible entity land in a dual-gated track? Does every derived entity have computational output verification? Cite the entity → track mapping for each.
3. **Verification Completeness**: Does every track specify an actual, runnable verification command? Cite the command per track.
4. **Role Scope Overlap & Granularity**: Do any roles have conflicting boundaries? Does any role inappropriately mix dual-gated and non-dual-gated tracks?
5. **Complexity Budget Reported**: Was the 4h consolidation pass actually performed (not skipped), and — if the track/role count exceeds the 8/5 guideline — was it explicitly surfaced to the human with the full list, rather than presented silently inside a larger document?
6. **Tool Scope Minimality**: For every tool granted to every role, does a 4f justification line exist, and does it name a genuine self-verification need from 4a rather than a general-purpose grant ("might need it later" is not a justification)? List any tool that fails this test and remove it.
7. **Invariant Provenance**: Does every hard invariant carry a provenance tag (`[user-confirmed]`, `[code-evidence + confirmed]`, or `[near-miss-derived]`)? Any untagged invariant must be resolved via `ask_question` before proceeding — do not tag it retroactively from assumption to make this check pass.
8. **Circuit Breaker & Halt-on-Ambiguity Wiring**: For every invariant-bearing or dual-gated track, is a circuit breaker counter wired to `.agents/checkpoint.json` (or the host's equivalent checkpoint file) with a stated ceiling, and is the escalate-on-breach instruction physically present in the top-level directive file? Cite the counter's checkpoint field and the ceiling value per track — a track with no stated ceiling has not passed this check. **For every track carrying a Hard Invariant specifically, additionally cite the stated ceiling value against the floor in the Circuit Breaker Protocol §4 (`decision_procedure.md`) and confirm it is ≤ 3** — a Hard-Invariant track with a ceiling above 3, on a first-time build or as the result of any prior Sub-mode 3c change, has not passed this check regardless of what rationale is written in `HARNESS_RATIONALE.md` for it. This applies retroactively on every Mode 3 run, not only at the moment the ceiling was first set: an Audit or Quick Fix that touches an invariant-bearing track's `HARNESS_RATIONALE.md` entry must re-verify this floor even if the ceiling itself wasn't the thing being changed.
9. **Orchestrator Delegation Wiring**: Does the top-level directive file (named per the detected host — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/000-orchestrator.mdc`, or equivalent) explicitly contain Section 0 forbidding the orchestrator from running edit/write tools and mandating subagent delegation for all code tasks and bug fixes, using the concrete mechanism named in that host's primitives file? An orchestrator permitted to hand-edit code undermines role boundaries and pollutes context. Quote the exact Section 0 text found. If the detected host has no subagent isolation primitive, confirm Section 0 is explicitly labeled advisory-only rather than silently presented as enforced.
10. **Mechanical Enforcement Coverage**: For every Hard Invariant and dual-gated track, does at least one real enforcement artifact exist per the Mechanical Enforcement Protocol — and is it named with its file path in the `HARNESS_RATIONALE.md` ownership mapping? Cite the artifact path per invariant/track. An invariant whose only backing is rule text in the orchestrator file, with no hook/git-hook/CI artifact cited, has not passed this check. Confirm each cited artifact contains real gate logic (the actual verification command or pattern match), not an unconditional allow — quote the relevant line of the script.
11. **Reference Integrity (Audit-Only)**: If this run renamed, merged, split, or removed any track/role/invariant, was the Reference Integrity Scan run and its result reported? Cite the scan result. Not applicable on a first-time Genesis or Adoption build with nothing yet to rename.

If any gap is found, correct it before proceeding to Step 5. Present the completed checklist — with citations, not just verdicts — as part of the Step 5 transparency document, so the human reviewer is auditing the same evidence rather than re-trusting a bare "all checks passed."
