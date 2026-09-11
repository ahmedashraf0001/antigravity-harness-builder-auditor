# Cursor Primitives & File Layout Mapping

When Step 3.6 detects **Cursor** (`.cursor/` directory or explicit user statement), map the derived harness directly to Cursor's native primitives. As of Cursor's current release, subagents, skills, and blocking hooks are all first-class — treat this host at the same enforcement fidelity as Antigravity and Claude Code, not as a markdown-only fallback.

---

## 1. Cursor Customization Hierarchy

Cursor resolves customizations in this order (highest to lowest priority):
1. **Local Project Overrides**: `.cursor/hooks.json` / rule files marked local-only (not committed).
2. **Project Configuration**: `.cursor/rules/*.mdc`, `.cursor/agents/*.md`, `.cursor/skills/*/SKILL.md`, `.cursor/hooks.json`, `.cursor/mcp.json` at the repository root (committed, team-shared).
3. **AGENTS.md**: a single-file alternative or supplement to `.cursor/rules/` for simpler setups — Cursor reads this if present.
4. **User-Level Configuration**: `~/.cursor/agents/`, `~/.cursor/hooks.json`, `~/.cursor/rules/` (machine-wide, personal).

---

## 2. Direct Primitive Mapping

| Harness Concept | Cursor Native Primitive | Target File / Location | Purpose & Behavior |
| :--- | :--- | :--- | :--- |
| **Orchestrator & Routing** | Always-Apply Rule or `AGENTS.md` | `.cursor/rules/000-orchestrator.mdc` (with `alwaysApply: true`) or `AGENTS.md` | Always-on context loaded every session. Holds the triage matrix, Section 0, and the Interruption & Resume Protocol. |
| **Work-Routing Tracks** | Skills | `.cursor/skills/<track>/SKILL.md` | Model-invoked via `/skill-name` or `@skill-name`, or auto-triggered from the skill's description — progressive disclosure, same mechanism as Claude Code Skills. |
| **Specialized Roles** | Subagents | `.cursor/agents/<role>.md` | Each subagent runs with its **own context**, can be launched via the `Task` mechanism, and inherits the parent's tools by default unless explicitly restricted — scope explicitly per 4e/4f rather than relying on the default. |
| **Gating** | Lifecycle Hooks | `.cursor/hooks.json` | Real mechanical backstop: `beforeShellExecution`, `beforeMCPExecution`, `preToolUse` hooks can return `"permission": "deny"` (or exit code `2`) to block the action outright before it runs. |
| **Circuit Breakers** | Always-Apply Rule + Persistent State | `.cursor/rules/000-orchestrator.mdc` (enforcement logic) & `.cursor/checkpoint.json` (counter) | Attempt counters live in checkpoint state, read/incremented by the orchestrator rule logic, and can be cross-checked by a `preToolUse` hook for gates that correspond to a real tool call. |
| **Tool Provisioning** | Project MCP Servers + Per-Subagent Tool Scope | `.cursor/mcp.json` and each subagent's declared tool access | Connects external domain tools (DB inspectors, test runners); subagent tool scope should be explicitly restricted in the subagent file rather than left at the inherited default. |
| **State & Checkpoints** | Persistent Project State | `.cursor/checkpoint.json` & `.cursor/harness_log.json` | `checkpoint.json` holds active task state, evidence, and circuit breaker counters. `harness_log.json` holds the append-only structured changelog per the Versioning & Migration Protocol. |
| **Specs & Rationale** | Plain Project Documents | Project root (`PROJECT_SPEC.md`, `HARNESS_RATIONALE.md`, `ONBOARDING.md`) | Referenced from the orchestrator rule; opened as ordinary files in the editor. |
| **Interactive Questioning** | No native modal equivalent | In-conversation | Cursor's Agent chat has no Antigravity-style `ask_question` dialog. Use the fallback procedure in §5. |

---

## 3. Concrete Implementation Details

### A. The Always-On Orchestrator (`.cursor/rules/000-orchestrator.mdc`)
Use an always-applying rule file (frontmatter `alwaysApply: true`, no glob restriction) so it loads on every prompt in this project, equivalent to Antigravity's `AGENTS.md`. If the project already uses a single `AGENTS.md` convention instead of `.cursor/rules/`, write Section 0 there and note the choice at Step 5.

- **Section 0: Zero Direct Application Writes (Mandatory Subagent Delegation)**:
  ```markdown
  ---
  description: Always-on orchestrator directive — routing, delegation, resume, and circuit breaker protocol
  alwaysApply: true
  ---
  ## 0. MANDATORY: Zero Direct Application Writes (Subagent Delegation)
  The primary agent is STRICTLY FORBIDDEN from writing or editing application code directly for any implementation or bug-fix task.
  Under NO circumstances — including bug fixes, debugging, error remediation, or small tweaks — may the primary agent edit source code with its own hands.

  For EVERY coding task or bug report, the primary agent MUST:
  1. Determine the target track (`.cursor/skills/<track>/SKILL.md`) and assigned role.
  2. IMMEDIATELY delegate to the subagent declared in `.cursor/agents/<role>.md`, passing a self-contained work order (task description, relevant files, required verification command(s)).
  3. Audit the subagent's completion report and verification evidence before updating `.cursor/checkpoint.json`.
  ```
  > **Enforcement note**: Pair Section 0 with a **`preToolUse` hook** scoped to edit-type tool calls on application source paths (see §3.D), so the rule is backed by a real block rather than resting on the model's own compliance. Cursor's default hook behavior is **fail-open** (a crashing or malformed hook allows the action through) — set `"failClosed": true` on this hook entry explicitly, since a fail-open Section 0 gate is not a gate.
- **Triage Matrix**: Maps task descriptions to the appropriate `.cursor/skills/<track>/`.
- **Halt-on-Ambiguity**: Mandates escalating unstated assumptions on invariant-bearing tracks to `OPEN_QUESTIONS.md`.
- **Interruption & Resume Protocol**:
  ```markdown
  ## Resume Protocol
  On receiving a "continue", "resume", or recovery prompt:
  1. Inspect `.cursor/checkpoint.json` and `git status` before executing any commands.
  2. Never restart a task from the beginning.
  3. Verify the sanity of partial changes before proceeding.
  ```
- **Circuit Breaker Enforcement**:
  ```markdown
  ## Circuit Breaker Protocol
  Before dispatching a subagent for a gate retry on an existing work order:
  1. Read the work order's attempt counter from `.cursor/checkpoint.json`.
  2. If the counter is at or above the track's stated ceiling (default 3):
     - Do NOT dispatch another attempt.
     - Write a breach record (work order, track, gate, prior attempts' verification output, timestamp).
     - Escalate to the human via the fallback questioning procedure (§5) and halt.
  3. If under the ceiling, dispatch the subagent, then increment the counter ONLY after a verification result is observed — never on the subagent's self-report of success.
  4. Pre-gate and post-gate counters on a dual-gated track are tracked and checked independently.
  ```

### B. Track Definitions (`.cursor/skills/<track-name>/SKILL.md`)
```markdown
---
name: <track-name>
description: >-
  Work-routing track for <domain/task type>. Routes tasks concerning <entities>
  and enforces <single-gated/dual-gated> verification.
---

# Track: <Track Name>

## Assigned Role: <Role Name> (`.cursor/agents/<role-slug>.md`)
- **Model Tier**: match to project's available models — cheaper/faster for mechanical work, strongest for dual-gated tracks.
- **Tool Scoping**: explicitly restricted per 4e/4f — do not rely on Cursor's default inherited-tools behavior for a role that should not have broad access.

## Workflow Steps
1. Pre-work order inspection (if dual-gated).
2. Execute implementation in batch (or step-by-step).
3. Run verification: `<verification command>`.
4. Render completion report adhering to the reporting contract.
```

### C. Specialized Roles (`.cursor/agents/<role-slug>.md`)
```markdown
---
name: <role-slug>
description: >-
  Use this agent for <track domain>. Handles <responsibilities>. Do not use
  for <explicitly excluded work> — route that to <other-role-slug> instead.
tools: <explicit allow-list, e.g. read, edit, terminal:pytest>
model: <tier>
---

You are the <Role Name>. Your scope is strictly <track(s)>.
<Full role prompt: responsibilities, verification obligations, reporting contract, escalation rules.>
```
- **Important**: Cursor subagents inherit all of the parent's tools (including MCP tools) by default unless the subagent file explicitly restricts them. This means 4e (Minimal Tool Scoping) is **not automatic** in Cursor the way it is in Claude Code's `tools:` allow-list — the harness must write an explicit restriction into every role file, and Step 4.1 item 6 must verify the restriction is actually present in the file, not merely intended.
- **Nesting**: subagents can launch child subagents up to one level deep (a subagent's own subagent cannot launch further ones). Do not design roles that assume deeper nesting.
- Check `.cursor/agents/` into version control so the whole team shares role definitions.

### D. Lifecycle Hooks (`.cursor/hooks.json`)
Deterministic, mechanical enforcement — Cursor's actual teeth:
```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": ".cursor/hooks/verify_gate.sh",
        "matcher": "edit|write",
        "failClosed": true
      }
    ],
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/block_destructive.sh",
        "failClosed": true
      }
    ]
  }
}
```
- The hook script receives JSON on stdin (`command`, `cwd`, or `tool_name`/`tool_input` depending on event) and returns JSON on stdout:
  - `{"permission": "allow"}` → proceeds.
  - `{"permission": "deny", "user_message": "...", "agent_message": "..."}` → **blocked**, both the user and the agent see a reason.
  - `{"permission": "ask"}` → prompts the human for approval before proceeding.
  - Exit code `2` is equivalent to a deny response.
- **`failClosed` matters**: by default Cursor hooks **fail open** — a crashing script, a timeout, or malformed JSON output silently lets the action through. Set `"failClosed": true` on every hook entry that backs a Hard Invariant or Section 0 — an unset fail-open hook on an invariant-bearing gate is a Step 4.1 failure (cite the missing flag).
- **Use this for**: enforcing Section 0 (`preToolUse` matcher on edit-type tools scoped to application source paths), gating destructive shell commands (`beforeShellExecution`, deny on `rm -rf`, `git push --force`, unreviewed migrations), and pre-commit verification (`beforeShellExecution` matcher on `git commit`, run the track's verification command and deny on non-zero exit).
- **Write real scripts, not stubs**: a hook entry whose script always returns `{"permission": "allow"}` is decoration, not enforcement — generate the actual gate logic from the harness's derived invariants, per the Mechanical Enforcement Protocol (`decision_procedure.md`). Step 6's Mechanical Enforcement Execution Test actually runs this script against a synthetic pass and fail case, so a stub is caught rather than merely discouraged.

---

## 4. Standard Generated Workspace Layout

```text
<workspace_root>/
├── PROJECT_SPEC.md                   # Grounded project specification
├── HARNESS_RATIONALE.md              # Design rationale for all tracks and invariants
├── ONBOARDING.md                     # Practical quick-reference for developers
└── .cursor/
    ├── rules/
    │   └── 000-orchestrator.mdc      # Always-on orchestrator, routing, & resume protocol
    ├── hooks.json                    # Deterministic gating hooks (failClosed on invariant gates)
    ├── hooks/
    │   ├── verify_gate.sh            # Real enforcement script(s) — not a stub
    │   └── block_destructive.sh
    ├── mcp.json                      # Project MCP servers (if any tool provisioning needs it)
    ├── checkpoint.json               # Active task state, evidence log, circuit breaker counters
    ├── harness_log.json              # Append-only structured changelog
    ├── agents/
    │   ├── <role-1>.md               # Subagent: role prompt, tool scope, model tier
    │   └── <role-2>.md
    └── skills/
        ├── <track-1>/
        │   └── SKILL.md              # Track 1 workflow & verification command
        └── <track-2>/
            └── SKILL.md              # Track 2 workflow & verification command
```

If the project uses the simpler `AGENTS.md`-only convention instead of `.cursor/rules/`, write the orchestrator content there and note the substitution explicitly in `HARNESS_RATIONALE.md`.

---

## 5. Interactive Questioning Fallback

Cursor's Agent chat has no native `ask_question`-equivalent modal. Resolution order:
1. Check the available tool list at Step 3.6 time for any interactive elicitation tool exposed by the host or an installed extension; use it if present.
2. Otherwise, present the question as clearly formatted Markdown with a stated recommended option and explicit options list, then **wait for the user's literal reply** before proceeding. Never treat silence or moving to the next topic as an implicit selection.
3. Do not simulate interactive UI affordances (fake buttons/checkboxes) that don't actually exist in this host.

---

## 6. Known Gaps vs. Antigravity (Disclose at Step 5)

- No first-class `ask_question` modal — degraded to the fallback in §5.
- Subagent tool inheritance defaults to "inherit everything," the inverse of Claude Code's default-deny `tools:` list — every role file must carry an explicit restriction, and this is more error-prone to omit; flag this specifically when reviewing 4f justifications during Step 4.1.
- Hooks fail open by default — every invariant-bearing or Section-0-backing hook must explicitly set `failClosed: true`, or the enforcement is silently weaker than it appears.
