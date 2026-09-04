---
id: PLB-004
title: Split site playbook by platform and host function
status: In Progress
assignee:
  - AI
created_date: '2026-08-28 22:11'
updated_date: '2026-08-28 22:20'
labels:
  - ansible
  - playbooks
  - inventory
  - architecture
dependencies: []
documentation:
  - >-
    backlog/docs/reviews/ansible-standards-review/doc-001 -
    Ansible-Standards-Review-and-Improvement-Plan.md
modified_files:
  - site.yml
  - inventory/production.yml
  - inventory/dev.yml
  - inventory/README.md
  - README.md
priority: high
type: enhancement
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The main site playbook currently applies many unrelated roles to every host, even when systems have different operating systems and purposes. This risks running Debian package tasks on NixOS or deploying backup, monitoring, and runner configuration to hosts that do not need them. Reorganize orchestration so each host receives only the roles intended for its platform and function while keeping role tags and common commands usable.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Debian-specific roles do not run on NixOS hosts
- [ ] #2 NixOS-specific roles do not run on Debian or other unsupported hosts
- [ ] #3 Backup, monitoring, Kubernetes, GitHub Runner, and other functional roles target only explicitly assigned hosts
- [ ] #4 A full site run preserves the intended configuration coverage for existing production and development hosts
- [ ] #5 Existing role tags and Just commands continue to target the correct plays and hosts
- [ ] #6 Inventory and playbook documentation clearly explains platform and functional groups
- [ ] #7 Production and development inventories parse successfully and all affected playbooks pass syntax validation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Keep production and development separated through their existing inventory files (`inventory/production.yml` and `inventory/dev.yml`); do not merge environments.
2. Keep each host defined once with its connection details and add an `enabled_roles` list to that host (or host_vars when already present) to declare only the roles it should receive.
3. Keep all role implementations in the central `roles/` directory; no role files move in this task.
4. Refactor `site.yml` so common orchestration checks each host's `enabled_roles` list before importing a role, preserving existing tags and host limits.
5. Retain the existing Kubernetes cluster groups for multi-host cluster topology, because server/node relationships are meaningful and not merely role assignment.
6. Update Just commands and documentation to explain environment selection and per-host role assignment.
7. Compare current and proposed host-to-role coverage before changing inventory, then validate inventory parsing, syntax, tags, host limits, and listed tasks without applying infrastructure changes.

User instructed that every current general-system role should initially be present in each host's `enabled_roles` list and will remove unwanted assignments manually. This preserves current coverage while introducing the safer assignment mechanism; platform/function isolation will only become effective as those lists are trimmed. Kubernetes application and K3s inventory roles remain controlled by their topology groups.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Planning started. Proposed scope changes orchestration and inventory grouping only; roles remain under the central `roles/` directory and no role implementation is moved. Implementation is paused for user review of host-to-role assignments.

User approved a revised inventory model: preserve separate production/dev inventory files and use one `enabled_roles` list per host instead of creating many overlapping functional groups. Existing K3s topology groups remain where group membership carries cluster meaning. No host-to-role assignments will be guessed or changed until confirmed.

Implemented per-host role selection. Every general role import in `site.yml` now checks the host's `enabled_roles` list. Production and development remain separate inventory files, all current hosts initially receive the full general-role list as requested, and K3s topology groups remain unchanged. Added documentation showing how to remove unwanted roles per host.

Validation passed: production and development inventories parse; both site syntax checks pass; `git diff --check` passes; list-host/list-task checks confirm tags still select Tailscale on Bellamy and Prometheus on ubuntu-srv-01. Development continues to show the pre-existing warning because it has no K3s topology groups. Platform/function isolation acceptance criteria remain pending until the user trims each host's intentionally broad initial `enabled_roles` list.
<!-- SECTION:NOTES:END -->
