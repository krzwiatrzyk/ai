---
name: github-actions-workflows
description: Designs secure, minimal GitHub Actions workflows with least-privilege permissions, SHA-pinned third-party actions, and clear run summaries. Use when creating or updating workflow YAML files, CI/CD automation, pull request checks, release pipelines, or when the user mentions GitHub Actions workflows.
---

# GitHub Actions workflows

## Goal

Create GitHub Actions workflows that are secure, simple (KISS), and easy to operate.

## Discovery (required before writing YAML)

Collect these inputs first:

1. Workflow purpose (test, lint, build, release, deploy, scan, etc.)
2. Trigger events (`push`, `pull_request`, `workflow_dispatch`, schedules)
3. Required repository/token permissions
4. Whether deployment needs cloud auth (prefer OIDC)
5. Whether external actions are allowed by team policy

If key information is missing, ask the user before generating the workflow.

## Security baseline (always apply)

1. Set explicit top-level token permissions:
   - Default to read-only where possible.
   - Elevate per job only when required.
2. Never use `permissions: write-all`.
3. Pin every third-party action to a full commit SHA, not a moving tag.
4. Keep secrets out of logs and source; use encrypted secrets or OIDC.
5. Prefer short-lived credentials (OIDC federation) over long-lived cloud keys.
6. Add only the minimum triggers and branch scopes needed.

## KISS workflow rules

1. Prefer one job unless clear separation is needed.
2. Keep steps linear and obvious; avoid clever shell logic.
3. Use direct built-in shell commands when they are short and clear.
4. Introduce reusable workflows/composite actions only when repetition is real.
5. Set `timeout-minutes` for jobs that can hang.

## External action selection protocol (required)

When an external action could be used for a step/job:

1. Present options briefly:
   - **Option A**: built-in shell/native commands
   - **Option B**: one or more external actions (with rationale)
2. Ask the user to confirm whether to use an external action.
3. If yes, ask the user to choose which action.
4. After choice, pin selected action to a full commit SHA in the final YAML.

Do not silently pick unconfirmed third-party actions when alternatives exist.

## Permissions setup process

Use this order:

1. Start with restrictive top-level permissions (for example, `contents: read`).
2. For each job, add only required scopes (`pull-requests: write`, `id-token: write`, etc.).
3. Explain why each write permission is needed.
4. Remove unused permissions before finalizing.

## Summaries and user-facing output

Always provide concise run output with `GITHUB_STEP_SUMMARY`:

1. Add a final `if: always()` summary step for each job.
2. Include:
   - workflow/job result
   - key metrics (tests passed, artifact names, image/tag, deploy target)
   - links or identifiers the user needs next
3. Use markdown headings and short bullet lists.
4. Prefer append (`>>`) style writes so each step can contribute.

## Recommended defaults

- Use `concurrency` for non-parallel-safe workflows (e.g., deploys).
- Use `actions/checkout` with minimal history (`fetch-depth: 1`) unless full history is required.
- Use dependency or build caches only where they reduce runtime meaningfully.
- For Docker/container references, prefer immutable digests when feasible.
- Add path filters to avoid unnecessary runs in monorepos.

## Validation checklist

Before presenting a workflow, verify:

- [ ] All third-party `uses:` entries are pinned to commit SHAs
- [ ] Permissions are explicit and least-privilege
- [ ] No plain-text secrets or insecure credential handling
- [ ] Workflow complexity is minimal for its purpose
- [ ] `GITHUB_STEP_SUMMARY` gives actionable run output
- [ ] Triggers, branches, and paths match user intent

## Output format when delivering a workflow

When returning a generated workflow, include:

1. Short rationale (security + simplicity decisions)
2. Final YAML
3. Permission justification by scope
4. Any external action choices that required/received user confirmation

## Example summary step

```yaml
- name: Write job summary
  if: always()
  run: |
    echo "## CI Result" >> "$GITHUB_STEP_SUMMARY"
    echo "- Status: ${{ job.status }}" >> "$GITHUB_STEP_SUMMARY"
    echo "- Ref: ${{ github.ref_name }}" >> "$GITHUB_STEP_SUMMARY"
    echo "- SHA: ${{ github.sha }}" >> "$GITHUB_STEP_SUMMARY"
```
