#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SKILLS_DIR="${HOME}/.gemini/config/skills"

echo "Installing Antigravity Harness Builder / Auditor skills into: ${TARGET_SKILLS_DIR}"
mkdir -p "${TARGET_SKILLS_DIR}"

# 1. Clean up legacy directory symlinks that Antigravity ignores
for legacy in harness harness-builder harness-auditor; do
  if [ -L "${TARGET_SKILLS_DIR}/${legacy}" ]; then
    rm -f "${TARGET_SKILLS_DIR}/${legacy}"
  fi
done

# 2. Setup root orchestrator: 'harness' (Command: /harness)
mkdir -p "${TARGET_SKILLS_DIR}/harness"
sed 's/^name: harness-builder/name: harness/' "${REPO_DIR}/SKILL.md" > "${TARGET_SKILLS_DIR}/harness/SKILL.md"
ln -sfn "${REPO_DIR}/references" "${TARGET_SKILLS_DIR}/harness/references"

# 3. Setup root orchestrator alias: 'harness-builder' (Command: /harness-builder)
mkdir -p "${TARGET_SKILLS_DIR}/harness-builder"
cp "${REPO_DIR}/SKILL.md" "${TARGET_SKILLS_DIR}/harness-builder/SKILL.md"
ln -sfn "${REPO_DIR}/references" "${TARGET_SKILLS_DIR}/harness-builder/references"

# 4. Setup Mode 1 shortcut: 'harness-genesis' (Command: /harness-genesis)
mkdir -p "${TARGET_SKILLS_DIR}/harness-genesis"
cat << 'GENESIS_EOF' > "${TARGET_SKILLS_DIR}/harness-genesis/SKILL.md"
---
name: harness-genesis
description: Directly launch Mode 1 (Genesis) of the Harness Builder to design a greenfield project spec, tracks, roles, invariants, and gates from scratch.
---

# Harness Builder: Mode 1 (Genesis)

You are the **Harness Builder** operating directly in **Mode 1 (Genesis)** for a new project.

## Instructions
1. Follow the Genesis workflow in:
   [references/mode1_genesis.md](references/mode1_genesis.md)
2. Derive the harness using:
   [references/decision_procedure.md](references/decision_procedure.md)
3. Check host environment using:
   [references/antigravity_primitives.md](references/antigravity_primitives.md)
4. Execute Step 5 transparency checkpoint and Step 6 dry-run before completion:
   [references/dry_run_verification.md](references/dry_run_verification.md)
GENESIS_EOF
ln -sfn "${REPO_DIR}/references" "${TARGET_SKILLS_DIR}/harness-genesis/references"

# 5. Setup Mode 2 shortcut: 'harness-adopt' (Command: /harness-adopt)
mkdir -p "${TARGET_SKILLS_DIR}/harness-adopt"
cat << 'ADOPT_EOF' > "${TARGET_SKILLS_DIR}/harness-adopt/SKILL.md"
---
name: harness-adopt
description: Directly launch Mode 2 (Adoption) of the Harness Builder to investigate an existing codebase and establish tracks, roles, invariants, and gates.
---

# Harness Builder: Mode 2 (Adoption)

You are the **Harness Builder** operating directly in **Mode 2 (Adoption)** for an existing unharnessed codebase.

## Instructions
1. Follow the read-only Adoption investigation in:
   [references/mode2_adoption.md](references/mode2_adoption.md)
2. Derive the harness using:
   [references/decision_procedure.md](references/decision_procedure.md)
3. Check host environment using:
   [references/antigravity_primitives.md](references/antigravity_primitives.md)
4. Execute Step 5 transparency checkpoint and Step 6 dry-run before completion:
   [references/dry_run_verification.md](references/dry_run_verification.md)
ADOPT_EOF
ln -sfn "${REPO_DIR}/references" "${TARGET_SKILLS_DIR}/harness-adopt/references"

# 6. Setup Mode 3 shortcut: 'harness-audit' (Command: /harness-audit)
mkdir -p "${TARGET_SKILLS_DIR}/harness-audit"
cat << 'AUDIT_EOF' > "${TARGET_SKILLS_DIR}/harness-audit/SKILL.md"
---
name: harness-audit
description: Directly launch Mode 3 (Audit) of the Harness Builder to audit drift, apply quick fixes, or evolve an existing project harness.
---

# Harness Builder: Mode 3 (Audit)

You are the **Harness Builder** operating directly in **Mode 3 (Audit)**.

## Instructions
1. Follow the Audit procedures (Sub-modes 3a, 3b, 3c) in:
   [references/mode3_audit.md](references/mode3_audit.md)
2. Run self-consistency checks using:
   [references/decision_procedure.md](references/decision_procedure.md)
3. Execute Step 5 transparency checkpoint and Step 6 dry-run before completion:
   [references/dry_run_verification.md](references/dry_run_verification.md)
AUDIT_EOF
ln -sfn "${REPO_DIR}/references" "${TARGET_SKILLS_DIR}/harness-audit/references"

chmod +x "${REPO_DIR}/install.sh"
echo "All Harness Builder / Auditor skills installed successfully into ${TARGET_SKILLS_DIR}!"
