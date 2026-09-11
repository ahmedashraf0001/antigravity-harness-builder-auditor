# Antigravity 2.0 Primitives & File Layout Mapping

When Step 3.6 detects **Antigravity** or **Antigravity 2.0**, map the derived harness directly to Antigravity's native primitives. This ensures the harness works with progressive disclosure, subagent orchestration, lifecycle hooks, and the chat canvas.

---

## 1. Antigravity Customization Hierarchy

Antigravity resolves customizations in this order (highest to lowest priority):
1. **Workspace Project**: `.agents/` (or `AGENTS.md`) at the repository root.
2. **Declared Configurations**: `.agents/skills.json` or `.agents/plugins.json`.
3. **Global Customizations**: `~/.gemini/config/` (machine-wide).
4. **Built-in Customizations**: Bundled platform capabilities.

---

## 2. Direct Primitive Mapping

| Harness Concept | Antigravity Native Primitive | Target File / Location | Purpose & Behavior |
| :--- | :--- | :--- | :--- |
| **Orchestrator & Routing** | Context Rule / Project Directive | `AGENTS.md` or `.agents/rules/routing.md` | Always-on rule loaded every session. Holds triage logic and the Interruption & Resume Protocol. |
| **Work-Routing Tracks** | Project Skills | `.agents/skills/<track>/SKILL.md` | Progressive disclosure: Antigravity indexes the `description` and loads the full track workflow only when triggered. |
| **Specialized Roles** | Subagents | Declared via `define_subagent` / `invoke_subagent` | Scoped agent instances with customized system prompts, tool permissions, and model tiering (`flash` vs `pro`). |
| **Gating** | Lifecycle Hooks | `.agents/hooks.json` | Mechanical backstop: runs automated verification or blocking scripts before/after tool actions. Mandatory (not merely available) for any Hard Invariant or dual-gated track per the Mechanical Enforcement Protocol (`decision_procedure.md`) — Antigravity's hooks are this host's primary enforcement artifact, equivalent in role to Claude Code's `PreToolUse` or Cursor's `preToolUse`. |
| **Circuit Breakers** | Always-On Directive + Persistent State | `AGENTS.md` (enforcement logic) & `.agents/checkpoint.json` (counter) | Attempt counters are data, not hook config — they must survive a session restart, so they live in checkpoint state and are read/incremented by the orchestrator logic in `AGENTS.md`, not solely by a hook. |
| **Tool Provisioning** | Project MCP Servers | `.agents/mcp_config.json` | Connects external domain tools, live database inspectors, or testing runners. |
| **State & Checkpoints** | Persistent Project State | `.agents/checkpoint.json` & `.agents/harness_log.json` | `checkpoint.json` holds active task state, evidence, and circuit breaker counters. `harness_log.json` holds the append-only structured changelog (version, change_type, entities_affected old→new, rationale) per the Versioning & Migration Protocol. |
| **Specs & Rationale** | Artifact Documents | Project root or `<appDataDir>/brain/<conversation-id>/` | Renders interactively in Antigravity 2.0's Auxiliary Pane for transparent user review. |
| **Interactive Questioning** | Native Interaction Tool | `ask_question` | Renders interactive multiple-choice dialogs in chat UI for gap resolution, stack selection, and approvals. |

---

## 3. Concrete Implementation Details

### A. The Always-On Orchestrator (`AGENTS.md`)
Placed at the repository root. This file is read by Antigravity on every prompt. It MUST be structured with Section 0 prominently at the top:
- **Section 0: Zero Direct Application Writes (Mandatory Subagent Delegation)**:
  ```markdown
  ## 0. MANDATORY: Zero Direct Application Writes (Subagent Delegation)
  The primary orchestrator agent is STRICTLY FORBIDDEN from writing or editing application code directly (`write_to_file`, `replace_file_content`, etc.).
  Under NO circumstances — including bug fixes, debugging, error remediation, or small tweaks — may the orchestrator edit source code with its own hands.

  For EVERY coding task or bug report, the orchestrator MUST:
  1. Determine the target track and assigned role.
  2. IMMEDIATELY invoke a specialized subagent via `invoke_subagent` specifying:
     - `TypeName`: `self`
     - `Role`: The assigned role name (e.g. `Core Systems Engineer`, `Desktop UI Engineer`)
     - `Model`: The assigned model tier (`pro` vs `flash`)
     - `Prompt`: Detailed description of the task, user feedback, relevant files, and required verification test commands.
  3. Audit the subagent's completion report and verification evidence before updating `.agents/checkpoint.json`.
  ```
- **Triage Matrix**: Maps task descriptions to the appropriate `.agents/skills/<track>/`.
- **Halt-on-Ambiguity**: Mandates escalating unstated assumptions on invariant-bearing tracks to `OPEN_QUESTIONS.md`.
- **Interruption & Resume Protocol**:
  ```markdown
  ## Resume Protocol
  On receiving a "continue", "resume", or recovery prompt:
  1. Inspect `.agents/checkpoint.json` and `git status` before executing any commands.
  2. Never restart a task from the beginning.
  3. Verify the sanity of partial changes before proceeding.
  ```
- **Circuit Breaker Enforcement**:
  ```markdown
  ## Circuit Breaker Protocol
  Before dispatching a subagent for a gate retry on an existing work order:
  1. Read the work order's attempt counter from `.agents/checkpoint.json`.
  2. If the counter is at or above the track's stated ceiling (default 3):
     - Do NOT dispatch another attempt.
     - Write a breach record (work order, track, gate, prior attempts' verification output, timestamp).
     - Escalate via `ask_question` (or `OPEN_QUESTIONS.md` if unavailable) and halt.
  3. If under the ceiling, dispatch the subagent, then increment the counter ONLY after a verification result is observed — never on the subagent's self-report of success.
  4. Pre-gate and post-gate counters on a dual-gated track are tracked and checked independently.
  ```

### B. Track Definitions (`.agents/skills/<track-name>/SKILL.md`)
Each track is structured as an Antigravity skill:
```markdown
---
name: <track-name>
description: >-
  Work-routing track for <domain/task type>. Routes tasks concerning <entities>
  and enforces <single-gated/dual-gated> verification.
---

# Track: <Track Name>

## Assigned Role: <Role Name>
- **Model Tier**: pro (or flash)
- **Tool Scoping**: Read, edit, run command (`<specific verification command>`)

## Workflow Steps
1. Pre-work order inspection (if dual-gated).
2. Execute implementation in batch (or step-by-step).
3. Run verification: `<verification command>`.
4. Render completion report adhering to the reporting contract.
```

### C. Specialized Roles (Antigravity Subagent Declarations)
In Antigravity 2.0, roles can be invoked as subagents with scoped capabilities:
- **Model Tiering**:
  - `flash`: For low-risk, mechanical, cosmetic, or documentation tracks.
  - `pro`: For dual-gated tracks, architectural design, and irreversible data logic.
- **Tool Scoping**:
  - Set `enable_write_tools: false` for read-only audit roles.
  - Scope terminal access to specific verification binaries.

### D. Lifecycle Gates (`.agents/hooks.json`) & Portable Scripts
Deterministic enforcement through Antigravity lifecycle hooks — this is Antigravity's real enforcement artifact per the Mechanical Enforcement Protocol (`decision_procedure.md`), not an optional extra. Every Hard Invariant and dual-gated track must have its verification logic written into a real hook script here (or a git pre-commit hook / CI check per the same protocol), not merely described in `AGENTS.md` prose:
```json
{
  "pre_tool": [
    {
      "tool": "run_command",
      "command_pattern": "git commit.*",
      "hook_script": ".agents/scripts/verify_gates.sh"
    }
  ]
}
```

#### Portable Gate Enforcement Script Template (`.agents/scripts/verify_gates.sh`)
Generated scripts must be **100% portable** with zero machine-specific paths:
```bash
#!/usr/bin/env bash
# ==============================================================================
# Mechanical Gate Enforcement Script (Portable, Fail-Closed)
# Returns Exit Code 2 on Gate Failure
# ==============================================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"

# Global baseline check (e.g. typecheck, fast lint)
echo "=== [Gate 1] TypeScript Strict Typecheck ==="
if ! npx tsc --noEmit; then
  echo "❌ Gate 1 FAILED: Compilation errors."
  exit 2
fi

# Path-aware domain invariant check (run heavy domain suite if domain files touched)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
if echo "$STAGED_FILES" | grep -qE "(src/lib/erp|supabase/|accounting/)" || [ -z "$STAGED_FILES" ]; then
  echo "=== [Gate 2] Financial Invariants & Statutory Suite ==="
  if ! npm test; then
    echo "❌ Gate 2 FAILED: Domain invariants broken."
    exit 2
  fi
fi

echo "✓ ALL GATES PASSED."
exit 0
```

#### Git Pre-Commit Hook Template (`.git/hooks/pre-commit`)
```bash
#!/usr/bin/env bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$(dirname "$0")/../.." && pwd)"
exec bash "${REPO_ROOT}/.agents/scripts/verify_gates.sh" "$@"
```

---

## 4. Standard Generated Workspace Layout

When the user approves Step 5 in Antigravity, write the harness directly inside the **target git repository root** (co-located with `.git/`):

```text
<target_git_repository_root>/          # MUST be the git repo root, NEVER a parent folder
├── AGENTS.md                         # Single authoritative orchestrator, routing, & resume protocol
├── PROJECT_SPEC.md                   # Grounded project specification
├── HARNESS_RATIONALE.md              # Design rationale for all tracks and invariants
├── ONBOARDING.md                     # Practical quick-reference for developers
└── .agents/
    ├── checkpoint.json               # Active task state and evidence log
    ├── harness_log.json              # Append-only structured changelog (version, change_type, entities_affected, rationale)
    ├── hooks.json                    # Deterministic gating hooks (mandatory for Hard Invariants/dual-gates — real scripts, not stubs)
    ├── scripts/
    │   └── verify_gates.sh           # Portable fail-closed verification script (Zero absolute paths)
    └── skills/
        ├── <track-1>/
        │   └── SKILL.md              # Track 1 workflow & verification command
        └── <track-2>/
            └── SKILL.md              # Track 2 workflow & verification command
```

> [!WARNING]
> **No Parent Workspace Dumping**: If the IDE opened a parent folder containing the git repository inside a subdirectory (e.g. workspace is `~/project/` but git repo is `~/project/Real-Estate-Platform`), ALL harness files must live inside `~/project/Real-Estate-Platform/`. Never write harness files into `~/project/`.
> **Single Orchestrator Rule**: Do NOT create a duplicate `.agents/rules/harness.md` mirroring `AGENTS.md`. `AGENTS.md` at the repo root is the single authoritative always-on directive. Preserve framework-generated notices (such as Next.js agent blocks) in their respective sub-packages.

---

## 5. Interactive Questioning Protocol (`ask_question`)

In Antigravity, never present multiple-choice questionnaires, gap resolutions, or approval gates as static text blocks in markdown. Instead, invoke the native `ask_question` tool to display an interactive UI dialog.

### Usage Standards
1. **Recommendations**: Always prefix your recommended choice with `(Recommended)`.
2. **Options Format**: Format options as the user's direct response (e.g. `"Option A: In-browser web portal (QR code)"`).
3. **No Redundant 'Other'**: Do not add an "Other" option; the Antigravity UI automatically provides a write-in input box.
4. **Key Lifecycle Invocations**:
   - **Step 0 Monorepo**: Selecting between a shared vs. split harness.
   - **Mode 1 Genesis Gaps**: Selecting tech stack, mobile companion strategy, and directory streaming scope.
   - **Mode 2 Adoption Hypotheses**: Confirming whether an unusual pattern is intentional domain logic or technical debt.
   - **Mode 3 Audit Entry Points**: Choosing between Full Audit (3a), Quick Fix (3b), and Behavior Feedback (3c).
   - **Step 4 Tool Installs**: Individual approval for each proposed new dependency.
   - **Step 5 Approval Gate (MANDATORY TOOL CALL)**: Explicit confirmation to write the harness to disk. In Antigravity, **you MUST invoke `ask_question` and stop calling tools to end your turn**. You are strictly forbidden from calling `write_to_file`, `replace_file_content`, or shell heredocs in the same turn. Files may only be created in the subsequent turn after the user explicitly selects "(Recommended) Approve".

