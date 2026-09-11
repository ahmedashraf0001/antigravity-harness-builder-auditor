# Generic Primitives & File Layout Mapping (Unlisted / Unknown Host Tools)

Use this file when Step 3.6 detects a host that is **not** Antigravity, Claude Code, Cursor, or Windsurf/Devin Desktop — e.g. a bare VS Code + Copilot setup, Zed, Aider, JetBrains AI Assistant, a custom in-house agent harness, or any tool without a dedicated reference file in this skill. This file exists so Step 3.6 never has zero structural guidance to fall back on — the goal is to derive the closest honest analog to each harness primitive from what the host actually documents, not to invent capabilities it doesn't have.

**This file is a procedure for investigating an unknown host, not a fixed mapping table** — unlike the tool-specific files, the primitives here are genuinely unknown until Step 3.6 investigates. Do not skip the investigation and default straight to prose-only rules; a surprising number of hosts have *some* structural primitive (a `settings.json` hook, a project-root instruction file, a plugin/extension mechanism) that this procedure will surface if actually checked.

---

## 1. Investigation Procedure (Required Before Deriving Anything)

1. **Identify the tool concretely.** Ask the user directly if it isn't obvious from workspace dotfiles: *"What tool are you using to run this harness — is there an official name and version I should look up?"* Do not proceed on a guess.
2. **Search official documentation** for each of the following capabilities, in this order, and record what you find (present/absent/uncertain) for each:
   - a. **Always-on project instruction file** (a `CLAUDE.md`/`AGENTS.md`-style file the tool reads automatically every session).
   - b. **Subagent / sub-session primitive** with its own context and independently scoped tools (vs. a single shared context for the whole session).
   - c. **Lifecycle hooks or an extension/plugin API** that can intercept a tool call *before* it executes and block it (not just log it).
   - d. **Model-invoked skill/workflow files** that are indexed by description and loaded on demand (progressive disclosure) vs. everything living in one flat instruction file.
   - e. **Native interactive elicitation UI** (selectable options, checkboxes) vs. plain chat text.
   - f. **Persistent state the tool itself manages** (a session/checkpoint file, task history) vs. nothing surviving between turns except conversation history.
3. **Never guess a primitive's existence from the tool's category.** "It's an IDE agent, so it probably has hooks like the others" is exactly the kind of unverified assumption this procedure exists to prevent — some tools genuinely have none of (b) through (f).
4. **State findings plainly to the user before deriving the harness**, e.g.: *"I checked [Tool]'s docs. It has an always-on instruction file and skill-style workflow files, but no subagent primitive and no blocking hooks — only an audit log. That changes what Section 0 and the circuit breaker can mechanically guarantee here; here's what I'd propose instead: [...]"*

---

## 2. Mapping Table (Fill In Per-Host, Do Not Assume Blank = Absent)

| Harness Concept | Question to Answer From Docs | If Present | If Absent |
| :--- | :--- | :--- | :--- |
| **Orchestrator & Routing** | Does the tool read a project-root file automatically every session? | Use it for the triage matrix, Section 0, Resume Protocol, Circuit Breaker logic. | Fall back to the most-persistent context the tool does offer (e.g. a pinned system prompt, a `.rules` file manually attached each session) and disclose that "always-on" is not actually guaranteed here — the human may need to manually attach it each session. |
| **Work-Routing Tracks** | Are there model-invoked, on-demand instruction files (skills/workflows)? | Mirror the `SKILL.md` frontmatter/description pattern used by the other hosts. | Fold track definitions directly into the single orchestrator file as clearly delimited sections; flag that this loses progressive disclosure and may bloat context on every turn. |
| **Specialized Roles** | Is there a subagent/sub-session primitive with independent context and tool scope? | Map roles onto it directly, following the Claude Code/Cursor pattern as the closest precedent. | **Do not claim delegation exists.** Collapse roles into documented conventions within the single shared context (state the current role explicitly before each task, stay within its declared scope) and mark this "advisory only" in `HARNESS_RATIONALE.md`, per the Non-Negotiables — this is the same honest degradation as Cascade in `windsurf_primitives.md` §3.A. |
| **Gating** | Is there a hook/extension API that can block a tool call before execution? | Use it for Section 0 enforcement and destructive-command gating — this is the host's real teeth. | No mechanical backstop exists at the AI-tool layer. Section 0 and all gates are prose-only *at that layer* — but the Mechanical Enforcement Protocol (`decision_procedure.md`) still requires a real artifact for every Hard Invariant/dual-gated track, so fall back to **(b) a git pre-commit hook** (near-universal, see §3 below) and/or **(c) a CI check**, since these don't depend on the AI tool's own primitives at all. State plainly at Step 5 that enforcement lives at the repo/CI layer rather than the AI-tool layer for this host. |
| **Circuit Breakers** | Is there any persistent state file, or does everything reset each session? | Wire the counter into that state. | If the tool has no persistent state of its own, use a plain project file (e.g. `.agents/checkpoint.json`, tool-agnostic) that the orchestrator instruction file is told to read/write directly via whatever file tools the host does expose — most hosts can at least read and write a file even without dedicated "state" primitives. |
| **Tool Provisioning** | Does the tool support MCP or an equivalent external-tool connection standard? | Use it. | Note the tool must be invoked via whatever generic shell/file access the host provides, without fine-grained per-role scoping — flag this as a 4e (Minimal Tool Scoping) limitation. |
| **State & Checkpoints** | See Circuit Breakers row — same file, same reasoning. | | |
| **Interactive Questioning** | Native selectable-option UI? | Use it. | Plain Markdown question, explicit recommended option, wait for literal reply — never treat silence as an answer. |

---

## 3. Universal Fallback: Git-Native Enforcement

Regardless of what the AI tool itself supports, a **pre-commit git hook** is a property of the repository, not of the AI tool, and works with any host that eventually runs `git commit` on the human's or agent's behalf. This is enforcement artifact type (b) in the Mechanical Enforcement Protocol (`decision_procedure.md`), and for a host with no blocking-hook primitive of its own, it is the primary mechanism satisfying that protocol's mandatory requirement for every Hard Invariant and dual-gated track — not an optional nicety:
```bash
#!/bin/sh
# .git/hooks/pre-commit (or managed via a tool like husky/pre-commit framework)
# Runs the harness's dual-gate verification command(s) before allowing a commit to complete.
<verification command for the affected track(s)>
if [ $? -ne 0 ]; then
  echo "Harness gate failed: <track> verification did not pass. Commit blocked."
  exit 2
fi
```
- **Exit Code Convention**: Use exit code `2` for the blocking case, not a bare `exit 1`. Git itself only distinguishes zero from non-zero, so `1` would work for git alone — but this builder standardizes every generated enforcement script (host-native hooks, git hooks, CI checks) on exit code `2` for "blocked" so a script can be reused verbatim across layers (e.g. the same verification logic backing both a git pre-commit hook and, per `claude_code_primitives.md` §3.D, a `PreToolUse` hook that specifically requires exit code `2` to deny). A pre-commit script generated with `exit 1` will still block the commit correctly, but will silently fail to block if the same file is later wired in as a host-native hook expecting `2` — treat this as a portability bug, not a stylistic choice, and correct it if found during Step 4.1 item 10 or the Step 6 execution test.
- Reserve exit code `1` (or any other non-zero, non-`2` code) for genuine script errors unrelated to the gate decision itself (e.g. the verification command's binary is missing) — see the Step 6 degraded-verification handling below for how to distinguish "the artifact correctly blocked" from "the artifact itself is broken."

This does not require the AI tool to have any hook/enforcement primitive at all — it works purely at the Git layer, and is available as a fallback enforcement mechanism on **any** host, including ones covered by this file. Prefer this over pure prose whenever the harness has a Hard Invariant and the host has no native blocking hook — a Hard Invariant enforced by prose alone, with neither this git hook nor a CI check (type (c)) generated, has not passed the Mechanical Enforcement Protocol and must not ship as complete.


---

## 4. Disclosure Requirement

Because this file describes an investigation procedure rather than a fixed mapping, **Step 5's transparency checkpoint must include a short "Host Capability Summary"** for any project routed through this file:
> *"This harness targets [Tool], which I could not find a dedicated reference for. Based on its documentation: [primitive] is supported ([how it's used]); [primitive] is not, so [what was substituted, and how much weaker the guarantee is]."*

A harness built through this file that does not include this summary has not passed Step 4.1 item 9 (Orchestrator Delegation Wiring) or item 10 (Mechanical Enforcement Coverage) — silently presenting a fully-prose harness as if it had the same guarantees as an Antigravity/Claude Code/Cursor harness is a misrepresentation of what was actually built.
