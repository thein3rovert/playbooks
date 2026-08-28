---
id: PLB-003
title: Make SSH hardening safe and reliable
status: In Progress
assignee:
  - AI
created_date: '2026-08-28 22:04'
updated_date: '2026-08-28 22:07'
labels:
  - ansible
  - ssh
  - security
  - reliability
dependencies: []
documentation:
  - >-
    backlog/docs/reviews/ansible-standards-review/doc-001 -
    Ansible-Standards-Review-and-Improvement-Plan.md
modified_files:
  - roles/user/tasks/main.yml
  - roles/user/handlers/main.yml
  - roles/user/defaults/main.yml
  - roles/user/README.md
priority: high
type: bug
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The user role changes SSH login settings but calls a restart action that does not exist and does not verify the new configuration first. This could make a playbook fail or lock administrators out of a server. For example, if password and root login are disabled while the authorized key or SSH configuration is invalid, the current session may end and the next login may be rejected. The role should apply SSH hardening only when a working key-based login is available, reject invalid configuration before reload, and keep the service available.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The user role completes successfully when SSH settings change and does not reference a missing handler
- [ ] #2 Invalid SSH configuration is rejected before the running SSH service is reloaded or restarted
- [ ] #3 SSH hardening is not applied unless a usable non-root key-based login is configured
- [ ] #4 The correct SSH service is reloaded safely on each supported operating system
- [ ] #5 An existing control connection remains usable and a new SSH connection succeeds after hardening
- [ ] #6 A repeated role run makes no unnecessary SSH configuration or service changes
- [ ] #7 The affected playbook passes syntax validation and the safe failure behavior is documented
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Validate required user, group, public-key, and SSH configuration inputs before changing accounts or SSH settings.
2. Make user and authorized-key setup consistent and ensure the target non-root account has a usable key before hardening begins.
3. Detect the platform SSH service name and add the missing handler using a safe reload rather than an unconditional restart.
4. Validate the complete SSH daemon configuration before accepting changes so malformed settings cannot replace a working configuration.
5. Flush the handler while the existing Ansible control connection is still available, reset the connection, and verify a fresh SSH connection as the hardened non-root user.
6. Run syntax/check-mode validation, then perform a controlled first and repeat run on an approved host to prove connectivity and idempotence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
User requested keeping all Ansible standards fixes in one branch. Renamed the current branch from `plb-001-harden-ansible-security` to `ansible-standards-hardening`; no new branch was created. Research found the user role hard-codes the `users` supplementary group, lacks `become` on several account files, uses an unqualified authorized-key module, has no handler, and modifies `sshd_config` without validation.

Implemented safe SSH hardening for supported imperative Linux platforms. The role validates required non-root user/key inputs, checks the SSH validator, creates the configured account and key with privilege escalation, verifies `authorized_keys` is populated, validates candidate SSH configuration with `sshd -t`, reloads through a platform-aware handler, resets the control connection, and verifies a fresh non-root connection. Added role safety documentation.

Runtime research showed Bellamy is NixOS. Because imperative user and `/etc/ssh/sshd_config` edits conflict with NixOS declarative configuration, the role now explicitly skips unsupported platforms including NixOS. Bellamy check-mode verification passed with zero changes and reported the skip. Production/development syntax checks and `git diff --check` passed; development retains the existing unmatched K3s group warnings. A first/repeat runtime test of the hardening path still requires an approved supported Debian, Red Hat, or SUSE host with `ssh_pub_key` configured.
<!-- SECTION:NOTES:END -->
