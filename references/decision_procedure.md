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

#### Role Granularity (4f)
- **Default to Sharing Roles**: When tracks share the same kind of judgment, risk profile, and verification approach, share one role (e.g., UI layout and copy text).
- **Split Roles on Risk or Expertise**: Split tracks into separate roles when one is dual-gated/irreversible and the other is not, or when they require distinct engineering disciplines.
- **Re-evaluate Holistically**: Review the full role roster after all tracks are identified to avoid arbitrary fragmentation or over-consolidation.

### 5. Cost / Risk Strategy per Track
- **Batching Policy**:
  - *Low-risk / cosmetic tracks*: Default to **batching** (make related edits in a batch, verify once at the end).
  - *High-risk / irreversible tracks*: Default to **eager step-by-step verification** (verify each mutation before proceeding).
- **Reasoning Effort / Model Tier**:
  - Assign model tiers based on track stakes (e.g., Fast/Flash for mechanical linting/docs; Pro/High-effort for architecture and financial invariant enforcement).

---

## Interruption & Resume Protocol (Structural Platform Defense)

This protocol is adopted across all harnesses to safeguard against mid-task disconnections, token exhaustion, or session restarts:

1. **Persistent Append-Only Checkpoint**: Track active steps and verified evidence in `.agents/checkpoint.json` (or tool equivalent). A step is marked done only upon verified evidence, never on an agent's unverified self-report.
2. **Inspect-Before-Acting on Resume**: On receiving a "continue" or "resume" prompt, inspect the checkpoint and on-disk git state before taking any action. Never restart from scratch.
3. **Reconnect or Spawn Successor**: Reconnect to in-flight tasks if supported; otherwise spawn a single successor scoped only to the incomplete work.
4. **Partial Work Sanity Check**: Ensure partial changes build and parse cleanly before building on top of them.
5. **Always-On Injection**: This protocol must be wired into the top-level always-on directive file that the orchestrator reads every session.

---

## Required Harness Structural Elements

Every generated harness must output:
- **Tracks**: Work categories with routing criteria and assigned roles.
- **Roles**: Specialists with defined responsibilities and minimal tool privileges.
- **Hard Invariants**: Non-negotiable safety rules with associated rationale.
- **Gates**: Single or dual gates with explicit verification commands.
- **Circuit Breakers**: Fixed retry limits on gate failure loops (e.g., max 3 retries) with mandatory escalation to human.
- **Halt-on-Ambiguity Rule**: Instruction to log open questions and escalate rather than guessing when invariants are at stake.
- **Completion Reporting Contract**: Structured evidence-based reporting (restated requests, evidence, test commands run, deferred items).
- **Orchestrator-Subagent Delegation Protocol**: The primary orchestrator agent **never writes application code directly**. Its responsibilities are strictly triage, dispatching work orders to specialized subagents, auditing verification evidence, and updating checkpoints. When the host environment supports subagents (e.g. Antigravity's `invoke_subagent`), feature implementation must always be executed by spawning subagents with their designated role prompt, track skill, and model tier (`pro` vs `flash`).
- **Explicit Versioning**: Initial version `1.0`, incremented with a changelog entry on every approved audit.

---

## Step 4.1 — Self-Consistency Audit Checklist

Before presenting the harness to the user, run this 5-point audit against your derived specification:

1. **Invariant Coverage**: Does every hard invariant have at least one track that actively enforces it?
2. **Classification Coverage**: Does every irreversible entity land in a dual-gated track? Does every derived entity have computational output verification?
3. **Verification Completeness**: Does every track specify an actual, runnable verification command?
4. **Role Scope Overlap & Granularity**: Do any roles have conflicting boundaries? Does any role inappropriately mix dual-gated and non-dual-gated tracks?
5. **Circuit Breaker & Halt-on-Ambiguity Wiring**: Are circuit breakers and halt-on-ambiguity directives physically attached to all invariant-bearing tracks?
6. **Orchestrator Delegation Wiring**: Does the top-level directive file (`AGENTS.md`) explicitly contain Section 0 forbidding the orchestrator from running edit/write tools and mandating `invoke_subagent` for all code tasks and bug fixes? An orchestrator permitted to hand-edit code undermines role boundaries and pollutes context.

If any gap is found, correct it before proceeding to Step 5.
