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
| **Gating & Circuit Breakers**| Lifecycle Hooks | `.agents/hooks.json` | Runs automated verification or blocking scripts before/after tool actions. |
| **Tool Provisioning** | Project MCP Servers | `.agents/mcp_config.json` | Connects external domain tools, live database inspectors, or testing runners. |
| **State & Checkpoints** | Persistent Project State | `.agents/checkpoint.json` & `.agents/harness_log.json` | Persistent record of active steps, verified evidence, and version history. |
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

### D. Lifecycle Gates (`.agents/hooks.json`)
Deterministic enforcement through Antigravity lifecycle hooks:
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

---

## 4. Standard Generated Workspace Layout

When the user approves Step 5 in Antigravity, write the harness to this structure:

```text
<workspace_root>/
├── AGENTS.md                         # Always-on orchestrator, routing, & resume protocol
├── PROJECT_SPEC.md                   # Grounded project specification
├── HARNESS_RATIONALE.md              # Design rationale for all tracks and invariants
├── ONBOARDING.md                     # Practical quick-reference for developers
└── .agents/
    ├── checkpoint.json               # Active task state and evidence log
    ├── harness_log.json              # Version history and audit trail
    ├── hooks.json                    # Deterministic gating hooks (optional)
    └── skills/
        ├── <track-1>/
        │   └── SKILL.md              # Track 1 workflow & verification command
        └── <track-2>/
            └── SKILL.md              # Track 2 workflow & verification command
```

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
   - **Step 5 Approval Gate**: Explicit confirmation to write the harness to disk.

