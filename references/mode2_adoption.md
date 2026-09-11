# Mode 2 — Adoption (Existing, Unharnessed Codebase)

**Goal**: Derive the same artifacts as Genesis (`PROJECT_SPEC.md`, tracks, roles, invariants, gates) directly from code reality via read-only investigation instead of a blank-slate discussion.

---

## Step 1 — Deep Read-Only Investigation

Explore the codebase thoroughly using read-only tools:
- Trace primary execution paths, entrypoints, and API contracts.
- Detect existing data-handling, state mutation, and numeric patterns.
- Map module boundaries and dependency flows.
- Locate test suites, linters, typecheckers, and CI configuration.

> [!CAUTION]
> **Zero File Edits in This Step**:
> Step 1 produces findings only — patterns, their locations, and your confidence in inferring intent from each. Do not create, modify, or delete any source files.

---

## Step 2 — Treat Every Finding as a Hypothesis, Never a Conclusion

Surface each ambiguous pattern individually as a focused interactive question via `ask_question`.
- **Never batch these into one massive checklist dump** (batching invites rubber-stamping).
- **Never silently promote a detected pattern into a hard invariant.**
- **Never silently discard an unusual pattern.**

Use `ask_question`:
- **Question**: *"I found [pattern] in [location]. How should this be treated in the harness?"*
- **Options**:
  - `"(Recommended) Intentional domain logic (Derive rule/invariant to protect it)"`
  - `"Legacy gap or bug (Do not enshrine as an invariant)"`
  *(The UI write-in allows providing tribal context)*

**Provenance Tagging (Mandatory)**: Every finding that becomes an invariant must be recorded with its tag at the moment of confirmation, not reconstructed later:
- Confirmed via this step → `[code-evidence + confirmed]`, with the file/location cited alongside.
- Raised independently by the user with no corresponding code pattern → `[user-confirmed]`.
- Raised via a confirmed near-miss in Step 3.3 → `[near-miss-derived]`.
A pattern the user does not explicitly confirm stays a hypothesis in the open-questions log — it never reaches `PROJECT_SPEC.md` as an invariant, tagged or not.

---

## Step 3 — Confirm Domain Understanding, Invisible Constraints & Near-Misses

Work through the following confirmations:

1. **State Inferred Domain Model**:
   > *"Based on the schema and services, this codebase appears to be built around [entities] — is that accurate, or am I missing key domain objects?"*

2. **Uncover Tribal Knowledge & Invisible Constraints**:
   Code shows what was written, not what was assumed:
   > *"Is there anything about this system that isn't obvious from the code — a business rule, a compliance requirement, or something previous contributors knew that isn't written down anywhere?"*

3. **Inquire About Near-Misses**:
   Near-misses provide the strongest evidence of reachable failure modes:
   > *"Has anything broken, or nearly broken, in production because of a subtle issue in this area?"*
   Weight confirmed near-misses heavily when establishing hard invariants.

4. **Present Proposed Track Boundaries**:
   > *"Based on what I found, I propose splitting future changes into: [...] — does that match how you actually divide work here?"*

---

## Step 4 — Write `PROJECT_SPEC.md`

Reconstruct `PROJECT_SPEC.md` matching the structure defined in Genesis Step 3, derived from code reality and verified intent rather than aspirational planning:

```markdown
# Project Spec: <name>

## What This Is
<reconstructed from codebase exploration and user confirmation>

## Core Entities
- **<entity>**: <classification (mutable / append-only / irreversible-if-wrong / derived-computed)> — <evidence from code + confirmation>

## Catastrophic Failure Modes
- <failure mode> — <why it matters, near-miss history, what track/invariant it implies>

## Repeating Change Categories (proposed tracks)
- <category>: <scope and associated directories>

## Tech Stack
- <detected tools, runtimes, test frameworks, and linters>

## Deferred / Future Scope
- <unimplemented features noted in comments or confirmed by user>

## Open Questions
- <unresolved anomalies, carried forward without guessing>
```
