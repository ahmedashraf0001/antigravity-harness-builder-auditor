# Step 6 — Dry-Run Verification Before Declaring Build Complete

A harness written to disk without execution testing is unverified. Step 6 walks through synthetic checks to prove that routing, verification commands, and safety gates fire as intended.

---

## The 6 Dry-Run Verification Checks

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

### 3. Deliberate Ambiguity & Halt-on-Ambiguity Test (Critical Safety Check)
For each track carrying a **Hard Invariant** or **Dual-Gate**:
- Formulate a synthetic task that is **deliberately ambiguous** on the exact dimension the invariant protects:
  - *Example (Financial Track)*: *"Charge the user $10 if the job times out, but there is no policy on refunding unconsumed processing tokens."*
  - *Example (Data Retention)*: *"Purge inactive records after 30 days, but active sessions may reference soft-deleted IDs."*
- Trace the ambiguous task through the written triage rules.
- **Passing Criterion**: The logic **must halt and escalate** (log to open questions and prompt the user), rather than making a "reasonable guess" or silently proceeding.
- If an invariant-bearing track allows an ambiguous prompt through, fix the gate logic immediately and re-test.

### 4. Interruption & Resume Protocol Wiring Check
Re-open the top-level always-on directive file (e.g., `AGENTS.md` or `.agents/rules/harness-routing.md`):
- Confirm the resume check directive is physically present.
- Confirm it points to the valid, persisted checkpoint file path (`.agents/checkpoint.json`).
- Ensure the instruction orders the agent to inspect the checkpoint before performing any action.

### 5. Orchestrator Zero-Direct-Writes & Subagent Delegation Wiring Check
Re-open `AGENTS.md`:
- Confirm that **Section 0: Zero Direct Application Writes** is physically present at the top.
- Confirm it explicitly states:
  * The orchestrator is **strictly forbidden** from writing or editing application code directly (`write_to_file`, `replace_file_content`, etc.).
  * For any task, bug fix, or error remediation, the orchestrator **must dispatch a subagent** via `invoke_subagent`.
- If Section 0 is missing or weak, add/strengthen it before declaring the build complete.

### 6. Failure Remediation
If any track misroutes, points to an invalid binary/command, fails the halt-on-ambiguity check, or lacks the Section 0 delegation rule:
- Correct the rule or configuration file.
- Re-run the dry-run check until all tracks pass cleanly. Never ship known breakage.

---

## Dry-Run Completion Report Format

Deliver the dry-run results as a structured report matching your completion contract:

```markdown
### Harness Dry-Run Verification Report

| Track Name | Synthetic Task Description | Routing Result | Verification Command Status | Halt-on-Ambiguity Test |
| :--- | :--- | :--- | :--- | :--- |
| **<Track 1>** | *"<task>"* | PASS (-> Role X) | PASS (`npm run typecheck`) | N/A (single-gated) |
| **<Track 2>** | *"<ambiguous task>"* | PASS (-> Role Y) | PASS (`pytest tests/audit`) | PASS (Halted & Escalated) |

- **Resume Protocol Status**: Verified wired to `AGENTS.md` pointing to `.agents/checkpoint.json`.
- **Orchestrator Delegation Status**: Verified wired to `AGENTS.md` (Section 0: Zero Direct Writes, mandatory `invoke_subagent`).
- **Harness Status**: Active and verified at Version `1.0`.
```
