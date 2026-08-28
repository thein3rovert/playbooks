---
id: PLB-001
title: Harden Ansible credential and SSH security
status: In Progress
assignee:
  - AI
created_date: '2026-08-28 21:38'
updated_date: '2026-08-28 21:59'
labels:
  - ansible
  - security
  - secrets
dependencies: []
documentation:
  - >-
    backlog/docs/reviews/ansible-standards-review/doc-001 -
    Ansible-Standards-Review-and-Improvement-Plan.md
modified_files:
  - ansible.cfg
  - justfile
  - README.md
  - VAULT-RECOVERY.md
  - roles/tailscale/defaults/main.yml
  - roles/tailscale/tasks/main.yml
  - roles/github-runner/tasks/main.yml
  - roles/github-runner/github-runner.yml
  - roles/argocd/tasks/main.yml
  - roles/linkding/defaults/main.yml
  - roles/linkding/tasks/main.yml
priority: high
type: chore
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Remove the immediate credential-exposure and insecure-access risks identified in the Ansible standards review. The project must protect Vault, Tailscale, GitHub Runner, Argo CD, and Linkding credentials while restoring trustworthy SSH host verification.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Ansible runs do not print or otherwise expose Tailscale, GitHub Runner, Argo CD, Linkding, or Vault credentials in normal output
- [ ] #2 Linkding deployment fails safely when a valid non-placeholder administrator password is not supplied
- [ ] #3 Tailscale authentication credentials are created only when enrollment is required and are not unnecessarily reusable or long-lived
- [ ] #4 Argo CD administrator credentials are not decoded or displayed by the automation
- [ ] #5 SSH host identity is verified rather than globally bypassed
- [ ] #6 The repository does not require a plaintext static Vault password stored in the project working tree
- [ ] #7 Affected playbooks pass syntax validation without revealing secret values
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Establish a safe baseline: inventory every credential path in the affected files and confirm which values are encrypted or externally supplied without reading or recording secret values.
2. Remove secret disclosure from normal Ansible output: protect Tailscale key generation/enrollment and GitHub API/runner configuration with `no_log`, and stop retrieving or printing the Argo CD initial administrator password.
3. Enforce secure Linkding inputs: remove the usable default password and add an early assertion requiring a defined, nonempty, non-placeholder credential before any Kubernetes resource is changed.
4. Correct Tailscale credential lifecycle: check enrollment before requesting an API key, generate a short-lived non-reusable key only for hosts that need enrollment, and keep all key-bearing operations suppressed.
5. Replace project-local static Vault password configuration with a documented external password-client or environment-driven workflow; preserve `.gitignore` protection and avoid handling the actual secret in code or task notes.
6. Re-enable SSH host identity verification in `ansible.cfg` and document the prerequisite for populating trusted host keys so rollout does not unexpectedly lock out automation.
7. Validate safely: run secret-pattern/static checks, inventory parsing, and syntax checks for affected playbooks; review diffs to ensure no credential values or insecure defaults remain.
8. Do not revoke, replace, rekey, or otherwise rotate any live credentials as part of this task. Limit changes to safer code and configuration handling.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Planning research confirmed immediate issues in `ansible.cfg`, Tailscale enrollment, GitHub Runner registration/API verification, Argo CD password display, and Linkding's default password. No secret values were read or copied into the task. Implementation will begin with output suppression and mandatory-secret validation; live credential rotation remains a manual approval checkpoint.

User explicitly decided not to rotate any live credentials at this time. Credential revocation, replacement, and Vault rekeying are excluded from PLB-001; the task will only prevent future disclosure and improve secret handling.

Implemented the first security-hardening pass. Secret-bearing Tailscale and GitHub Runner operations now suppress output; Argo CD no longer reads or displays the initial admin password; Linkding has no usable default password and validates the required secret before cluster changes. Tailscale now creates a non-reusable 10-minute key only after detecting an unauthenticated host. Removed the repository-local Vault password default from `ansible.cfg` and Just recipes, enabled SSH host-key checking, and updated README/Vault recovery guidance for interactive or external password clients.

Validation completed: `git diff --check` passed; production `site.yml` and `vault-manage.yml` syntax checks passed; development `site.yml` syntax check passed with only existing unmatched `k3s_server`/`k3s_nodes` inventory warnings; production and development inventory parsing passed; `just --list` parsed the updated recipes. Validation used the existing ignored local Vault password only as a temporary syntax-check input and did not display or modify it. No live credentials were rotated and no infrastructure-changing playbook was run.

Copied the existing local Vault password, without displaying or changing it, to `~/.config/ansible/vault-password` with mode `0600`. The original ignored `.vault_pass` remains unchanged for now.

Configured `ansible.cfg` to use `~/.config/ansible/vault-password` by default and removed forced interactive prompts from the Vault Just recipes. Confirmed normal syntax checks use the local default and `ANSIBLE_VAULT_PASSWORD_FILE` successfully overrides it for CI.

Final pre-commit verification passed: Ansible resolves the default Vault path to `~/.config/ansible/vault-password`, and an `ANSIBLE_VAULT_PASSWORD_FILE` environment value overrides it as intended. Production/development site syntax checks, Vault management syntax check, Just recipe parsing, and diff validation passed. Development still reports the pre-existing unmatched K3s group warnings. Runtime behavior remains to be verified against a safely selected host before closing the task.
<!-- SECTION:NOTES:END -->
