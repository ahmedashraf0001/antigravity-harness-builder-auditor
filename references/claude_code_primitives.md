# Claude Code Primitives & File Layout Mapping

When Step 3.6 detects **Claude Code** (`.claude/` directory, `CLAUDE.md` at repo root, or explicit user statement), map the derived harness directly to Claude Code's native primitives. Claude Code has genuine subagent isolation and genuine mechanical enforcement via hooks — this is not a "prose-only" host, and the harness must use both, not fall back to markdown-only conventions.

---

## 1. Claude Code Customization Hierarchy

Claude Code resolves customizations in this order (highest to lowest priority):
1. **Enterprise Managed Policy Settings**: platform-specific managed settings file (out of scope for this builder; read-only for the agent).
2. **Local Project Settings**: `.claude/settings.local.json` (not committed — personal overrides).
3. **Project Settings**: `.claude/settings.json` (committed — team-shared).
4. **User Settings**: `~/.claude/settings.json` (machine-wide).
5. **Project Directive**: `CLAUDE.md` at the repository root (always-on context, read every session).

---

## 2. Direct Primitive Mapping

| Harness Concept | Claude Code Native Primitive | Target File / Location | Purpose & Behavior |
| :--- | :--- | :--- | :--- |
| **Orchestrator & Routing** | Project Memory File | `CLAUDE.md` | Always-on context loaded every session. Holds the triage matrix, Section 0, and the Interruption & Resume Protocol. |
| **Work-Routing Tracks** | Skills | `.claude/skills/<track>/SKILL.md` | Model-invoked, progressively disclosed: Claude Code reads the frontmatter `description` and loads the full body only when a task matches. |
| **Specialized Roles** | Subagents | `.claude/agents/<role>.md` (project) or `~/.claude/agents/<role>.md` (personal) | Each subagent is a Markdown file with YAML frontmatter (`name`, `description`, `tools`, `model`) and runs in its **own context window** with independently scoped tool access — genuine isolation, not a prompt convention. |
| **Gating** | Lifecycle Hooks | `.claude/settings.json` → `hooks` field | Mechanical backstop: `PreToolUse` hooks can inspect a tool call before it runs and block it outright (see §3.D). This is real enforcement — it runs outside the model's control and the model cannot talk its way past it. |
| **Circuit Breakers** | Always-On Directive + Persistent State | `CLAUDE.md` (enforcement logic) & `.claude/checkpoint.json` (counter) | Attempt counters are data, not hook config — they must survive a session restart, so they live in checkpoint state and are read/incremented by the orchestrator logic described in `CLAUDE.md`, cross-checked by a `PreToolUse` hook where the gate corresponds to a real tool call (e.g. a commit). |
| **Tool Provisioning** | MCP Servers + Per-Subagent `tools:` Field | `.mcp.json` (project-scoped MCP servers) and each subagent's frontmatter `tools:` list | Subagent tool access is allow-listed per role directly in frontmatter — this is a structural enforcement point, not a suggestion: a subagent with `tools: Read, Grep, Glob` physically cannot invoke `Bash` or `Edit`. |
| **State & Checkpoints** | Persistent Project State | `.claude/checkpoint.json` & `.claude/harness_log.json` | `checkpoint.json` holds active task state, evidence, and circuit breaker counters. `harness_log.json` holds the append-only structured changelog per the Versioning & Migration Protocol. |
| **Specs & Rationale** | Plain Project Documents | Project root (`PROJECT_SPEC.md`, `HARNESS_RATIONALE.md`, `ONBOARDING.md`) | Claude Code has no dedicated rendering pane; these are read as ordinary Markdown files, referenced from `CLAUDE.md`. |
| **Interactive Questioning** | No native equivalent — use `AskUserQuestion` if available, else structured Markdown | In-conversation | Claude Code does not have an Antigravity-style modal `ask_question` UI. If the `AskUserQuestion` tool is present in the environment, use it (it renders selectable options in supported clients). Otherwise, present a clearly labeled question with a recommended option and wait for an explicit reply before proceeding — never silently assume an answer. |

---

## 3. Concrete Implementation Details

### A. The Always-On Orchestrator (`CLAUDE.md`)
Placed at the repository root. Claude Code reads this file automatically on every session in this project. It MUST be structured with Section 0 prominently at the top:

- **Section 0: Zero Direct Application Writes (Mandatory Subagent Delegation)**:
  ```markdown
  ## 0. MANDATORY: Zero Direct Application Writes (Subagent Delegation)
  The primary agent is STRICTLY FORBIDDEN from writing or editing application code directly (`Edit`, `Write`) for any implementation or bug-fix task.
  Under NO circumstances — including bug fixes, debugging, error remediation, or small tweaks — may the primary agent edit source code with its own hands.

  For EVERY coding task or bug report, the primary agent MUST:
  1. Determine the target track (`.claude/skills/<track>/SKILL.md`) and assigned role.
  2. IMMEDIATELY delegate via the `Task` tool, specifying:
     - `subagent_type`: the role's declared name in `.claude/agents/<role>.md`
     - `description`: a short summary of the work order
     - `prompt`: detailed task description, user feedback, relevant files, and required verification command(s)
  3. Audit the subagent's completion report and verification evidence before updating `.claude/checkpoint.json`.
  ```
  > **Enforcement note**: Because plain prose alone can be argued around under pressure, pair Section 0 with a **`PreToolUse` hook on `Edit`/`Write`** (see §3.D) scoped to application source paths, so a violation is mechanically blocked — not just discouraged — whenever the host supports it. If the hook cannot be installed (see §5), Section 0 is advisory-only and this must be disclosed to the human at Step 5, per the Non-Negotiables.
- **Triage Matrix**: Maps task descriptions to the appropriate `.claude/skills/<track>/`.
- **Halt-on-Ambiguity**: Mandates escalating unstated assumptions on invariant-bearing tracks to `OPEN_QUESTIONS.md`.
- **Interruption & Resume Protocol**:
  ```markdown
  ## Resume Protocol
  On receiving a "continue", "resume", or recovery prompt:
  1. Inspect `.claude/checkpoint.json` and `git status` before executing any commands.
  2. Never restart a task from the beginning.
  3. Verify the sanity of partial changes before proceeding.
  ```
- **Circuit Breaker Enforcement**:
  ```markdown
  ## Circuit Breaker Protocol
  Before dispatching a subagent for a gate retry on an existing work order:
  1. Read the work order's attempt counter from `.claude/checkpoint.json`.
  2. If the counter is at or above the track's stated ceiling (default 3):
     - Do NOT dispatch another attempt.
     - Write a breach record (work order, track, gate, prior attempts' verification output, timestamp).
     - Escalate to the human (via `AskUserQuestion` if available, else `OPEN_QUESTIONS.md`) and halt.
  3. If under the ceiling, dispatch the subagent, then increment the counter ONLY after a verification result is observed — never on the subagent's self-report of success.
  4. Pre-gate and post-gate counters on a dual-gated track are tracked and checked independently.
  ```

### B. Track Definitions (`.claude/skills/<track-name>/SKILL.md`)
Each track is structured as a Claude Code Skill:
```markdown
---
name: <track-name>
description: >-
  Work-routing track for <domain/task type>. Routes tasks concerning <entities>
  and enforces <single-gated/dual-gated> verification.
---

# Track: <Track Name>

## Assigned Role: <Role Name> (`.claude/agents/<role-slug>.md`)
- **Model Tier**: opus/sonnet (or haiku for mechanical work — match to project's available models)
- **Tool Scoping**: Read, Edit, Bash (scoped to `<specific verification command>` only)

## Workflow Steps
1. Pre-work order inspection (if dual-gated).
2. Execute implementation in batch (or step-by-step).
3. Run verification: `<verification command>`.
4. Render completion report adhering to the reporting contract.
```

### C. Specialized Roles (Claude Code Subagent Files)
Each role is declared as its own file, checked into `.claude/agents/` so the whole team shares it:
```markdown
---
name: <role-slug>
description: >-
  Use this agent for <track domain>. Handles <responsibilities>. Do not use
  for <explicitly excluded work> — route that to <other-role-slug> instead.
tools: Read, Edit, Bash
model: sonnet
---

You are the <Role Name>. Your scope is strictly <track(s)>.
<Full role prompt: responsibilities, verification obligations, reporting contract, escalation rules.>
```
- **Model Tiering**: Assign per 4a–4h stakes — cheaper/faster models for cosmetic or mechanical tracks, the strongest available model for dual-gated or architecture-bearing tracks.
- **Tool Scoping**: The `tools:` frontmatter field is a hard allow-list — a subagent with `tools: Read, Grep, Glob` cannot call `Edit` or `Bash` even if the role prompt tried to instruct it to. Use this to make 4e (Minimal Tool Scoping) structurally true, not just stated.
- **Isolation**: Each subagent invocation runs in its own context window and does not inherit the orchestrator's conversation history unless explicitly passed in the `prompt` — write self-contained work orders.

### D. Lifecycle Hooks (`.claude/settings.json`)
Deterministic, mechanical enforcement — this is Claude Code's actual teeth, equivalent in strength to Antigravity's `hooks.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/scripts/verify_gate.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```
- The hook script reads the JSON payload on stdin (`tool_name`, `tool_input`, `cwd`), applies project-specific gate logic (e.g. "block edits to `payments/` unless a work order for the Payments track is currently open in `.claude/checkpoint.json`"), and:
  - Exit code `0` → tool call proceeds.
  - Exit code `2` → tool call is **blocked**, and stderr is surfaced to the model as the reason.
  - Alternatively, emit `{"hookSpecificOutput": {"permissionDecision": "deny", "additionalContext": "<reason>"}}` on stdout for the same effect with a structured message.
- **Use this for**: enforcing Section 0 (block `Edit`/`Write` from the primary agent's own context on application source paths — a subagent's own `Edit` calls are a separate tool invocation from a separate context and are not blocked by the same matcher unless the hook explicitly checks the caller), gating destructive Bash commands (`matcher: "Bash"`, deny on patterns like `rm -rf`, `git push --force`, migration commands outside a dual-gate window), and pre-commit verification (`matcher: "Bash"`, pattern `git commit.*`, run the track's verification command and deny the commit on non-zero exit).
- **Write real scripts, not stubs**: A hook entry pointing at a script that always exits 0 is decoration. `.claude/scripts/verify_gate.sh` must be generated with actual logic derived from the harness's gates — this is the concrete artifact required by the Mechanical Enforcement Protocol (`decision_procedure.md`) for every Hard Invariant/dual-gated track; do not ship a hooks.json that only logs. Step 6's Mechanical Enforcement Execution Test will actually invoke this script against a synthetic pass and fail case, so a stub will be caught rather than merely discouraged.

---

## 4. Standard Generated Workspace Layout

When the user approves Step 5 on Claude Code, write the harness directly inside the **target git repository root** (co-located with `.git/`):

```text
<target_git_repository_root>/          # MUST be the git repo root, NEVER a parent folder
├── CLAUDE.md                         # Always-on orchestrator, routing, & resume protocol
├── PROJECT_SPEC.md                   # Grounded project specification
├── HARNESS_RATIONALE.md              # Design rationale for all tracks and invariants
├── ONBOARDING.md                     # Practical quick-reference for developers
├── .mcp.json                         # Project-scoped MCP servers (if any tool provisioning needs it)
└── .claude/
    ├── settings.json                 # Hooks configuration (committed, team-shared)
    ├── checkpoint.json               # Active task state, evidence log, circuit breaker counters
    ├── harness_log.json              # Append-only structured changelog
    ├── scripts/
    │   └── verify_gate.sh            # Real enforcement script (100% portable, Zero absolute paths)
    ├── agents/
    │   ├── <role-1>.md               # Subagent: role prompt, tool scope, model tier
    │   └── <role-2>.md
    └── skills/
        ├── <track-1>/
        │   └── SKILL.md              # Track 1 workflow & verification command
        └── <track-2>/
            └── SKILL.md              # Track 2 workflow & verification command
```

---

## 5. Interactive Questioning Fallback

Claude Code does not ship an Antigravity-style native modal (`ask_question`) by default. Resolution order:
1. If the environment exposes an `AskUserQuestion`-style tool (check the available tool list at Step 3.6 time — do not assume), use it for gap resolution, stack selection, and approvals, matching the same usage standards as Antigravity's `ask_question` (recommended option prefixed, no redundant "Other").
2. If no such tool is present, present the question as clearly formatted Markdown with a stated recommended option and explicit options list, then **wait for the user's literal reply** before proceeding. Never treat silence, a partial answer, or moving on to the next topic as an implicit selection.
3. Do not simulate an interactive UI in Markdown (e.g. fake checkboxes) — that implies affordances that do not exist in this host and can mislead the user into thinking they're clicking something.

---

## 6. Known Gaps vs. Antigravity (Disclose at Step 5)

- No native rendering pane for `PROJECT_SPEC.md`/`HARNESS_RATIONALE.md` — they are plain files the user opens manually.
- No first-class `ask_question` modal — degraded to the fallback in §5.
- Section 0 enforcement depends on a real `PreToolUse` hook existing and being correctly scoped; if the user's Claude Code version or settings prevent hooks (e.g. hooks disabled by enterprise policy), Section 0 reduces to a prompted convention only — state this explicitly rather than implying mechanical enforcement that isn't actually present.
