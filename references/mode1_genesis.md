# Mode 1 — Genesis (No Code Exists Yet)

**Goal**: Produce a `PROJECT_SPEC.md` and, derived from it, a proposed harness (tracks, roles, invariants, gates) — nothing written to disk until final approval in Step 5.

---

## Step 1 — Determine Sub-Mode: Build-With-Me vs. Have-The-Plan

Determine the user's starting point. In environments supporting `ask_question`, present this interactively:
- **Question**: *"How would you like to build out the project specification?"*
- **Options**:
  - `"(Recommended) Build it together from scratch (Propose-then-confirm)"`
  - `"I have an initial plan / spec ready to share (Extract-then-verify)"`

If answering directly from initial prompt context:
- **A doc, paste, or unprompted full explanation** → **Sub-mode 1b: Extract-then-verify**
- **"Just an idea" / wants help figuring it out** → **Sub-mode 1a: Propose-then-confirm**
- **Partial or ambiguous input ("I have some notes")** → Treat as **1b**; its gap-detection step will absorb sparse input and converge toward 1a for whatever is missing.

---

## Step 2a — Sub-Mode 1a: Propose-Then-Confirm

This is a **discussion, not a survey**. At every topic, state a concrete, reasoned guess and ask for confirmation or correction — never ask a bare open question when a defensible guess is possible (except for raw intent, where guessing would be presumptuous). Where multiple options or tech stacks are suggested, provide them via `ask_question` with recommendations.

### Adaptive Pacing & Fatigue Mitigation

To prevent conversation fatigue while preserving high rigor:
- **Fast / Rich Path (Grouped Proposals)**: If the user provides a detailed explanation of their idea, bundle adjacent topics into 3–4 logical blocks rather than forcing 8 separate turns:
  - **Block 1**: Raw Intent & Core Entities (with classifications: mutable, append-only, irreversible, derived/computed).
  - **Block 2**: Catastrophic Failure Modes & Repeating Change Categories (proposed starter tracks & gates).
  - **Block 3**: Tech Stack, Deferred Scope, and Known Unknowns.
  - **Block 4**: Pre-mortem on the harness itself.
- **Sparse Path (Unbundled Proposals)**: If the user provides only a one-line idea ("I want to build a budget app"), step through the 8 topics sequentially.

Every individual entity and invariant must still be explicitly grounded and confirmed—never gloss over a classification to save time.

---

### The 8 Discovery Topics

1. **Raw Intent** (No guess offered):
   > "Tell me what you're building — not the tech, just what it does and who it's for."
   Reflect back a concrete shape immediately: *"Sounds like it has these moving parts: [...] — right, or am I missing something?"*

2. **Core Entities and Their Nature**:
   For each entity mentioned or implied, propose a classification with a grounded reason:
   - **Mutable**: Freely editable over time.
   - **Append-only / Immutable once created**: Historical records, events, audit trails.
   - **Irreversible-if-wrong**: Costly or impossible to undo (money, legal status, destructive external actions, safety-critical data).
   - **Derived / Computed**: A value with no independent stored existence, calculated from other entities (running total, streak, score).
   > *"I'd guess [entity] should be append-only once finalized, because [domain reason] — sound right, or does it need to support edits?"*
   > *(For derived entities)*: *"Since [entity] is fully computed from [source], I'd focus its verification on calculation accuracy rather than storage — sound right?"*

3. **Catastrophic Failure Modes**:
   If the user cannot name one unprompted, offer 2–3 domain-plausible examples derived from what was discussed:
   > *"Common failure classes for this kind of system might include [2-3 domain examples]. Do any of these apply, or is there something more specific to your situation?"*

4. **Repeating Change Categories (Future Tracks)**:
   Propose a starter taxonomy:
   > *"Given what you've described, I'd expect future work to fall into roughly these categories: [derived list]. Does that cover it, or is there a category missing?"*

5. **Tech Stack**:
   If undecided, suggest one grounded in what has been described, explaining why it fits.

6. **Known Unknowns**:
   Leave genuinely open:
   > *"What haven't you decided yet?"*
   A real *"I don't know"* is the correct, expected output. It goes into the open-questions log, not into the harness.

7. **Deferred-But-Planned Scope**:
   Distinct from known unknowns. This represents deliberate non-building of planned scope (e.g. v2 features):
   > *"I won't build tracks or invariants for [X] now since it's not being built yet, but I'll note it as planned so a later Audit isn't caught off guard."*

8. **Pre-Mortem on the Harness Itself**:
   Ask about the harness's own likely failure modes:
   > *"If this harness stops working for you a few months from now — becomes annoying, gets ignored, or turns out to have a rule that doesn't fit — what's the most likely reason?"*

Log every proposal and resolution (accepted / corrected / rejected). The reasoning behind a correction is often the invariant itself and belongs in `PROJECT_SPEC.md` verbatim.

---

## Step 2b — Sub-Mode 1b: Extract-Then-Verify

1. **Ingest** whatever the user hands over in full without interrupting.
2. **Extract** the same structure 1a would have built: entities, classifications, catastrophic areas, change categories, stack.
3. **Reflect back a structured summary with explicit gaps flagged**: Name specifically what the plan did not cover that the harness needs.
4. **Interactive Gap Resolution (MANDATORY)**: For all genuine gaps, architectural choices, tech stack recommendations, or scoping decisions, **invoke `ask_question`**. Provide structured questions with `(Recommended)` options and actionable choices. Do not dump them as static markdown text questions. Do not re-open decisions the user already finalized in their plan.

---

## Step 3 — Write `PROJECT_SPEC.md`

Produce the following artifact structure:

```markdown
# Project Spec: <name>

## What This Is
<in the user's own framing where possible>

## Core Entities
- **<entity>**: <classification (mutable / append-only / irreversible-if-wrong / derived-computed)> — <reason>

## Catastrophic Failure Modes
- <failure mode> — <why it matters, what track/invariant it implies>

## Repeating Change Categories (proposed tracks)
- <category>: <what falls under it>

## Tech Stack
- <choices + rationale>

## Deferred / Future Scope
- <feature or module decided on but not built yet; not built into current tracks/invariants, but noted for future audits>

## Open Questions
- <genuinely undecided items, carried forward, never guessed at>
```
