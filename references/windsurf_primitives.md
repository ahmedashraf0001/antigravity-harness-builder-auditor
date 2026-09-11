# Devin Desktop (formerly Windsurf) Primitives & File Layout Mapping

**Staleness note for future readers of this file**: Cognition renamed Windsurf to **Devin Desktop** and this product's agent runtime has changed materially and repeatedly since. This file was last checked against `docs.devin.ai` in September 2026. Before trusting any specific claim below — especially the Subagents toggle state and whether Cascade is still present — re-check the current docs (`docs.devin.ai/desktop/devin-local`, `docs.devin.ai/desktop/devin-desktop-faq`, `docs.devin.ai/desktop/changelog`) rather than assuming this file is still accurate; this product's agent runtime is evolving faster than most others this builder supports.

When Step 3.6 detects **Devin Desktop** (`.windsurf/` directory — the legacy/still-used config path — `.devin/` directory, `AGENT.md`, or explicit user statement that they're on "Windsurf" or "Devin Desktop"; the two names refer to the same product, Windsurf having been rebranded), this host requires an extra sub-step before mapping, because the product currently ships **two coexisting local agents** with materially different capabilities:

- **Cascade** (the original agent, still present and still the automatic fallback): rules, workflows, hooks — **no genuine subagent isolation**.
- **Devin Local** (the newer local agent, shared with Devin CLI, intended to eventually replace Cascade): rules, skills, hooks, and **subagents** — but subagents are gated behind a **"Subagents (Preview)" toggle in Devin Settings that is not on by default**, and several Cascade capabilities (Fast Context, App Deploys, browser previews, Conversation Sharing) are not yet available in Devin Local at all. Treat "Devin Local is in use" and "Devin Local's subagents are actually available" as two separate facts to confirm, not one.

Do not assume either agent, or that "Devin Local present" implies "subagents available." Detect both which agent is active and whether its Subagents toggle is on before deriving role/subagent structure, since the correct mapping for Section 0 differs materially across all three resulting states (Cascade / Devin Local without subagents / Devin Local with subagents enabled).

---

## 0. Runtime Detection (Required Before Mapping)

1. **Ask directly rather than inferring from dotfiles alone** — config file presence is a weaker signal here than the in-app agent selector, and this product's config layout has changed more than once: *"This project uses Devin Desktop (formerly Windsurf). Which local agent are you running — Cascade, or Devin Local? You can check via the agent selector in the bottom-right corner of the editor, or Windsurf Settings → the Agents tab. If you're on Devin Local, is the 'Subagents (Preview)' toggle in Devin Settings turned on?"*
2. If the user can't check directly, use dotfiles only as a fallback signal, cross-checked against the answer above rather than trusted alone:
   - `.devin/config.json` / `.devin/config.local.json` present → Devin Local has been used or configured for this project, but does **not** by itself confirm the Subagents toggle is on — that's a per-user Devin Settings preference, not a project file.
   - `.windsurf/rules/`, `.windsurf/workflows/`, or `.windsurf/hooks.json` present with no `.devin/` directory → likely Cascade, or Devin Local has not been configured for this project yet.
3. **Do not guess, and do not assume "newer must mean available."** The Section 0 enforcement mechanism differs structurally across all three states above — guessing wrong produces an unexecutable harness (e.g. wiring subagent-based delegation into a project where the toggle is off and every "subagent" call would simply fail or silently run in the parent's own context).
4. **Re-verify this file's claims before trusting them.** This product has changed its runtime defaults and even its own name more than once in recent months; a claim here that Devin Local subagents are "Preview-gated" or that Cascade is "still present" is a snapshot, not a permanent fact. If the user's description of what they're seeing in the editor doesn't match this file, trust the user and the current docs over this file.

Both agents share the same `hooks.json` mechanism and largely the same rules/skills conventions, so §§2–4 below note where they diverge.

---

## 1. Customization Hierarchy (Both Agents)

1. **Local/Personal**: `.devin/config.local.json` (gitignored) or workspace-local rule overrides.
2. **Project/Workspace**: `.windsurf/rules/`, `.windsurf/workflows/`, `.windsurf/hooks.json`, `.devin/config.json`, `agents/` (committed, team-shared).
3. **User-Level**: `~/.codeium/windsurf/` (Cascade) or `~/.config/devin/config.json` (Devin Local) — plus the per-user **Subagents (Preview)** toggle in Devin Settings, which is not a file this builder can inspect and must be confirmed by asking the user directly (Step 0 above).
4. **System/Enterprise-Level**: platform-specific managed hooks/settings, plus enterprise-level agent controls (e.g. an org-wide "Enable Cascade" toggle that can disable the legacy agent entirely) — out of scope for this builder; read-only for the agent.

---

## 2. Direct Primitive Mapping

| Harness Concept | Cascade Primitive | Devin Local Primitive | Target File / Location |
| :--- | :--- | :--- | :--- |
| **Orchestrator & Routing** | Always-on Rule | Always-on Rule / `AGENT.md` / `AGENTS.md` | `.windsurf/rules/000-orchestrator.md`, `AGENT.md`, or `AGENTS.md` (all three are read into the same rules engine — see §3.A) |
| **Work-Routing Tracks** | Workflows (slash-command scripts) | Skills (model-invoked, progressive disclosure) | `.windsurf/workflows/<track>.md` (Cascade) or Devin Local's skills convention |
| **Specialized Roles** | **No native subagent primitive** — see §3.B | Subagents (own conversation chain, shares tools/codebase context with parent) — **only if the Subagents (Preview) toggle is on**; if off, treat identically to Cascade for role-isolation purposes | `agents/<role>.md` (flat file) or `agents/<role>/AGENT.md` (directory form), Devin Local only, toggle-gated |
| **Gating** | Lifecycle Hooks | Lifecycle Hooks | `.windsurf/hooks.json` (both agents read this format; blocking is exit code `2` on pre-hooks only — post-hooks cannot block) |
| **Circuit Breakers** | Always-on Rule + Persistent State | Always-on Rule + Persistent State | Rule logic + `.windsurf/checkpoint.json` |
| **Tool Provisioning** | MCP Servers | MCP Servers + Permissions Model | `.windsurf/mcp_config.json` (Cascade) or `.devin/config.json` (Devin Local, includes fine-grained allow/deny/ask permission rules, replacing Cascade's auto-execution levels) |
| **State & Checkpoints** | Persistent Project State | Persistent Project State | `.windsurf/checkpoint.json` & `.windsurf/harness_log.json` |
| **Specs & Rationale** | Plain Project Documents | Plain Project Documents | Project root |
| **Interactive Questioning** | No native modal | No native modal | Fallback procedure, §6 |

---

## 3. Concrete Implementation Details

### A. The Always-On Orchestrator
Place at `.windsurf/rules/000-orchestrator.md`, or `AGENT.md`/`AGENTS.md` at the project root if the project already uses that convention — both agents' rules engines discover `AGENTS.md`/`agents.md` automatically and treat root-level files as always-on. This must be structured with Section 0 at the top, but **Section 0's content depends on which of the three detected states applies (Cascade / Devin Local without subagents / Devin Local with subagents enabled)**:

#### If Devin Local with the Subagents (Preview) toggle confirmed on:
```markdown
## 0. MANDATORY: Zero Direct Application Writes (Subagent Delegation)
The primary agent is STRICTLY FORBIDDEN from writing or editing application code directly for any implementation or bug-fix task.

For EVERY coding task or bug report, the primary agent MUST:
1. Determine the target track and assigned role.
2. IMMEDIATELY spawn a subagent (foreground or background) declared under `agents/<role>.md`, passing a self-contained work order.
3. Audit the subagent's completion report and verification evidence before updating `.windsurf/checkpoint.json`.
```
Pair with a `hooks.json` `pre_write_code` hook (see §3.D) scoped to application source paths so the rule has a mechanical backstop, not just prose. Note this is still labeled Preview by the vendor at time of writing — disclose that at Step 5 as a stability caveat, not just an enforcement-strength one: a Preview feature can change behavior or be pulled between sessions in a way a GA feature won't.

#### If Cascade, or Devin Local without the Subagents toggle confirmed on:
Neither has an isolated-context delegation target available — there is nothing to delegate *to* that provides real separation (Devin Local without the toggle behaves like Cascade for this purpose: same shared-context limitation, regardless of which agent name is showing in the editor). Do not claim subagent delegation is happening when it structurally cannot, and do not infer the toggle is on just because the project uses Devin Local for other reasons.

Instead, degrade Section 0 to the best-effort structural analog, **explicitly flagged as weaker**:
```markdown
## 0. Role Discipline (Best-Effort — No Subagent Isolation Available)
This project runs on [Cascade / Devin Local without Subagents enabled], which has no isolated-context
subagent primitive available. The following is a best-effort convention, not a mechanically enforced boundary:

1. Before starting implementation on any task, state which track and role (per HARNESS_RATIONALE.md)
   the work falls under, and open the corresponding workflow: `/[track-workflow-name]`.
2. Stay within that role's stated tool/file scope for the duration of the task — do not silently
   drift into another track's territory without explicitly re-declaring the switch.
3. This is advisory only. A `pre_write_code` hook (see §3.D) can mechanically block writes to
   paths outside the declared track's scope, and should be used wherever the harness has enough
   path-based structure to make that check meaningful — but it cannot verify *which role the agent
   currently believes itself to be acting as*, only *which files it is touching*. Role adherence
   itself still depends on the agent's own discipline in this runtime.
```
This must be disclosed plainly at Step 5: *"This project's harness currently has no subagent isolation available — [because it's on Cascade / because Devin Local's Subagents toggle isn't enabled]. Section 0 is enforced by convention and file-path hooks only, not by structural role separation. If you enable the Subagents (Preview) toggle in Devin Settings for Devin Local, the harness could gain genuine role isolation — want me to re-derive Section 0 assuming that, once you've confirmed it's on?"*

- **Triage Matrix**, **Halt-on-Ambiguity**, **Interruption & Resume Protocol**, and **Circuit Breaker Enforcement** sections follow the same content pattern as the other primitive files (see `antigravity_primitives.md` §3.A for the canonical wording), pointed at `.windsurf/checkpoint.json`.

### B. Track Definitions
- **Devin Local**: define tracks as skills, following the same `SKILL.md`-style frontmatter/description pattern as the other hosts, discovered per Devin Local's skills convention.
- **Cascade**: define tracks as Workflows at `.windsurf/workflows/<track>.md`, invoked via `/<track>`. A Workflow is a linear script the agent follows step by step in the *same* context — it is a routing and procedure aid, not an isolation boundary. State this distinction in `HARNESS_RATIONALE.md` so a future auditor doesn't mistake a workflow for a subagent.

### C. Specialized Roles
- **Devin Local, Subagents toggle on**: `agents/<role>.md` or `agents/<role>/AGENT.md`, following the same frontmatter conventions (name, description, tool scope) as Claude Code/Cursor subagent files, adapted to Devin Local's declared schema. Verify the exact frontmatter schema against current docs at build time rather than assuming exact field names — this feature is explicitly labeled Preview and has changed shape recently.
- **Cascade, or Devin Local without the toggle on**: no dedicated role file — the role's responsibilities and scope live inside the workflow file itself (§3.B) and in the orchestrator rule's best-effort Section 0. Do not fabricate a role-isolation mechanism that doesn't exist.

### D. Lifecycle Hooks (`.windsurf/hooks.json`)
Both agents read the same hook configuration format — this is genuine mechanical enforcement, available regardless of which local agent is active:
```json
{
  "hooks": {
    "pre_write_code": [
      {
        "command": ".windsurf/hooks/verify_gate.sh"
      }
    ],
    "pre_run_command": [
      {
        "command": ".windsurf/hooks/block_destructive.sh"
      }
    ]
  }
}
```
- Pre-hooks (`pre_user_prompt`, `pre_read_code`, `pre_write_code`, `pre_run_command`, `pre_mcp_tool_use`) block by **exit code 2 only** — there is no structured `permission`/JSON response contract like Cursor's; the script's exit code is the entire signal. Post-hooks cannot block, since the action has already occurred by the time they fire. Design gate scripts accordingly (a script that wants to explain *why* it blocked should print to stderr, which the host surfaces when hook output is enabled, but the block itself is purely the exit code).
- **Cannot rewrite commands** — a `pre_run_command` hook can only allow (exit 0) or block (exit 2) the command as submitted; it cannot modify it in place. Design gates around this: block-and-reject, not block-and-fix.
- Hook levels: system (org-managed, out of scope), user (`~/.codeium/windsurf/hooks.json`), workspace (`.windsurf/hooks.json`, this builder's target — version-controlled, team-shared). Hooks neither load nor run when the workspace is opened in Restricted Mode — flag this at Step 5 if the project uses that mode, since it silently disables every hook-backed enforcement artifact for the session.
- **Use this for**: enforcing the path-scoped part of Section 0 (`pre_write_code` denying edits to application source when no work order is open), gating destructive shell commands (`pre_run_command` denying `rm -rf`, force-pushes, unreviewed migration commands), and pre-commit verification (`pre_run_command` matching `git commit`, running the track's verification command, exiting 2 on failure).
- **Write real scripts, not stubs**: a hook entry whose script always exits 0 is decoration, not enforcement — this is the concrete artifact required by the Mechanical Enforcement Protocol (`decision_procedure.md`) for every Hard Invariant/dual-gated track. When subagent isolation isn't available (Cascade, or Devin Local with the toggle off), this hook layer carries even more of the harness's actual enforcement weight than it does on other hosts — treat it as load-bearing, not optional. Step 6's Mechanical Enforcement Execution Test will invoke it against synthetic pass/fail cases.

---

## 4. Standard Generated Workspace Layout

```text
<workspace_root>/
├── AGENT.md (or AGENTS.md, or .windsurf/rules/000-orchestrator.md)   # Always-on orchestrator; Section 0 content depends on detected state
├── PROJECT_SPEC.md
├── HARNESS_RATIONALE.md              # Must state which agent + Subagents toggle state was detected and why Section 0 takes the form it does
├── ONBOARDING.md
├── .devin/                           # Devin Local only, if configured for this project
│   └── config.json                   # MCP servers, permission rules
└── .windsurf/
    ├── rules/
    │   └── 000-orchestrator.md       # (if not using root AGENT.md/AGENTS.md)
    ├── workflows/                    # Cascade tracks (if Cascade detected)
    │   ├── <track-1>.md
    │   └── <track-2>.md
    ├── hooks.json                    # Deterministic gating hooks — real scripts, not stubs
    ├── hooks/
    │   ├── verify_gate.sh
    │   └── block_destructive.sh
    ├── checkpoint.json
    └── harness_log.json

agents/                               # Devin Local with Subagents toggle on, only — project root, not under .windsurf/
├── <role-1>.md
└── <role-2>.md
```

---

## 5. Migration Awareness

Cascade remains present and is still the automatic fallback agent when Devin Local isn't available to a given user — this is not a deprecated-and-removed feature at the time of writing, despite the product having rebranded from Windsurf to Devin Desktop. If the user is on Cascade and hasn't tried Devin Local, note at Step 5 that Cognition intends Devin Local to eventually replace Cascade, and that a **Devin: Open Cascade Migration Wizard** command exists in the product to bring workflows and memories over. This builder does not run that migration itself — it is a product feature, not part of harness derivation — but flagging it lets the human decide whether to migrate before or after adopting this harness, since the harness's Section 0 strength changes materially depending on which agent (and, for Devin Local, which toggle state) it targets. Do not present this migration as urgent or time-boxed unless the user's own docs/changelog at build time say otherwise — treat any specific deprecation date found in outside sources as unverified until confirmed against `docs.devin.ai` directly, since this area of the product has moved faster than most.

---

## 6. Interactive Questioning Fallback

Neither agent has a native `ask_question`-equivalent modal. Resolution order:
1. Check the available tool list at Step 3.6 time for any interactive elicitation tool; use it if present.
2. Otherwise, present the question as clearly formatted Markdown with a stated recommended option and explicit options list, then **wait for the user's literal reply** before proceeding.
3. Do not simulate interactive UI affordances that don't actually exist in this host.

---

## 7. Known Gaps vs. Antigravity (Disclose at Step 5)

- No first-class `ask_question` modal — degraded to the fallback in §6.
- **If Cascade, or Devin Local without the Subagents toggle on**: no subagent isolation at all — Section 0 is convention-plus-path-hooks only; this is the weakest delegation guarantee of any host this builder supports, and must be disclosed as such, not smoothed over.
- **If Devin Local with the Subagents toggle on**: subagent support is still labeled "Preview" in current documentation at time of writing — confirm the toggle is actually enabled (don't infer it from Devin Local being the active agent) before designing a harness that assumes subagents are available, and disclose the Preview label itself as a stability caveat distinct from the enforcement-strength one. If the toggle is off, or the user is unsure, treat the project as Cascade for Section 0 purposes until confirmed otherwise.
- `pre_run_command`/`pre_write_code` hooks cannot rewrite or annotate structured reasons the way Cursor's hook contract can — gate scripts here are strictly allow/deny.
- Several Devin Local capabilities that exist in Cascade are not yet available (Fast Context, App Deploys, browser previews with DOM element picking, Conversation Sharing) — none of these directly affect harness enforcement, but mention them if the user is deciding whether to switch agents for reasons beyond this harness.
- Hooks neither load nor run in a workspace opened in Restricted Mode — disclose this explicitly if it applies, since it silently defeats every hook-backed enforcement artifact without any error being raised.

